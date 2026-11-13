# Linux 构建验证（Ubuntu）

本项目已在实际 Ubuntu 上用 Bash 脚本完整构建并启动验证通过。

## 环境

| 项目 | 版本 |
|---|---|
| 发行版 | Ubuntu 26.04 LTS Server (VMware 虚拟机, NAT) |
| gcc | 15.2.0 (含 gcc-multilib) |
| binutils / ld | 2.46 |
| genisoimage | 1.1.11 |
| qemu-system-i386 | 10.2.1 |
| bison / flex | 3.8.2 / 2.6.4 |

## 构建与测试

```bash
sudo apt install build-essential gcc-multilib libc6-dev-i386 binutils \
                 genisoimage qemu-system-x86 bison flex python3
cd bsd45
bash build_all.sh                 # userland -> /bin/sh -> /test -> kernel -> ISO
bash tools/test_s3.sh             # ... s4, test_proc, test_tty, s7, s8, s9
```

结果：

- 产物：`out/BSD45-ELF-x86.iso`（4,247,552 字节）、`build/bsd45.elf`
- `verify.sh`：kernel banner / ISO9660 root / monitor 全部 PASSED
- 7 个验收测试 **全部 PASSED**：S3 sh、S4 ISO root、S5 fork/vfork/wait4、
  S6 tty、S7 目录+glob+管道、S8 tmpfs、S9 vnode/VFS

## 为 Linux 做的适配（只改 `.sh`，`.ps1` 不变）

1. **符号下划线**：Windows/mingw 会给 C 符号自动加 `_`，ELF 不会，而 4.4BSD
   的汇编（`locore.s`、`icu.s`）和本项目的 `usermode_asm.s`、`crt0.s` 都按
   `_name` 引用。Bash 版编译统一加 `-fleading-underscore`，与 mingw 行为一致。
2. **入口符号**：`libc/src/hello.c` 的入口由 `_start` 改名 `start`
   （加下划线后正好是 `_start`，两种平台一致）。
3. **64 位除法**：加 `-fleading-underscore` 后 gcc 引用 `___divdi3`，而 libgcc
   只提供 `__divdi3`；`build_sh.sh` 改为链接 4.4BSD `kernel/lib` 的
   quad 例程（`divdi3.c`/`qdivrem.c` 等 19 个文件），不依赖 libgcc 符号名。
4. **串口测试**：`tools/run_qemu_test.sh` 原用 `|` 分隔按键，与 shell 管道
   冲突；现支持 `\|` 转义（测试脚本里的 `echo hi \| cat` 即真实管道）。
5. **串口读取**：后台读取器改用 `stdbuf -o0`，避免最后一行 `[user exit N]`
   滞留在缓冲区。

## 与 Windows 版的关系

Windows 上仍用 `*.ps1`（`gcc -m32` COFF → `ld -m i386pe` PE →
`objcopy -O elf32-i386`）；Linux 上 `gcc -m32` 直接产出 ELF，`build_*.sh` 用
`ld -m elf_i386` + `boot/kernel.ld` 链接，不需要 PE 转换这一步。
