import io

p = r"C:\Users\Administrator\Desktop\work\bsd45\RESUME-TASK.md"
t = io.open(p, encoding="utf-8", newline="").read().replace("\r\n", "\n")

# ---------------------------------------------------------------- header
old_head = '''更新时间：2026-11-13（Asia/Shanghai）
状态：**S9 完成**（vnode/VFS 统一层，ISO9660 与 tmpfs 共用一套接口）。
下一步：页回收、作业控制、更多工具、更完整的 VFS。
仓库：https://github.com/moccuishle/BSD45_rootfs_shell_finished'''
new_head = '''更新时间：2026-11-13（Asia/Shanghai）
状态：**S9 完成**（vnode/VFS 统一层）；Windows 与 Linux(Ubuntu 26.04 LTS) 双平台构建、
启动与 7 套验收全部通过；内核目录已整理（`kernel/libkern` → `kernel/lib`，
`include/libkern` → `include/lib`）。
下一步：**S10**（页/vnode 回收与缓存 → 作业控制 + 信号投递 → `/bin/rm`、`/bin/cp`
等工具 → 真正的 mount 表与 `chdir`/相对路径）。
仓库：https://github.com/moccuishle/BSD_overlay_finished'''
assert old_head in t
t = t.replace(old_head, new_head, 1)

# ---------------------------------------------------------------- section 0
sec0 = '''## 0. 在新机器上恢复（clone 仓库 → 继续 S10）

### 0.1 取代码

```bash
git clone git@github.com:moccuishle/BSD_overlay_finished.git
cd BSD_overlay_finished
# 4.4BSD-Lite2 源码树不在 git 里（体积大），仓库根有 4.4BSD-Lite2.tar.gz，
# 首次构建会自动解包到 bsd45/src/BSD45（tools/ensure-src.sh / ensure-src.ps1）
```

### 0.2 Linux（推荐，已实测）

```bash
sudo apt install build-essential gcc-multilib libc6-dev-i386 binutils \\
                 genisoimage qemu-system-x86 bison flex python3
cd bsd45
bash build_all.sh          # userland -> /bin/sh -> /test -> kernel -> ISO
bash verify.sh             # 启动 + 检查内核 banner / ISO 根
bash tools/test_s3.sh      # 7 套：s3 s4 test_proc test_tty s7 s8 s9
```

产物：`bsd45/out/BSD45-ELF-x86.iso`（约 4.2 MB）、`bsd45/build/bsd45.elf`。

### 0.3 Windows（历史路径，PS 脚本保持可用）

```powershell
$env:MKISOFS='C:\\Program Files (x86)\\VMware\\VMware Workstation\\mkisofs.exe'
$env:QEMU='C:\\msys64\\ucrt64\\bin\\qemu-system-i386.exe'
powershell -NoProfile -ExecutionPolicy Bypass -File .\\build_all.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\\tools\\test_s9.ps1
```

### 0.4 关键路径速查

| 内容 | 位置 |
|---|---|
| 内核入口/启动 | `kernel/arch/i386/i386/locore.s`、`kernel/arch/i386/isa/machdep.c` |
| 内核运行时 glue | `kernel/other/glue.c`、`stubs.c`、`strings.c`、`mon.c` |
| 用户态/系统调用 | `kernel/other/usermode.c`、`usermode_asm.s` |
| VFS / 后端 | `kernel/fs/vfs.c`、`kernel/fs/isofs.c`、tmpfs 在 `vfs.c` 内 |
| 进程/fd/管道 | `kernel/other/usermode.c`（`struct uproc`、`proc_sched`、`fd_*`） |
| libc 子集 | `libc/src/`（`libc_sys.c` 是 syscall 粘合层） |
| 用户工具源码 | `libc/src/{echo,ls,cat,mkdir,printf,test}.c` |
| 4.4BSD sh | `src/BSD45/usr/src/bin/sh`（构建时拷到 `build/shgen`） |
| 链接脚本 | `boot/kernel.ld`（Linux ELF）；Windows 走 PE + defsym |
| 测试驱动 | `tools/run_qemu_test.sh`（串口 TCP + `/dev/tcp`） |

### 0.5 已知坑（补）

44. **符号下划线**：mingw 自动给 C 符号加 `_`，Linux ELF 不加，而 4.4BSD
    汇编按 `_name` 引用 → Linux 构建统一加 `-fleading-underscore`。
45. **64 位除法**：加了下划线后 gcc 要 `___divdi3`，libgcc 只有 `__divdi3`
    → `build_sh.sh` 链接 4.4BSD `kernel/lib` 的 quad 例程。
46. **测试脚本的 `|`**：`run_qemu_test.sh` 用 `|` 分隔多条输入，真实管道要写
    `\\|`（如 `echo hi \\| cat`）。
47. **串口读取**：后台 `cat` 要用 `stdbuf -o0`，否则最后一行
    `[user exit N]` 会丢。

'''

anchor = "## 1. 任务目标（原始需求）"
assert anchor in t
t = t.replace(anchor, sec0 + anchor, 1)

# ---------------------------------------------------------------- section 7
old_sec7 = t[t.index("## 7. 下一步（S9 之后）"):]
new_sec7 = '''## 7. S10 任务（下一步，按优先级）

目标：把"能跑"变成"像个系统"。四个方向按依赖顺序做，每步都要能过现有 7 套
验收 + 新增验收。

### S10.1 页 / vnode 回收与缓存（最先做，其它都依赖它）

现状：`struct vnode` 池固定（96 个），`vn_put` 只减引用不回收；物理页
`page_alloc()` 只分配不释放；tmpfs 文件数据页永不归还；反复
`open/close/exec/cat` 后池子耗尽。

要做：

1. **物理页回收**：`pmap` 里记录页引用（或简单的 free list），实现
   `page_free(pa)`；`pmap_map` 的临时窗口用完即 `pmap_unmap`；给
   `struct uproc` 的页目录/用户栈在 `proc_exit` 时释放。
2. **vnode 缓存**：`vn_put` 到 0 时进 LRU（`vnode->v_usecount==0` 挂
   freelist 尾部）；需要时从 LRU 复用并调 `vop_inactive`；
   加 `vnode` 统计（`vfs_vnode_stats()`，monitor 命令 `vstat`）。
3. **tmpfs 页回收**：`tmpfs_truncate`/`tmpfs_remove` 释放数据页；
   `rm`/`>` 覆盖时先释放旧页。
4. **验收**：新 `tools/test_s10.sh`：
   - `for i in 1 2 ... 50; do cat /readme.txt > /dev/null; done`（或 sh 循环）；
   - 交错 `mkdir /tmp/d$i; ls /tmp; rmdir /tmp/d$i` 50 次；
   - 每次打印 `vstat`，池用量必须回落；`free pages` 不得单调下降。

### S10.2 信号投递 + 作业控制

现状：没有 `kill(2)`、没有信号；`proc_sched` 是协作式；`wait4` 只有
`WIFEXITED`。

要做：

1. **进程结构**：`struct uproc` 增加 `p_sig`（待投递位图）、`p_sigmask`、
   `p_sigignore`、`p_sigcatch[NSIG]`、`p_pgrp`、`p_session`、`p_flag`
   （`SSTOP`/`SWTED`）。
2. **投递点**：`resume_user` 返回用户态之前检查 `p_sig & ~p_sigmask`；
   有则把 `ucontext`（寄存器 + 栈）压到用户栈，PC 设为 handler，
   `%eax` 设为 sig；handler `ret` 到 trampoline 调 `sigreturn`。
3. **系统调用**：`kill(2)`、`signal(3)`（`sigaction` 简化版）、
   `sigprocmask`、`sigreturn`、`wait4` 支持 `WIFSTOPPED`/`WIFSIGNALED`。
4. **终端**：`pccon.c` 的 `^C`/`^Z`/`^\\\\` 生成 `SIGINT`/`SIGTSTP`/`SIGQUIT`
   给前台进程组；`tcsetpgrp` 可后做。
5. **sh**：4.4BSD sh 的 `jobs`/`fg`/`bg`/`kill` 已编译进来（`jobs.c`），
   接上 `kill(2)`、`wait4` STOP 状态后应可直接用。
6. **验收**：`tools/test_sig.sh`：`sleep 100 &`、`jobs`、`kill %1`、
   `cat` 后 Ctrl-C、`echo $?` 130、`fg` 恢复。

### S10.3 `/bin/rm`、`/bin/cp` 等工具

现状：VFS 有 `create/remove/mkdir/rmdir/truncate`，但 syscall 层缺
`unlink`/`rename`/`link`；用户态只有 echo/ls/cat/mkdir/printf/test。

要做：

1. **syscall**：`unlink(2)`、`rmdir(2)`、`rename(2)`、`link(2)`、`chmod(2)`
   （后两个可先返回 `ENOSYS`），全部走 `vnodeops`。
2. **工具**：`libc/src/rm.c`（`unlink`/`rmdir` + `-r` 递归用 `opendir`）、
   `cp.c`（`open(O_CREAT|O_TRUNC)` + 读循环）、`mv.c`（`rename` 失败再
   `cp`+`unlink`）、`wc.c`、`grep.c`（简单子串）。
3. **ISO 只读**：`rm`/`cp` 写到 `/tmp` 要能工作；对 ISO 上文件 `unlink`
   返回 `EROFS`。
4. **验收**：`cp /readme.txt /tmp/r; cat /tmp/r; rm /tmp/r; mkdir /tmp/x;
   rmdir /tmp/x; rm /nonexistent`（报错但不崩）。

### S10.4 真正的 mount 表与 `chdir`/相对路径

现状：`/tmp` 在 `vfs_init` 里硬编码挂 tmpfs；路径必须是绝对路径。

要做：

1. **mount 表**：`struct mount { vnode *m_root; char *m_path; mount *m_next; }`，
   `vfs_mount(path, fs)`/`vfs_unmount(path)`；`/` 与 `/tmp` 走同一套。
2. **cwd**：`struct uproc` 增 `p_cwd`（vnode 引用）；`chdir(2)`/`getcwd(2)`；
   `namei` 支持相对路径（起点 `p_cwd`）、`..` 到根钳制、`//` 折叠。
3. **sh**：`cd`、`pwd`、相对路径重定向（`> a`）随之可用；`execve` 的
   路径解析同样走 `namei`。
4. **验收**：`cd /tmp; pwd; echo hi > a; cat a; cd ..; pwd;
   cat readme.txt`（相对）、`cd /nope` 报错。

## 8. 提交与恢复

- 每完成一个子任务：`bash tools/test_s3.sh ... test_s9.sh` 全绿 + 新增
  `test_s10*.sh`，然后 `git add -A && git commit`，推到
  `git@github.com:moccuishle/BSD_overlay_finished.git`（main）。
- 恢复方式：clone 仓库 → 按第 0 节构建 → 从第 7 节 S10.1 开始。
- 构建产物不进 git（`bsd45/build/`、`bsd45/out/`、`bsd45/src/` 已忽略），
  仓库根有 `4.5BSD-jialiang.tar.gz` 作为完整快照。
'''
t = t[:t.index("## 7. 下一步（S9 之后）")] + new_sec7

io.open(p, "w", encoding="utf-8", newline="\n").write(t)
print("RESUME-TASK.md updated:", len(t.splitlines()), "lines")
