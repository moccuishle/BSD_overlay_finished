import io

p = r"C:\Users\Administrator\Desktop\work\bsd45\tools\ensure-src.ps1"
t = io.open(p, encoding="utf-8", newline="").read().replace("\r\n", "\n")
lines = t.split("\n")
out = []
inserted = False
for line in lines:
    out.append(line)
    if "4.5BSD-Lite2.tar.gz\" }" in line and not inserted:
        out.append('if (!(Test-Path $tarball)) { $tarball = Join-Path $ws "..\\4.4BSD-Lite2.tar.gz" }')
        out.append('if (!(Test-Path $tarball)) { $tarball = Join-Path $ws "4.4BSD-Lite2.tar.gz" }')
        inserted = True
t = "\n".join(out)
io.open(p, "w", encoding="utf-8", newline="\n").write(t)
print("fallback inserted:", inserted)
