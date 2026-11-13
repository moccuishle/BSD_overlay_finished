import io, os, re

W = r"C:\Users\Administrator\Desktop\work\bsd45"

# 1. run_qemu_test.sh: unbuffered reader so the last serial line is not lost
p = W + r"\tools\run_qemu_test.sh"
t = io.open(p, encoding="utf-8", newline="").read().replace("\r\n", "\n")
old = '''( cat <&3 >> "$log" ) &
catpid=$!'''
new = '''# stdbuf keeps the reader unbuffered: the final "[user exit N]" line is
# written just before the guest halts and must not sit in cat's buffer
( stdbuf -o0 cat <&3 >> "$log" 2>/dev/null || cat <&3 >> "$log" ) &
catpid=$!'''
assert old in t
t = t.replace(old, new, 1)
io.open(p, "w", encoding="utf-8", newline="\n").write(t)
print("run_qemu_test.sh reader fixed")

# 2. the Linux symbol patch must be present in every C-compiling build .sh
checks = {
    "build_userland.sh": "-fleading-underscore",
    "build_sh.sh": "-fleading-underscore",
    "build_kernel.sh": "-fleading-underscore",
}
for f, needle in checks.items():
    p = os.path.join(W, f)
    t = io.open(p, encoding="utf-8", newline="").read()
    print(f, "patched" if needle in t else "MISSING PATCH")

print("quad routines in build_sh.sh:", "kq_${f%.c}" in io.open(os.path.join(W, "build_sh.sh"), encoding="utf-8").read())
print("hello entry:", "void start(void)" in io.open(os.path.join(W, r"libc\src\hello.c"), encoding="utf-8").read())
