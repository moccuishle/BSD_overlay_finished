import io, re

p = r"C:\Users\Administrator\Desktop\work\.gitignore"
t = io.open(p, encoding="utf-8", newline="").read().replace("\r\n", "\n")

HEAD = """# 4.4BSD-Lite2 tree, merged into kernel/ but not tracked (regenerated from
# the tarball by tools/ensure-src.ps1 + tools/reorganize.ps1).
# The directory itself is not excluded; only its files are, so the
# per-directory config.mk files can stay in git.
"""

dirs = [
    "bsd45/kernel/include/sys",
    "bsd45/kernel/include/machine",
    "bsd45/kernel/include/libkern",
    "bsd45/kernel/arch",
    "bsd45/kernel/vm",
    "bsd45/kernel/net",
    "bsd45/kernel/fs/ufs",
    "bsd45/kernel/fs/miscfs",
    "bsd45/kernel/fs/isofs",
    "bsd45/kernel/fs/nfs",
    "bsd45/kernel/driver/dev",
    "bsd45/kernel/driver/isa",
    "bsd45/kernel/driver/pci_i386",
    "bsd45/kernel/other/kern",
    "bsd45/kernel/other/conf",
    "bsd45/kernel/other/compile",
    "bsd45/kernel/other/scripts",
    "bsd45/kernel/other/stand",
    "bsd45/kernel/other/stand.att",
    "bsd45/kernel/other/tests",
]
files = ["bsd45/kernel/other/mips"]

rules = [HEAD]
for d in dirs:
    rules.append(f"{d}/**")
    rules.append(f"!{d}/**/")
    rules.append(f"!{d}/**/config.mk")
for f in files:
    rules.append(f)
# the three patched files stay tracked inside arch/
rules += [
    "!bsd45/kernel/arch/i386/isa/locore.s",
    "!bsd45/kernel/arch/i386/isa/machdep.c",
    "!bsd45/kernel/arch/i386/isa/pmap.c",
]
rules.append("")

start = t.find("# 4.4BSD-Lite2 tree")
end = t.find("\n# local reference trees")
if end < 0:
    end = len(t)
t = t[:start] + "\n".join(rules) + t[end:]
io.open(p, "w", encoding="utf-8", newline="\n").write(t)
print("gitignore rewritten")
