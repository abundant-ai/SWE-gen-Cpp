There is an inconsistency/bug in how pugixml handles “empty” text/attribute wrappers (default-constructed objects or wrappers obtained from nodes that don’t have text) across the xml_text and xml_attribute APIs.

When working with node text via xml_node::text(), the returned xml_text object should behave like an empty/false value when there is no applicable text content. In particular:

- For elements that contain actual character data (PCDATA) or CDATA as their text, xml_node::text() should be truthy and should provide that content via xml_text::get() and xml_text::as_string(). Examples:
  - For <a>foo</a>, both node.child("a").text().get() and node.child("a").text().as_string() should return "foo".
  - For <b><![CDATA[bar]]></b> (even when mixed with child elements before/after), node.child("b").text().get() and .as_string() should return "bar".

- For nodes that do not have usable text content (e.g., nodes whose only child is a processing instruction, or empty elements), xml_node::text() should be falsy; however, calls to xml_text::get() / xml_text::as_string() must still be safe and return the empty string ("") rather than crashing or returning garbage.
  - For <c><?pi value?></c> with parsing that preserves processing instructions, node.child("c").text() should be false, and node.child("c").text().get() and .as_string() should return "".
  - For <d/>, node.child("d").text() should be false, and .get()/.as_string() should return "".

- A default-constructed xml_node (xml_node()) should produce an empty xml_text via xml_node().text(); xml_node().text() should be falsy and xml_node().text().get() / .as_string() should return "".

Additionally, default-constructed wrappers must be safely usable:
- A default-constructed xml_text() should be falsy and xml_text().as_int() should return 0.

Separately, xml_attribute assignment and set_value operations on an empty/default-constructed xml_attribute must be safe and must not succeed:
- Expressions like xml_attribute() = "v1" or xml_attribute() = -2147483648 should be no-ops that do not crash.
- xml_attribute::set_value(...) must return false when called on a default-constructed xml_attribute, across overloads including string, signed/unsigned integers, floating point, and bool.

Fix the implementation so that these empty/null object behaviors are consistent: boolean checks reflect presence of real underlying data, but getters/converters on empty objects are safe and return the documented default values ("" for strings, 0 for integers).