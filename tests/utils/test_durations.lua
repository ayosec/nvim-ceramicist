local asserts = require("tests.asserts")
local f = require("ceramicist.utils").format_duration

asserts.eq(f(923), "923 ns")
asserts.eq(f(456294), "456 μs")
asserts.eq(f(573817591), "574 ms")
asserts.eq(f(6084087435), "6 s")
asserts.eq(f(1007016260400), "17 m")
asserts.eq(f(25524835271892), "7 h")
asserts.eq(f(3.241528202e14), "4 d")
