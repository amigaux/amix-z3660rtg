# Changelog

## 2026-11-16 — fixed=1 on the Z3660's emulated 68030; module 1.1.2-2 (604c723..f9273a5)

With `fixed=1` the fixed base 0x10000000 is now read when the AutoConfig list holds any of the Z3660 firmware's identities: manufacturer 0x144B with product 1 (the RTG), 2 (its Zorro III RAM) or 3 (its Zorro II board). When the Z3660 runs its emulated 68030 (UAE_030_MMU, AutoConfig RTG off), the list holds only products 2 and 3. 1.1.2-1 required product 1, so it did not attach the RTG there (seen on an A4000T, firmware 1.03 beta 21); 1.1.1-4 had attached it. A machine with no 0x144B entry, a ZZ9000-only one included, still never has the fixed base read. The console line now says what it looked for. New host tests cover the 68030 list, each product on its own, an unknown product 4, the empty list and a ZZ9000-only list.

## 2026-11-15 — zz9k_probe takes a unit (a7b0509)

`zz9k_probe zz9000 0|1` asks one unit only: it opens only that unit's information node, exits 0 with `node /dev/zz900N` when the unit is a ZZ9000 (adding the `modes` line for Zorro III), and otherwise exits 1 with no output, so each display.d card file can cover one unit. `zz9000` with no unit and `z3660` work as before; any other form gives usage and exit 2.

## 2026-11-15 — zz9k_probe, the display start-up's probe (a431bed)

`zz9k_probe z3660|zz9000` (tools/zz9k_probe.c, zz9k_probe(1M)) says which board is behind the driver, for the
display.d card files. It reads only GETINFO through the information nodes /dev/zz9000i and /dev/zz9001i: a
read-only open, one ioctl, a close. `z3660` exits 0 when unit 0 is the Z3660 and prints `node /dev/zz9000`.
`zz9000` picks the first unit that is a ZZ9000 and prints its node; for a Zorro III card it adds a `modes` line
with 1920x1080. A bad argument gives exit 2. Host test tests/host/zz9k_probe_test.sh. The driver source is
unchanged and the module stays 1.1.2-1.

## 2026-11-15 — the emulator rows' findings; module 1.1.2-1 not yet published (06a1198..ee17d34)

The fixed base 0x10000000 is read only when the AutoConfig list holds the Z3660, so `fixed=1` on a machine without one
costs no bus timeout and reads no other card's memory. On the 68040/060 line the 8 MiB `kvfb` request halves to 4 MiB,
since the kernel's arena is shared with its heap: documented with its effect (the 1920x800 console scrolls by copying).
A known issue is noted: on the 68030 line a program drawing into a board mapped above 1 GB can be killed by the
kernel's bus-error probe. zz9k_test treats Zorro III and the Z3660 as supported boards and writes unbuffered. INSTALL
shows the four device nodes, 0660 and 0444 root sys. README explains two boards sharing the one monitor-switch line.
A host test checks that each attach line is printed once. The Z3660 register-write traces are unchanged.

## 2026-11-15 — real MNT ZZ9000 cards; module 1.1.2-1 (63644c7..a23d281)

The ZZ9000 Zorro II device no longer maps its register page, which holds the firmware-update, SD, USB, ethernet and
video-timing registers: the device is the framebuffer from offset 0 on every board (GETINFO `fb_offset` 0). On a
ZZ9000, `SVGAIOCSetMonitorSwitch` switches the card's own pass-through, and the last close puts it back on native
video unless the console is shown there. The blitter fill colour goes in RGB_HI, where the firmware reads it; the
ZZ9000 blitter stays off by default. A Zorro III ZZ9000 (product 4) is attached, mapped above 1 GB on both lines; on
the 68030 line the console takes the largest mode that fits in the mapped part. Two units, `/dev/zz9000` and
`/dev/zz9001`, the Z3660 always unit 0. GETINFO's `zorro`/`product` pairs have names in `zz9000.h` (`ZZ9K_IS_*`).
`module/README.md` and zz9000(7) added. On a k46.1.6 kernel the module asks for the fast framebuffer cache class
through a weak `DDI_FB_REGISTER`. What the Z3660 rows write to the card is unchanged (register-write traces
identical). Not yet run on a real ZZ9000 or in the emulator.

## 2026-11-01 — the review fixes, the sensors ioctl with ztop and xztop, a board above the identity map; module 1.1.1-1 (643a555..5c433fe)

Commands that change the board need a descriptor open for writing; raw register access, CONSOLE, PROBE and SETSWITCH
need privilege; GETREG/SETREG reach only the row's RTG registers (on the Z3660, 0x104 and 0x190–0x1AC are refused);
/dev/zz9000 is 0660 root:sys. Blitter bands default to 8192 px and BLITS has a per-call budget with a partial count.
The console runs guarded under spl7, scrolls by panning a ring, and pauses on a client's SETMODE. FILL is capped at
1 MiB per call. New, additions only: GETMODES, SENSORS, the read-only information node /dev/zz9000i (c 49 128, 0444),
ztop(1) and xztop(1). A board above VSECT1 is mapped automatically (dev_kvmap on k46, sptalloc on k30). The 1.1
launcher is x11/1.1/startx-rtg (no -ac); the 1.0 kit file is unchanged. Host tests in tests/host. docs/IOCTL-ABI.md.
Modules k30 0702dadf (37 742 B), k46 d0e7a7e3 (37 715 B).

## 2026-10-31 — docs and comments state facts without internal ids or scratch paths (7023ea9, 763b9a7)

Local tool files leave .gitignore. Module bytes unchanged (k30 0db1156d, k46 0a36d5fc); the X kit is unchanged
(KIT.sha256 afd7068c).

## 2026-10-29 — module/Makefile: MONSWMOD defaults into amix kernel/modules/monsw (0631925)

KIT examples point at ../../amix/kernel/dlm/build/kit/<line>; the README says where the kit and monsw come from
(github.com/amigaux/amix). Module bytes unchanged: k30 0db1156d, k46 0a36d5fc.

## Unreleased

- 2026-10-27 — README: why the module builds without `-DZZ9K_NO_BUILTINFONT` — it links the kit's sunfont.o with `builtinfont`
  localized and carries its own console font; the static 040/060 build has no font object and keeps the flag. Deliberate.
  Bytes unchanged, VERSION 1.1.0-1 (eded552).


- 2026-10-26 — The module's dependency gate runs against the real monsw module (amix-modules): MONSWINC is gone (sys/monsw.h
  comes from the kit, dc54ff4), MONSWMOD defaults to ../../amix-modules/monsw/build/<line>/mod.d/monsw; module bytes unchanged
  (4f8c3e33 / 21ccf3c5), modcheck ok on both lines; the check-only stand-in retired (e9d6a71).

- 2026-10-26 — Module form of the driver (amix-dlm C3-6 §3) behind `ZZ9K_MODULE`: `make module` builds
  z3660rtg.o (zz9000m.o + sunfont.o), z3660rtg.keys (demand class, major 49, depend=monsw, unload=allowed);
  one module probes both boards at run time; the console hook tests cp->screen == displayedscreen; static
  build byte-identical in 8 configurations (c6fa2e6, branch dlm-module).
- 2026-10-26 — The module packages' version (z3660rtg-k30 / z3660rtg-k46, amix-dlm C3-5 §1.1) lives in
  `module/VERSION`, one line `x.y.z-rev` for both lines: 1.1.0-1.

## 1.0 (amix-z3660rtg) - 2026-10-13

Initial public release of the fork: the Z3660 accelerator's onboard RTG as a second target.
The default build is upstream's ZZ9000 driver; `/dev/zz9000`, major 49 and the ioctl ABI
are unchanged.

### Driver
- Board table: identity, window, register file and mode table are data. The default rows
  reproduce upstream's behaviour. The Z3660 row is behind `-DZZ9K_TARGET_Z3660`: a 32-bit
  register file from 0x100, FW_VERSION at 0x1A0, the framebuffer as the whole device
  space, and modes 1920x1080 and 1280x800.
- Bench rows `-DZZ9K_BENCH_Z3` and `-DZZ9K_BENCH_Z3660` for amiberry's ZZ9000 Zorro III model
  and the Z3660-RTG stand-in.
- `ZZ9KIOC_CONPUTS` and the framebuffer console on the Z3660.
- The RTG monitor switch through the kernel's monsw (`-DZZ9K_MONSW`) and `ZZ9KIOC_GETMONSW`.
- The card blitter through `ZZ9KIOC_BLITS`, with a register cache. An optional non-cached
  framebuffer class (`-DZZ9K_FB_NC`) was measured and gave no gain.
- 68060 safety: no constant division (it compiles to 64-bit `MULS.L`), one message per miss.

### Tools
- `zz9k_cat`, `zz9k_reg`, `zz9k_demo`, `zz9k_maptest`, `zz9k_memprobe`, `zz9k_mode`,
  `zz9k_monsw`, `zz9k_rw`.
- `zz9k_test` accepts 1920x1080 and 1280x800, raises its own VM limit, and restores the display
  on an mmap failure.
- `bench/zzpanfix.c`, the stock-amiberry pan workaround.

### X (x11/)
- Build-tree patches for isoriano's X11R6.3 `Xzz9000`:
  - the two Z3660 modes;
  - the correctness fixes: raster ops in PolyFillRect, SetSpans and CopyArea, and
    window-to-window CopyArea exposures;
  - 32-bit stores;
  - the monitor-switch hook;
  - the card blitter in 8192-pixel bands;
  - the zero-width line bias;
  - the console keyboard handed back on exit.
- `startx-rtg`, `xinitrc-rtg` (the session ends when olwsm exits; no screen saver) and
  `rtg-kbdback`. The kit of record is pinned in `x11/KIT.sha256`.
- `x11/cross/`: the cross-build inputs (`host.def`, `imakecpp.sh`).
- `x11/bench/`: the measurement kit. It has x11perf R6.3, xbench, the discriminator clients and
  `zz9k_blitbench`, with a reproducible build.

### Validated
- Bench steps 0–3 on amiberry's ZZ9000 emulation and the Z3660-RTG stand-in.
- On metal (A4000, Z3660, 68LC060): the OpenLook desktop on the Z3660 HDMI, the release kit's
  correctness gates, and the blitter speed-ups.
- User `mmap` of `/dev/mem` stays broken on the r13 kernel lineage (the 68040/68060 port's
  ISSUE-46). It does not affect `/dev/zz9000`.

## 0.1.0 - 2026-07-03

- Initial public AMIX release.
- Zorro II product 3 discovery and attachment.
- Mode setting and RGB565/32-bit framebuffer mapping.
- Framebuffer information, fill, copy, pan, and display-switch ioctls.
- Color framebuffer console with late SysV init activation.
- Diagnostic, mode-test, console-control, and colorls tools.
- Interface used by the ZZ9000 X11R5 and X11R6.3 RTG servers.
