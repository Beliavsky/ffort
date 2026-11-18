/* SPDX-License-Identifier: MIT
 * Host console detection and bounded batch source stdin, never runtime input.
 */
#ifndef _WIN32
#define _POSIX_C_SOURCE 200809L
#endif
#include <stdio.h>
#ifdef _WIN32
#include <io.h>
#define FI_ISATTY _isatty
#define FI_FILENO _fileno
#else
#include <unistd.h>
#define FI_ISATTY isatty
#define FI_FILENO fileno
#endif

int fi_stdin_is_terminal(void)
{
    return FI_ISATTY(FI_FILENO(stdin)) ? 1 : 0;
}

/* 0 complete, 1 read failure, 2 capacity exceeded; no implicit file writes. */
int fi_read_stdin_source(char *buffer, int capacity, int *length)
{
    int c, n = 0;
    if (!buffer || !length || capacity < 0 || capacity > 1048576) return 2;
    *length = 0;
    while ((c = fgetc(stdin)) != EOF) {
        if (n == capacity) return 2;
        buffer[n++] = (char)c;
    }
    if (ferror(stdin)) return 1;
    *length = n;
    return 0;
}
