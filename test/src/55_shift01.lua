local x = ...
local a, b, c, d
-- register << immediate (encoded as SHRI with negated immediate + MMBINI TM_SHL)
a = x << 3
-- register >> immediate (SHRI)
b = x >> 3
-- immediate << register (SHLI)
c = 3 << x
-- immediate >> register (no immediate form; constant loaded into a register)
d = 3 >> x
print(a, b, c, d)
-- negative immediates
a = x << -3
b = x >> -3
c = -3 << x
d = -3 >> x
print(a, b, c, d)
-- boundaries of the signed C operand
a = x << 127
b = x >> 127
c = x << 128
d = x >> 128
print(a, b, c, d)
a = x << -127
b = x >> -127
c = x << -128
d = x >> -128
print(a, b, c, d)
a = 127 << x
b = 128 << x
c = -127 << x
d = -128 << x
print(a, b, c, d)
-- large constants (do not fit an immediate)
a = x << 1000
b = x >> 1000
c = 1000 << x
d = 1000 >> x
print(a, b, c, d)
a = x << -1000
b = x >> -1000
c = x << 0x7fffffffffffffff
d = x >> math.mininteger
print(a, b, c, d)
-- constants too large for LOADI (stored in the constant table)
a = x << -1000000
b = x >> 1000000
c = -1000000 << x
d = x >> -0x7fffffffffffffff
print(a, b, c, d)
-- shifts inside larger expressions
print((x << 3) >> 3, 1 << (x >> 2), -(x << 4), x << 3 | x >> 3)
