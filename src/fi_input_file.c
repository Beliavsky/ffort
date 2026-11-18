/* SPDX-License-Identifier: MIT
 * Bounded opt-in CLI input loader. No runtime Fortran unit reaches the host.
 * Files are opened read-only and verified as ordinary files before any read.
 * Windows is source-supported; POSIX is exercised by the verification suite.
 */
#ifndef _WIN32
#define _POSIX_C_SOURCE 200809L
#endif
#include <stddef.h>
#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#else
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#endif

/* 0 success, 1 open failure, 2 nonregular, 3 size cap, 4 short/changed/read error. */
int fi_load_input_file(const char *path, char *buffer, int capacity, int *length)
{
    int count = 0;
    if (!path || !buffer || !length || capacity < 0 || capacity > 1048576) return 3;
    *length = 0;
#ifdef _WIN32
    HANDLE file = CreateFileA(path, GENERIC_READ, FILE_SHARE_READ, NULL,
                             OPEN_EXISTING, FILE_FLAG_OPEN_REPARSE_POINT, NULL);
    BY_HANDLE_FILE_INFORMATION info;
    LARGE_INTEGER size;
    DWORD got;
    char extra;
    if (file == INVALID_HANDLE_VALUE) return 1;
    if (GetFileType(file) != FILE_TYPE_DISK ||
        !GetFileInformationByHandle(file, &info) ||
        (info.dwFileAttributes & (FILE_ATTRIBUTE_DIRECTORY | FILE_ATTRIBUTE_REPARSE_POINT))) {
        CloseHandle(file); return 2;
    }
    if (!GetFileSizeEx(file, &size) || size.QuadPart < 0 || size.QuadPart > capacity) {
        CloseHandle(file); return 3;
    }
    while (count < (int)size.QuadPart) {
        if (!ReadFile(file, buffer + count, (DWORD)((int)size.QuadPart - count), &got, NULL) || !got) {
            CloseHandle(file); return 4;
        }
        count += (int)got;
    }
    if (!ReadFile(file, &extra, 1, &got, NULL) || got) { CloseHandle(file); return 4; }
    if (!CloseHandle(file)) return 4;
#else
    struct stat info;
    int flags = O_RDONLY | O_NONBLOCK;
    int file;
    ssize_t got;
    char extra;
#ifdef O_NOFOLLOW
    flags |= O_NOFOLLOW;
#endif
#ifdef O_CLOEXEC
    flags |= O_CLOEXEC;
#endif
    file = open(path, flags);
    if (file < 0) return 1;
    if (fstat(file, &info) || !S_ISREG(info.st_mode)) { close(file); return 2; }
    if (info.st_size < 0 || info.st_size > capacity) { close(file); return 3; }
    while (count < (int)info.st_size) {
        got = read(file, buffer + count, (size_t)((int)info.st_size - count));
        if (got < 0 && errno == EINTR) continue;
        if (got <= 0) { close(file); return 4; }
        count += (int)got;
    }
    do { got = read(file, &extra, 1); } while (got < 0 && errno == EINTR);
    if (got != 0) { close(file); return 4; }
    if (close(file)) return 4;
#endif
    *length = count;
    return 0;
}
