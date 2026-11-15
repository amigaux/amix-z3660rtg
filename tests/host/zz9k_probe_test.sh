#!/bin/sh
# zz9k_probe_test.sh -- zz9k_probe's output, exit status and device calls against fake
# units (zz9k_probe_shim.c).  Exit 0 = all passed.
# Copyright (c) 2026 Jussi Alanärä.  SPDX-License-Identifier: MIT
set -e
here=$(cd "$(dirname "$0")" && pwd)
src=$here/../../overlay/usr/sys/amiga/driver/zz9000
out=${TMPDIR:-/tmp}/zz9k-probe-test.$$
mkdir -p "$out"
trap 'rm -rf "${out:?}"' 0
CC=${CC:-cc}
$CC -std=gnu89 -w -Dopen=fake_open -Dioctl=fake_ioctl -Dclose=fake_close -I"$src" \
	-o "$out/zz9k_probe" "$src/tools/zz9k_probe.c" "$here/zz9k_probe_shim.c"
fail=0
check() {
	if [ "$2" = "$3" ]; then echo "ok   $1"; else echo "FAIL $1: got [$2] want [$3]"; fail=1; fi
}
GETINFO=$(printf '0x%x' $(( (90 << 8) | 1 )))	# ('Z' << 8) | 1
# run <u0> <u1> <args...>: sets rc, so (stdout, ';'-joined), se (stderr), calls (the log)
run() {
	u0=$1 u1=$2; shift 2
	: > "$out/log"
	rc=0
	PROBE_U0=$u0 PROBE_U1=$u1 PROBE_LOG=$out/log "$out/zz9k_probe" "$@" \
		> "$out/so" 2> "$out/se" < /dev/null || rc=$?
	so=$(tr '\n' ';' < "$out/so")
	se=$(cat "$out/se")
	calls=$(tr '\n' ';' < "$out/log")
}
# one unit asked: open read-only (flags 0), one GETINFO on that descriptor, close
asked() { echo "open /dev/zz900${1}i 0;ioctl 3 $GETINFO;close 3;"; }
refused() { echo "open /dev/zz900${1}i 0;"; }
MODES="1024x768 640x480 800x600 1280x720 1280x1024 1920x800"

run z3660 empty z3660
check "Z3660 alone, z3660: exit 0" "$rc" 0
check "Z3660 alone, z3660: the node" "$so" "node /dev/zz9000;"
check "Z3660 alone, z3660: unit 0 asked, nothing else" "$calls" "$(asked 0)"
run z3660 empty zz9000
check "Z3660 alone, zz9000: exit 1" "$rc" 1
check "Z3660 alone, zz9000: no output" "$so$se" ""
check "Z3660 alone, zz9000: both units asked" "$calls" "$(asked 0)$(asked 1)"

run z2 empty zz9000
check "ZZ9000 Zorro II alone, zz9000: exit 0" "$rc" 0
check "ZZ9000 Zorro II alone, zz9000: the node, no modes" "$so" "node /dev/zz9000;"
check "ZZ9000 Zorro II alone, zz9000: unit 0 asked only" "$calls" "$(asked 0)"
run z2 empty z3660
check "ZZ9000 Zorro II alone, z3660: exit 1" "$rc" 1
check "ZZ9000 Zorro II alone, z3660: no output" "$so$se" ""

run z3 empty zz9000
check "ZZ9000 Zorro III alone, zz9000: exit 0" "$rc" 0
check "ZZ9000 Zorro III alone, zz9000: the node and the modes line" "$so" \
	"node /dev/zz9000;modes $MODES 1920x1080;"
run z3 empty z3660
check "ZZ9000 Zorro III alone, z3660: exit 1 (zorro 3 but product 4)" "$rc" 1

run z3660 z2 z3660
check "both, z3660: exit 0" "$rc" 0
check "both, z3660: unit 0" "$so" "node /dev/zz9000;"
check "both, z3660: unit 1 not asked" "$calls" "$(asked 0)"
run z3660 z2 zz9000
check "both, zz9000: exit 0" "$rc" 0
check "both, zz9000: /dev/zz9001" "$so" "node /dev/zz9001;"
check "both, zz9000: unit 0 then unit 1 asked" "$calls" "$(asked 0)$(asked 1)"
run z3660 z3 zz9000
check "Z3660 and a Zorro III ZZ9000, zz9000: /dev/zz9001 and modes" "$so" \
	"node /dev/zz9001;modes $MODES 1920x1080;"

for a in z3660 zz9000; do
	run nodev nodev $a
	check "no unit (the module refuses to load), $a: exit 1" "$rc" 1
	check "no unit (the module refuses to load), $a: no output" "$so$se" ""
	check "no unit (the module refuses to load), $a: opens only" "$calls" \
		"$(refused 0)$( [ $a = zz9000 ] && refused 1)"
	run nonode nonode $a
	check "no nodes (a chroot without them), $a: exit 1, no output" "$rc:$so$se" "1:"
	run empty empty $a
	check "no board on either unit, $a: exit 1, no output" "$rc:$so$se" "1:"
done

for args in "" "zz9001" "Z3660" "z3660 zz9000" "-h"; do
	run z3660 z2 $args
	check "bad argument [$args]: exit 2" "$rc" 2
	check "bad argument [$args]: usage on stderr only" "$so|$se" "|usage: zz9k_probe z3660|zz9000"
	check "bad argument [$args]: no device call" "$calls" ""
done

# the program names no other system call that could reach a device: its undefined symbols
$CC -std=gnu89 -w -I"$src" -c -o "$out/p.o" "$src/tools/zz9k_probe.c"
und=$(nm -u "$out/p.o" | awk '{print $NF}' | sed 's/@.*//' |
	grep -v -x -e printf -e fprintf -e strcmp -e memset -e stderr -e puts -e fwrite -e fputs \
		-e _GLOBAL_OFFSET_TABLE_ -e __stack_chk_fail | sort | tr '\n' ' ')
check "no call but open, ioctl and close" "$und" "close ioctl open "
exit $fail
