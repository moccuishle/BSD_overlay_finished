import io

W = r"C:\Users\Administrator\Desktop\work\bsd45"

# 1. harness: allow "\|" inside a command (a real shell pipeline)
p = W + r"\tools\run_qemu_test.sh"
t = io.open(p, encoding="utf-8", newline="").read().replace("\r\n", "\n")
old = '''IFS='|' read -r -a cmdlist <<< "$keys"
for k in "${cmdlist[@]}"; do'''
new = '''# "|" separates the commands to type, so a real pipeline must be written
# as "\\|" (the tests use e.g. "echo hi \\| cat")
keys_prot="${keys//\\\\|/$'\\x01'}"
IFS='|' read -r -a cmdlist <<< "$keys_prot"
for i in "${!cmdlist[@]}"; do
    cmdlist[$i]="${cmdlist[$i]//$'\\x01'/|}"
done
for k in "${cmdlist[@]}"; do'''
assert old in t, "anchor not found"
t = t.replace(old, new, 1)
io.open(p, "w", encoding="utf-8", newline="\n").write(t)
print("harness: escaped-pipe separator added")

# 2. s7/s9 use pipelines: switch to "\|"
for f, old_k, new_k in [
    ("test_s7.sh", 'echo hello-pipe | cat', 'echo hello-pipe \\| cat'),
    ("test_s9.sh", 'echo hi-vfs | cat', 'echo hi-vfs \\| cat'),
]:
    p = W + r"\tools" + "\\" + f
    t = io.open(p, encoding="utf-8", newline="").read()
    assert old_k in t, (f, old_k)
    t = t.replace(old_k, new_k, 1)
    io.open(p, "w", encoding="utf-8", newline="\n").write(t)
    print(f, "pipeline escaped")
