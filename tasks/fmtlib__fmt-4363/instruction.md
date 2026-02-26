Projects that integrate with fmt 11.2+ fail to compile because `detail::color_type::is_rgb()` (and the associated `is_rgb` member) was removed as part of an optimization that packs `fmt::text_style`/color data into a smaller representation.

A common failure mode is code that previously branched on whether a `detail::color_type` was an RGB color:

```cpp
if (color.is_rgb()) {
  // treat as 24-bit RGB
} else {
  // treat as terminal color
}
```

After upgrading, this produces a compile error like:

```
error: '...::color_type' has no member named 'is_rgb'
```

The library still needs to provide a supported way to distinguish RGB colors from terminal colors when working with `fmt::text_style`/foreground/background colors so that downstream code can make the same decision without relying on removed internals.

Implement a replacement API on the color representation used by `fmt::text_style` (and usable by downstream code) that allows checking whether the stored value is a terminal color vs an RGB color. The replacement should make it possible to update code that used `is_rgb()` to an equivalent check (for example, by introducing/ensuring an `is_terminal_color()` query and defining RGB as the negation where appropriate).

Behavioral requirements for `fmt::text_style` must remain correct:

- `fmt::text_style{}` reports no foreground, no background, and no emphasis.
- `fg(fmt::rgb(...))` sets foreground and does not set background/emphasis; similarly `bg(fmt::rgb(...))` sets background only.
- Combining styles with `operator|` preserves RGB semantics by bitwise-OR’ing RGB channels when both sides provide RGB for the same layer (e.g., OR’ing two foreground RGB values yields a foreground RGB whose packed integer is the bitwise OR of the two inputs).
- `operator|` must reject attempts to OR two foreground terminal colors, two background terminal colors, or a terminal color with a non-terminal color for the same layer, by throwing `fmt::format_error` with the message:

```
can't OR a terminal color
```

- Mixing layers remains allowed (e.g., `fg(terminal_color::white) | bg(terminal_color::white)` must not throw).

After the change, downstream code should be able to replace uses of `is_rgb()` with the new supported query to restore compilation on fmt 11.2+ while keeping the same runtime behavior for formatting ANSI sequences for RGB vs terminal colors.