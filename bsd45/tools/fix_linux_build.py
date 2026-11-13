import io

W = r"C:\Users\Administrator\Desktop\work\bsd45"

# 1. hello.c: with -fleading-underscore the C symbol "start" becomes _start,
#    which is what the kernel jumps to (and mingw also prefixes "_").
p = W + r"\libc\src\hello.c"
t = io.open(p, encoding="utf-8", newline="").read().replace("\r\n", "\n")
t = t.replace("void _start(void){", "void start(void){")
io.open(p, "w", encoding="utf-8", newline="\n").write(t)
print("hello.c entry renamed")

# 2. build_sh.sh: link the 4.4BSD libkern quad routines instead of libgcc's
#    __divdi3 (with -fleading-underscore gcc asks for ___divdi3).
p = W + r"\build_sh.sh"
t = io.open(p, encoding="utf-8", newline="").read().replace("\r\n", "\n")

anchor = 'compile_c "$ws/libc/src/ctype_table.c" "$obj/ctype_table.o"  && add "$obj/ctype_table.o"'
assert anchor in t
quad = anchor + '''

# 64-bit arithmetic helpers: 4.4BSD libkern, so we do not depend on the
# exact symbol names libgcc uses on this platform.
quad_srcs=(divdi3.c moddi3.c udivdi3.c umoddi3.c qdivrem.c
           muldi3.c adddi3.c subdi3.c anddi3.c iordi3.c xordi3.c
           notdi2.c negdi2.c ashldi3.c ashrdi3.c lshldi3.c lshrdi3.c
           cmpdi2.c ucmpdi2.c)
for f in "${quad_srcs[@]}"; do
    compile_c "$ws/kernel/libkern/$f" "$obj/kq_${f%.c}.o" && add "$obj/kq_${f%.c}.o"
done'''
t = t.replace(anchor, quad, 1)
io.open(p, "w", encoding="utf-8", newline="\n").write(t)
print("build_sh.sh quad routines added")
