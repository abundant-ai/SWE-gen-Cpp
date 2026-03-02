Projects that integrate with fmt’s color API no longer compile with fmt 11.2+ because `fmt::detail::color_type::is_rgb()` was removed as part of an internal representation change to `fmt::text_style`/color handling.

A common downstream usage pattern was to branch on whether a color value is an RGB color vs a terminal/palette color by calling `is_rgb()`. With fmt 11.2, attempting to compile such code fails with an error indicating that `color_type` has no member named `is_rgb`.

Update the color API so there is a supported way to distinguish terminal colors from non-terminal (RGB) colors when working with `fmt::text_style` and the color types used by `fg(...)`/`bg(...)`. Downstream code should be able to replace `is_rgb()` with an equivalent check (for example, a predicate like `is_terminal_color()` that returns true for terminal colors and false for RGB colors, so `!is_terminal_color()` can be used where `is_rgb()` previously was).

The fix must preserve existing `text_style` semantics:

- `fmt::text_style{}` reports no foreground/background/emphasis.
- `fg(fmt::rgb(...))` sets only the foreground; `bg(fmt::rgb(...))` sets only the background.
- Combining styles with `operator|` should merge RGB foreground colors by bitwise-OR’ing their packed RGB values (e.g., OR’ing `0xC0F000` and `0x000FEE` results in `0xC0FFEE`), and similarly for background.
- Combining two terminal foreground colors with `operator|` must throw `fmt::format_error` with the message: `"can't OR a terminal color"` (same for background terminal colors, and terminal color combined with a non-terminal color in the same channel).
- Combining a terminal foreground with a terminal background (different channels) is allowed and must not throw.
- Formatting a string with `fmt::format(style, ...)` must still emit correct ANSI escape sequences for RGB colors (e.g., `"\x1b[38;2;255;020;030m...\x1b[0m"` for an RGB foreground), and the formatting results must remain unchanged versus previous behavior.

In short: restore a stable, public way to query whether a stored color is terminal vs RGB (replacing the removed `is_rgb()` capability) while keeping all `text_style` combination and formatting behaviors identical to the pre-change semantics.