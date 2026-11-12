import io, re

W = r"C:\Users\Administrator\Desktop\work"
LAYOUT = """
## 目录布局

```
bsd45/
  kernel/                   内核（4.4BSD-Lite2 sys 树与自有内核代码合并）
    include/sys/            原 usr/src/sys/sys 的头文件
    include/machine/        原 sys/i386/include
    arch/i386/i386/         机器相关源码（locore.s、machdep.c、pmap.c、cons.c）
    arch/i386/{isa,conf,...}  i386 下的驱动/配置/启动代码
    fs/                     ufs/miscfs/isofs/nfs + 自有的 vfs.c、isofs.c
    vm/                     Mach VM（pmap 源）
    driver/                 dev + 自有的 atapi.c、pccon.c
    net/                    net/netinet/netiso/netccitt/netns
    other/                  kern、conf、libkern、tests + 自有的 glue.c/mon.c/
                            usermode.c/stubs.c/strings.c
  libc/                     用户态 C 库与工具
    include/                stdarg.h、ctype.h、histedit.h（用户态头文件）
    src/                    crt0.s、libc_sys.c、dtoa.c … 与 hello/init/sh/ls/
                            cat/mkdir/echo/t_libc 等程序
  rootfs_overlay/           ISO 根文件系统的覆盖层
    bin/ sbin/ usr/ tmp/ etc/ home/ include/ sys/
    etc/profile             /etc/profile
    README.TXT              /readme.txt
  boot/                      stage1/stage2（El Torito 引导）
  overlay/                   4.4BSD 源码的本地补丁（按 kernel 树镜像）
  tools/                     ensure-src、clean、测试脚本
  docs/                      USERLAND-PLAN.md
  vms/                       VMware 虚拟机定义
  src/BSD45/                 仍由 tarball 解出的 4.4BSD 用户态源码
                             （usr/src/lib、usr/src/bin/sh 等，构建时使用）
```

`kernel/include/sys`、`kernel/arch`、`kernel/vm`、`kernel/net`、`kernel/driver/dev`
等 4.4BSD 子树由 `tools/ensure-src.ps1` 从 tarball 解出后自动归位，不进入 git；
仓库只跟踪自有的 kernel/libc/rootfs_overlay 代码。
"""
for path in (W + r"\README.md", W + r"\bsd45\README.md"):
    t = io.open(path, encoding="utf-8").read()
    t = re.sub(r"## 目录与清理.*?(?=\n## 许可)", LAYOUT + "\n## 许可", t, flags=re.S)
    io.open(path, "w", encoding="utf-8", newline="\n").write(t)
print("readme layout ok")
