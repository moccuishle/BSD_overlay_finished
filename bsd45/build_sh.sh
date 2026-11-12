#!/usr/bin/env bash
# build_sh.sh - build the real 4.4BSD /bin/sh (and the small tools) as ELF32.
#
#   build_sh.sh            -> out/userland/sh.elf + echo/ls/cat/mkdir
#   build_sh.sh -t test    -> out/userland/test.elf (the self test)
set -uo pipefail
ws="$(cd "$(dirname "$0")" && pwd)"
. "$ws/tools-find.sh"

target="sh"
while [ $# -gt 0 ]; do
    case "$1" in
        -t|--target) target="$2"; shift 2 ;;
        *) echo "usage: $0 [-t sh|test]" >&2; exit 2 ;;
    esac
done

usr="$ws/src/BSD45/usr/src"
shsrc="$usr/bin/sh"
lc="$usr/lib/libc"
bld="$ws/build"
incu="$bld/incu"
gen="$bld/shgen"
obj="$bld/shobj"
outd="$ws/out/userland"
mkdir -p "$bld" "$incu" "$gen" "$obj" "$outd"

# the 4.4BSD userland tree is extracted from the tarball on demand
if [ ! -f "$usr/lib/libc/gen/opendir.c" ]; then
    bash "$ws/tools/ensure-src.sh"
fi

require_tools gcc ld

step() { echo "== $1"; }
fail=0

prepare_headers() {
    mkdir -p "$incu/sys" "$incu/machine" "$incu/net"
    [ -d "$incu" ] || return 0
    cp -f "$ws/libc/include/stdarg.h" "$incu/stdarg.h"
    cp -f "$ws/libc/include/ctype.h"  "$incu/ctype.h"
    cp -f "$ws/libc/include/histedit.h" "$incu/histedit.h"
    [ -f "$incu/errno.h" ] && return 0
    step "preparing libc header view"
    # 4.4BSD usr/include + the kernel headers, from the merged layout
    cp -f "$usr/include/"*.h "$incu/" 2>/dev/null
    cp -f "$ws/kernel/include/sys/"*.h "$incu/" 2>/dev/null
    cp -f "$ws/kernel/include/sys/"*.h "$incu/sys/" 2>/dev/null
    cp -f "$ws/kernel/include/machine/"*.h "$incu/machine/" 2>/dev/null
    cp -f "$ws/kernel/net/net/"*.h "$incu/net/" 2>/dev/null
    cp -f "$ws/kernel/include/machine/ansi.h"   "$incu/machine/ansi.h"   2>/dev/null
    cp -f "$ws/kernel/include/machine/limits.h" "$incu/machine/limits.h" 2>/dev/null
    cp -f "$ws/kernel/include/machine/float.h"  "$incu/machine/float.h"  2>/dev/null
    cp -f "$ws/kernel/include/sys/termios.h" "$incu/termios.h" 2>/dev/null
}

prepare_headers

gccinc="$(find_gcc_include)"
common=(-m32 -std=gnu89 -O2 -ffreestanding -fno-builtin
    -fno-pie -fno-pic -fno-stack-protector
    -fno-asynchronous-unwind-tables -fno-unwind-tables
    -fno-strict-aliasing -fcommon
    -march=i386 -mno-sse -mno-sse2 -mno-mmx -mno-avx
    -mpreferred-stack-boundary=2
    -nostdinc -I "$incu" -I "$gen" -I "$shsrc"
    -isystem "$gccinc" -DSHELL)

compile_c() {    # compile_c <src> <out> [extra flags...]
    local src="$1" out="$2"; shift 2
    if [ ! -f "$src" ]; then echo "  missing $src"; fail=$((fail+1)); return 1; fi
    local log
    log="$(gcc "${common[@]}" "$@" -c -o "$out" "$src" 2>&1)"
    if [ $? -ne 0 ]; then
        echo "FAIL $(basename "$src")"
        echo "$log" | head -12 | sed 's/^/   /'
        fail=$((fail+1)); return 1
    fi
    return 0
}

compile_asm() {
    local src="$1" out="$2" log
    log="$(gcc -m32 -x assembler-with-cpp -nostdinc -I "$incu" -c -o "$out" "$src" 2>&1)"
    if [ $? -ne 0 ]; then
        echo "FAIL $(basename "$src")"
        echo "$log" | head -12 | sed 's/^/   /'
        fail=$((fail+1)); return 1
    fi
    return 0
}

objs=()
add() { objs+=("$1"); }

step "startup objects"
compile_asm "$ws/libc/src/crt0.s" "$obj/crt0.o" && add "$obj/crt0.o"
compile_asm "$ws/libc/src/jmp.s"  "$obj/jmp.o"  && add "$obj/jmp.o"

step "port glue"
compile_c "$ws/libc/src/libc_sys.c"      "$obj/libc_sys.o"      && add "$obj/libc_sys.o"
compile_c "$ws/libc/src/dtoa.c"          "$obj/dtoa.o"          && add "$obj/dtoa.o"
compile_c "$ws/libc/src/histedit_stub.c" "$obj/histedit_stub.o" && add "$obj/histedit_stub.o"

step "4.4BSD libc subset"
libc_files=(
    string/strcat.c string/strcmp.c string/strcpy.c
    string/strcspn.c string/strdup.c string/strlen.c string/strncat.c
    string/strncmp.c string/strncpy.c string/strpbrk.c
    string/strsep.c string/strspn.c string/strstr.c string/strtok.c
    string/strcasecmp.c string/strerror.c
    string/memchr.c string/memcmp.c
    stdlib/atoi.c stdlib/atol.c stdlib/strtol.c
    stdlib/strtoul.c stdlib/malloc.c
    stdlib/calloc.c stdlib/exit.c stdlib/atexit.c stdlib/getenv.c
    stdlib/qsort.c stdlib/abs.c stdlib/div.c stdlib/ldiv.c stdlib/rand.c
    stdlib/abort.c stdlib/getopt.c gen/setmode.c gen/wait3.c gen/exec.c
    stdio/findfp.c stdio/flags.c stdio/fclose.c stdio/fopen.c
    stdio/fprintf.c stdio/fgets.c stdio/fputs.c stdio/fread.c
    stdio/fwrite.c stdio/fputc.c stdio/putc.c stdio/putchar.c
    stdio/printf.c stdio/vfprintf.c stdio/sprintf.c stdio/snprintf.c
    stdio/vsnprintf.c stdio/vsprintf.c stdio/perror.c stdio/fflush.c
    stdio/refill.c stdio/rget.c stdio/wbuf.c stdio/wsetup.c
    stdio/makebuf.c stdio/setvbuf.c stdio/fwalk.c stdio/fpurge.c
    stdio/fseek.c stdio/ftell.c stdio/rewind.c stdio/fdopen.c
    stdio/fileno.c stdio/feof.c stdio/ferror.c stdio/clrerr.c
    stdio/ungetc.c stdio/gets.c stdio/puts.c stdio/getc.c
    stdio/getchar.c stdio/fgetc.c
    gen/isatty.c gen/opendir.c gen/readdir.c gen/closedir.c
    gen/telldir.c gen/seekdir.c gen/rewinddir.c
    gen/glob.c gen/fnmatch.c
    stdio/stdio.c stdio/fvwrite.c
)
for f in "${libc_files[@]}"; do
    o="$obj/lc_$(basename "${f%.c}").o"
    extra=()
    case "$f" in stdio/*) extra=(-I "$lc/stdio") ;; esac
    compile_c "$lc/$f" "$o" "${extra[@]}" && add "$o"
done

# files 4.4BSD compiles several times with different macros
multi_src=(string/bcopy.c string/memset.c string/index.c string/rindex.c string/swab.c)
multi_def=("bcopy:" "memcpy:-DMEMCOPY" "memmove:-DMEMMOVE" "memset:" "bzero:-DBZERO"
           "index:" "strchr:-DSTRCHR" "rindex:" "strrchr:-DSTRRCHR" "swab:")
for spec in "${multi_def[@]}"; do
    name="${spec%%:*}"; def="${spec#*:}"
    case "$name" in
        bcopy|memcpy|memmove) src="$lc/string/bcopy.c" ;;
        memset|bzero)         src="$lc/string/memset.c" ;;
        index|strchr)         src="$lc/string/index.c" ;;
        rindex|strrchr)       src="$lc/string/rindex.c" ;;
        swab)                 src="$lc/string/swab.c" ;;
    esac
    [ -f "$src" ] || continue
    dflags=()
    [ -n "$def" ] && dflags=("$def")
    compile_c "$src" "$obj/lc_$name.o" "${dflags[@]}" && add "$obj/lc_$name.o"
done

compile_c "$ws/libc/src/errlst.c"      "$obj/lc_errlst.o"    && add "$obj/lc_errlst.o"
compile_c "$ws/libc/src/ctype_table.c" "$obj/ctype_table.o"  && add "$obj/ctype_table.o"

if [ "$fail" -ne 0 ]; then echo "$fail file(s) failed" >&2; exit 1; fi
libobjs=("${objs[@]}")

if [ "$target" = "sh" ]; then
    step "generating sh sources"
    cp -f "$shsrc/"*.c "$shsrc/"*.h "$shsrc/"*.y "$shsrc/"*.l "$gen/" 2>/dev/null
    cp -f "$shsrc/"mktokens "$shsrc/"mkbuiltins "$gen/" 2>/dev/null
    for f in token.def builtins.c builtins.h; do cp -f "$shsrc/$f" "$gen/" 2>/dev/null; done
    cp -f "$ws/libc/src/"* "$gen/" 2>/dev/null

    ( cd "$gen" && sh mktokens ) || true
    [ -f "$gen/token.def" ] || { echo "mktokens failed" >&2; fail=$((fail+1)); }
    ( cd "$gen" && sh mkbuiltins . ) || true
    [ -f "$gen/builtins.c" ] || { echo "mkbuiltins failed" >&2; fail=$((fail+1)); }

    step "generating nodes/syntax/init"
    hostflags=(-std=gnu89 -O1 -include "$ws/libc/src/hostgen/hostshim.h" -I "$shsrc")
    gcc "${hostflags[@]}" -o "$gen/mknodes"  "$ws/libc/src/hostgen/mknodes.c"  || fail=$((fail+1))
    gcc "${hostflags[@]}" -o "$gen/mksyntax" "$shsrc/mksyntax.c"               || fail=$((fail+1))
    gcc "${hostflags[@]}" -o "$gen/mkinit"   "$shsrc/mkinit.c" "$ws/libc/src/hostgen/hoststub.c" || fail=$((fail+1))
    if [ -x "$gen/mknodes" ] && [ -x "$gen/mksyntax" ] && [ -x "$gen/mkinit" ]; then
        ( cd "$gen" && ./mknodes nodetypes nodes.c.pat ) || true
        ( cd "$gen" && ./mksyntax ) || true
        srcs="$(cd "$shsrc" && ls *.c | grep -v -E '^(mknodes|mksyntax|mkinit)\.c$' | tr '\n' ' ')"
        ( cd "$gen" && ./mkinit "cc -c init.c" $srcs ) >/dev/null 2>&1 || true
    fi
    for f in init.c nodes.c syntax.c; do
        [ -f "$gen/$f" ] || { echo "missing $f" >&2; fail=$((fail+1)); }
    done

    step "bison/flex"
    ( cd "$gen" && sed -e 's/= {/{/' arith.y | grep -v -E '^[[:space:]]*(yyerrok|yyclearin);' > arith_sane.y )
    ( cd "$gen" && bison -y -d arith_sane.y ) 2>&1 | head -8
    [ -f "$gen/y.tab.c" ] && cp -f "$gen/y.tab.c" "$gen/arith.c"
    ( cd "$gen" && flex -o arith_lex.c arith_lex.l ) 2>&1 | head -8

    step "compiling sh"
    sh_c=(alias.c cd.c error.c eval.c exec.c expand.c input.c
          jobs.c mail.c main.c memalloc.c miscbltin.c mystring.c
          options.c parser.c redir.c show.c trap.c output.c var.c
          builtins.c init.c nodes.c syntax.c arith.c arith_lex.c)
    for f in "${sh_c[@]}"; do
        compile_c "$gen/$f" "$obj/sh_${f%.c}.o" && add "$obj/sh_${f%.c}.o"
    done
    compile_c "$shsrc/bltin/echo.c" "$obj/sh_echo_builtin.o" && add "$obj/sh_echo_builtin.o"
    if [ -f "$usr/usr.bin/printf/printf.c" ]; then
        compile_c "$usr/usr.bin/printf/printf.c" "$obj/sh_printf.o" -I "$usr/usr.bin/printf" && add "$obj/sh_printf.o"
    fi
else
    step "compiling libc test program"
    compile_c "$ws/libc/src/t_libc.c" "$obj/t_libc.o" && add "$obj/t_libc.o"
fi

if [ "$fail" -ne 0 ]; then echo "$fail file(s) failed" >&2; exit 1; fi

step "linking"
libgcc="$(gcc -m32 -print-libgcc-file-name)"
elf="$outd/sh.elf"
[ "$target" = "test" ] && elf="$outd/test.elf"
ld -m elf_i386 -Ttext 0x08048000 -e _start -o "$elf" "${objs[@]}" "$libgcc" || {
    echo "link failed" >&2; exit 1; }
echo "built $elf ($(stat -c%s "$elf" 2>/dev/null || wc -c < "$elf") bytes)"

if [ "$target" = "sh" ]; then
    for tool in echo ls cat mkdir; do
        tobj="$obj/$tool.o"
        if compile_c "$ws/libc/src/$tool.c" "$tobj"; then
            ld -m elf_i386 -Ttext 0x08048000 -e _start -o "$outd/$tool.elf" \
                "${libobjs[@]}" "$tobj" "$libgcc" && \
                echo "built $outd/$tool.elf ($(stat -c%s "$outd/$tool.elf" 2>/dev/null || wc -c < "$outd/$tool.elf") bytes)"
        fi
    done
fi
