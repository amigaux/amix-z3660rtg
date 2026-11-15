/*
 * zz9k_probe.c - which board is behind the RTG driver, for the display
 * start-up's card files (display.d(4), PROBES).
 *
 * Copyright (c) 2026 Jussi Alanärä.  SPDX-License-Identifier: MIT
 *
 *   zz9k_probe z3660     exit 0 when unit 0 is the Z3660's RTG
 *   zz9k_probe zz9000    exit 0 when a unit is an MNT ZZ9000; prints its node
 *                        (and, in a Zorro III slot, its modes)
 *
 * Each unit is asked through its information node (0444, any user) with
 * ZZ9KIOC_GETINFO only: open read-only, one ioctl, close.  The driver answers
 * it from what it found at load; nothing is written to a board, the main
 * node is never opened.  A unit whose node cannot be opened or that gives no
 * answer (ENXIO: no board) is not there.  Nothing goes to the standard error
 * unless the argument is wrong.  See zz9k_probe(1M).
 */

#include <stdio.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/ioctl.h>
#include "zz9000.h"

#define NUNITS  2

static char *infonode[NUNITS] = { "/dev/zz9000i", "/dev/zz9001i" };
static char *mainnode[NUNITS] = { "/dev/zz9000", "/dev/zz9001" };

/*
 * The ZZ9000's modes for X at 16 bits, the default first: the card file's
 * list (a Zorro II card's 4 MB window less the register page and the
 * firmware's tail holds 3.8 MB of framebuffer, 1920x800 at most); a Zorro III
 * card's 50 MB adds 1920x1080.  All are in the driver's ZZ9000 mode table.
 */
#define ZZ9000_MODES    "1024x768 640x480 800x600 1280x720 1280x1024 1920x800"
#define ZZ9000_Z3_MORE  "1920x1080"

static int
getinfo(unit, ip)
int unit;
struct zz9k_info *ip;
{
    int fd, r;

    memset((char *)ip, 0, sizeof *ip);
    fd = open(infonode[unit], O_RDONLY);
    if (fd < 0)
        return 0;
    r = ioctl(fd, ZZ9KIOC_GETINFO, ip);
    close(fd);
    return r == 0;
}

int
main(argc, argv)
int argc;
char **argv;
{
    struct zz9k_info in;
    int u;

    if (argc == 2 && strcmp(argv[1], "z3660") == 0) {
        if (!getinfo(0, &in) || !ZZ9K_IS_Z3660(&in))
            return 1;
        printf("node %s\n", mainnode[0]);
        return 0;
    }
    if (argc == 2 && strcmp(argv[1], "zz9000") == 0) {
        for (u = 0; u < NUNITS; ++u) {
            if (!getinfo(u, &in))
                continue;
            if (ZZ9K_IS_ZZ9000_Z2(&in)) {
                printf("node %s\n", mainnode[u]);
                return 0;
            }
            if (ZZ9K_IS_ZZ9000_Z3(&in)) {
                printf("node %s\nmodes %s %s\n", mainnode[u], ZZ9000_MODES,
                    ZZ9000_Z3_MORE);
                return 0;
            }
        }
        return 1;
    }
    fprintf(stderr, "usage: zz9k_probe z3660|zz9000\n");
    return 2;
}
