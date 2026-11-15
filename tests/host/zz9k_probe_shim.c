/*
 * zz9k_probe_shim.c -- zz9k_probe on the host: open, ioctl and close answer
 * from fake units and log every call, so the probe's output and its calls
 * can be checked.
 *
 *   PROBE_U0, PROBE_U1  what the unit is: z3660, z2, z3 (a board), empty (the
 *                       node opens, GETINFO gives ENXIO), nodev (the open
 *                       gives ENXIO: the module did not load), nonode (ENOENT)
 *   PROBE_LOG           the file every call is appended to
 *
 * Copyright (c) 2026 Jussi Alanärä.  SPDX-License-Identifier: MIT
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include "zz9000.h"

static char *fdunit[16];

static void
logf_(const char *fmt, const char *s, long a, long b)
{
    char *p = getenv("PROBE_LOG");
    FILE *f;

    if (!p || !(f = fopen(p, "a")))
        return;
    fprintf(f, fmt, s, a, b);
    fputc('\n', f);
    fclose(f);
}

static char *
unitkind(const char *name)
{
    char *k = 0;

    if (strcmp(name, "/dev/zz9000i") == 0)
        k = getenv("PROBE_U0");
    else if (strcmp(name, "/dev/zz9001i") == 0)
        k = getenv("PROBE_U1");
    return k ? k : "nonode";
}

int
fake_open(const char *name, int flags, ...)
{
    char *k = unitkind(name);
    int fd;

    logf_("open %s %ld%.0ld", name, (long)flags, 0L);
    if (strcmp(k, "nonode") == 0) {
        errno = ENOENT;
        return -1;
    }
    if (strcmp(k, "nodev") == 0) {
        errno = ENXIO;
        return -1;
    }
    for (fd = 3; fd < 16 && fdunit[fd]; ++fd)
        ;
    fdunit[fd] = k;
    return fd;
}

int
fake_ioctl(int fd, unsigned long cmd, void *arg)
{
    struct zz9k_info *in = arg;
    char *k;

    logf_("ioctl%s %ld 0x%lx", "", (long)fd, (long)cmd);
    if (fd < 3 || fd >= 16 || !(k = fdunit[fd])) {
        errno = EBADF;
        return -1;
    }
    if (cmd != ZZ9KIOC_GETINFO) {
        errno = EPERM;
        return -1;
    }
    memset(in, 0, sizeof *in);
    if (strcmp(k, "z3660") == 0) {
        in->zorro = 3; in->product = 1;
    } else if (strcmp(k, "z2") == 0) {
        in->zorro = 2; in->product = 3;
    } else if (strcmp(k, "z3") == 0) {
        in->zorro = 3; in->product = 4;
    } else {
        errno = ENXIO;
        return -1;
    }
    in->width = 800; in->height = 600;
    return 0;
}

int
fake_close(int fd)
{
    logf_("close%s %ld%.0ld", "", (long)fd, 0L);
    if (fd < 3 || fd >= 16 || !fdunit[fd]) {
        errno = EBADF;
        return -1;
    }
    fdunit[fd] = 0;
    return 0;
}
