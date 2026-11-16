# module/: the driver as an Amix kernel module

`make KIT=<amix>/kernel/dlm/build/kit/k30` (or `k46`) builds `build/<line>/mod.d/z3660rtg`
from the static driver's source (`../overlay/usr/sys/amiga/driver/zz9000`) with
`-DZZ9K_MODULE -DZZ9K_TARGET_Z3660 -DZZ9K_MONSW -DZZ9K_ZZ9KBUS`, and the kit's checker passes
it. The `Makefile` header lists the inputs (`KIT`, `MONSWMOD`, `ZZ9KBUSMOD`,
`LOCALIZE_OBJCOPY`). The zz9kbus service channel is registered for the Z3660 only; a ZZ9000
card's row describes no service block. `z3660rtg.keys`
holds the module's keys; `Master` is generated from it. `VERSION` is the module's version,
which the packages carry. `zz9000.7` is the manual page of the device.

## Boards

One object serves every board the driver knows, found at run time:

| Board | Found by | `GETINFO` zorro/product |
|---|---|---|
| The Z3660's onboard RTG | its AutoConfig entry (`0x144b`/1), or its fixed base at `0x10000000` with `fixed=1` (the emulated 68030 modes) | 3 / 1 |
| An MNT ZZ9000, Zorro II | AutoConfig `0x6d6e`/3 | 2 / 3 |
| An MNT ZZ9000, Zorro III | AutoConfig `0x6d6e`/4; above 1 GB through kernel mappings | 3 / 4 |

Two boards are served at once: unit 0 (`/dev/zz9000`, minor 0) and unit 1 (`/dev/zz9001`,
minor 1), each with its information node (minors 128 and 129). The Z3660 is always unit 0;
a ZZ9000 card beside it is unit 1. `zz9k_probe z3660|zz9000 [0|1]` (`../overlay/.../zz9000/tools/zz9k_probe.c`,
zz9k_probe(1M)) tells display.d's card files which board is on which unit, from `GETINFO`
on the information nodes alone.

Each board's last close returns only that board to native: a ZZ9000 through its own
pass-through, the Z3660 through the machine's monitor-switch line (monsw). A board that holds
the kernel console stays on RTG. The switch line is one for the machine: the console's output
sets it to RTG whichever board the console is on, so with X on the Z3660 and the console on a
ZZ9000, `monswctl status` reads native when X exits and RTG again at the next console line.

## Parameters

| Name | Default | Meaning |
|---|---|---|
| `blit` | 1 | use the card's blitter where the board's row has it (the Z3660; not the ZZ9000) |
| `fixed` | 0 | also look for the Z3660 RTG at its fixed base (a Z3660 running its emulated 68030, and amiberry's RTG stand-in, list no AutoConfig entry for it); read only when the AutoConfig list holds a Z3660 identity (manufacturer 0x144B, product 1, 2 or 3), so never on a machine without one |
| `kvfb` | 0 | MiB of a framebuffer above 1 GB mapped for the kernel; 0 = the line's default, 8 on k46, 2 on k30; a request the kernel cannot meet halves until it can |
| `maxarea` | 8192 | pixels per blitter band (0 = the default) |

On the 68030 line a ZZ9000 Zorro III card's console needs `kvfb=3` for its 1920x800 mode;
with the default it takes 1280x720 and says so on the console.

On the 68040/68060 line the mapping comes from the kernel's virtual arena (8 MiB on current
kernels, 4 MiB on older ones), which the kernel heap shares, so the 8 MiB default is never
met in full: the request halves and the attach line says what was mapped, `0x400000` (4 MiB)
on the emulator rows. With 4 MiB the 1920x800 console fits (3 MiB) but has no room for its
pan ring, so each scroll copies the screen (the CPU on a ZZ9000, slow across Zorro III);
`read`, `write`, `FILL` and the CPU fills and copies reach the first 4 MiB (`ENXIO` beyond,
which matters only for 16-bit modes above 1920x1080). User `mmap`, and so X, reach the
whole framebuffer either way. `kvfb=3` leaves the kernel heap more room and keeps the console.

## Loading on the released kernels

The module imports only what the 1.1 kits export (its kabi tags are `k30.1.2` and
`k46.1.2`, as the 1.1 module's), so it loads on the released 1.1 kernels of both lines.

## The framebuffer's cache class (k46)

At load the module asks the core for the fast class of unit 0's framebuffer window
(`DDI_FB_REGISTER`, `fb_register`, k46.1.6; amix-dlm contract C3-6 section 5): non-cacheable
but not serialised, so CPU stores to the framebuffer drain through the 68060's store buffer.
The register page keeps the serialised class. The reference is weak: on a k46 kernel before
1.6 the call does nothing and the module loads as before (its kabi tag stays `k46.1.2`); on
k30 there is no such class and no reference. The core reports an install or a refusal on
one console line.

## Known issue: a ZZ9000 Zorro III card on the 68030 line

On a k30 kernel a program drawing into its mapping of a board above 1 GB (a ZZ9000 in a real
Zorro III slot) can be killed by a `User BUS ERROR` (`FAULT:1`, after a console line
`WARNING: Hardware Bus Error @ <address>, (<physical> physical)`). The kernel's fault handler
probes the physical address of a valid user page as if it were a kernel address, which is true
only inside the first gigabyte, so a bus error there that it would otherwise retry ends the
process. The driver's page frames are right (the warning shows the expected physical address).
Seen in emulation only, under sustained drawing; k46 is not affected. A ZZ9000 configured as
Zorro II, or drawing through `write(2)`, avoids it.
