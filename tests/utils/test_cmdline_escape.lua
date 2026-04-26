local asserts = require("tests.asserts")
local ecc = require("ceramicist.utils").escape_control_chars

asserts.eq(ecc("no changes"), "no changes")
asserts.eq(ecc("a\x1b bc def\t"), [[a\e bc def\t]])
asserts.eq(ecc("a\x1b\v\3\t '\n\x11 \nb"), [[a\e\v\x03\t '\n\x11 \nb]])
