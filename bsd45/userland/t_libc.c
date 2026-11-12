/*
 * t_proc - fork/vfork/wait4 smoke test (built as /test).
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/wait.h>
#include <termios.h>
#include <fcntl.h>
#include <sys/stat.h>

static char *vav[3] = { "echo", "vfork-exec-ok", 0 };
static char *venv[2] = { "PATH=/bin", 0 };

static void
say(const char *s, int n)
{
	write(1, s, n);
}

int
main(int argc, char **argv)
{
	pid_t pid;
	int status;

	{
		struct termios t;
		int r = tcgetattr(0, &t);

		printf("tty: isatty=%d/%d/%d tcgetattr=%d\n",
		    isatty(0), isatty(1), isatty(2), r);
		if (r == 0)
			printf("tty: iflag=%x oflag=%x cflag=%x lflag=%x\n",
			    t.c_iflag, t.c_oflag, t.c_cflag, t.c_lflag);
	}

	{
		int fd, n2;
		char tb[64];

		fd = open("/tmp/t", O_WRONLY | O_CREAT | O_TRUNC, 0666);
		printf("tmpfs: open=%d\n", fd);
		if (fd >= 0) {
			n2 = write(fd, "tmpfs-data\n", 11);
			printf("tmpfs: wrote=%d\n", n2);
			close(fd);
		}
		if (stat("/tmp/t", &tb[0]) == 0)
			printf("tmpfs: stat ok\n");
		fd = open("/tmp/t", O_RDONLY);
		if (fd >= 0) {
			n2 = read(fd, tb, sizeof(tb));
			if (n2 > 0) {
				write(1, "tmpfs-read: ", 12);
				write(1, tb, n2);
			}
			close(fd);
		}
	}

	{
		int pfd[2];
		char b[32];
		int n;

		if (pipe(pfd) == 0) {
			write(pfd[1], "pipe-ok\n", 8);
			n = read(pfd[0], b, sizeof(b));
			if (n > 0) {
				write(1, "pipe: ", 6);
				write(1, b, n);
			}
			close(pfd[0]);
			close(pfd[1]);
		} else
			printf("pipe: failed\n");
	}

	say("S:fork\n", 7);
	pid = fork();
	if (pid == 0) {
		say("C:fork\n", 7);
		_exit(5);
	}
	pid = wait4(-1, &status, 0, (struct rusage *)0);
	printf("fork waited pid=%d code=%d\n", pid, WEXITSTATUS(status));

	say("S:vfork\n", 8);
	pid = vfork();
	if (pid == 0) {
		execve("/bin/echo", vav, venv);
		_exit(1);
	}
	say("P:vfork\n", 8);
	pid = wait4(-1, &status, 0, (struct rusage *)0);
	printf("vfork waited pid=%d code=%d\n", pid, WEXITSTATUS(status));

	printf("done\n");
	exit(0);
}
