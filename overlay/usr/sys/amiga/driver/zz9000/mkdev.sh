#!/bin/sh
#
# Create the AMIX device nodes for the ZZ9000 framebuffer driver.
# This matches the documented cdevsw major 49 integration.
# 0660 root:sys: the X server runs as root; the node gives others nothing.
#
# Copyright (c) 2026 Ignacio Soriano; changes Copyright (c) 2026 Jussi Alanärä.
# SPDX-License-Identifier: MIT

rm -f /dev/zz9000 /dev/zz9000i
mknod /dev/zz9000 c 49 0
chown root /dev/zz9000
chgrp sys /dev/zz9000
chmod 660 /dev/zz9000
# the information node (minor 128): board info and sensors only, for everyone (ztop)
mknod /dev/zz9000i c 49 128
chown root /dev/zz9000i
chgrp sys /dev/zz9000i
chmod 444 /dev/zz9000i
# unit 1 (minor 1, information node 129): a second board, e.g. a ZZ9000 card beside a Z3660
rm -f /dev/zz9001 /dev/zz9001i
mknod /dev/zz9001 c 49 1
chown root /dev/zz9001
chgrp sys /dev/zz9001
chmod 660 /dev/zz9001
mknod /dev/zz9001i c 49 129
chown root /dev/zz9001i
chgrp sys /dev/zz9001i
chmod 444 /dev/zz9001i
ls -l /dev/zz9000 /dev/zz9000i /dev/zz9001 /dev/zz9001i
