/*
 * mkdir(1) - create directories (exercises the S8 tmpfs mkdir syscall).
 */
#include <sys/stat.h>
#include <sys/types.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>

int
main(int argc, char **argv)
{
	int i, rc = 0;

	if (argc < 2) {
		fprintf(stderr, "usage: mkdir dir ...\n");
		return (1);
	}
	for (i = 1; i < argc; i++) {
		if (mkdir(argv[i], 0777) < 0) {
			fprintf(stderr, "mkdir: %s: %s\n", argv[i],
			    strerror(errno));
			rc = 1;
		}
	}
	return (rc);
}
