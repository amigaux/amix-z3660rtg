# module/: the driver as an Amix kernel module

`make KIT=<amix>/kernel/dlm/build/kit/k30` (or `k46`) builds `build/<line>/mod.d/z3660rtg`
from the static driver's source (`../overlay/usr/sys/amiga/driver/zz9000`) with
`-DZZ9K_MODULE -DZZ9K_TARGET_Z3660 -DZZ9K_MONSW`, and the kit's checker passes it. The
`Makefile` header lists the inputs (`KIT`, `MONSWMOD`, `LOCALIZE_OBJCOPY`). `z3660rtg.keys`
holds the module's keys; `Master` is generated from it. `VERSION` is the module's version,
which the packages carry. `zz9000.7` is the manual page of the device.

## Boards

One object serves every board the driver knows, found at run time:

| Board | Found by | `GETINFO` zorro/product |
|---|---|---|
| The Z3660's onboard RTG | its AutoConfig entry (`0x144b`/1), or its fixed base at `0x10000000` with `fixed=1` | 3 / 1 |
| An MNT ZZ9000, Zorro II | AutoConfig `0x6d6e`/3 | 2 / 3 |
| An MNT ZZ9000, Zorro III | AutoConfig `0x6d6e`/4; above 1 GB through kernel mappings | 3 / 4 |

Two boards are served at once: unit 0 (`/dev/zz9000`, minor 0) and unit 1 (`/dev/zz9001`,
minor 1), each with its information node (minors 128 and 129). The Z3660 is always unit 0;
a ZZ9000 card beside it is unit 1.

## Parameters

| Name | Default | Meaning |
|---|---|---|
| `blit` | 1 | use the card's blitter where the board's row has it (the Z3660; not the ZZ9000) |
| `fixed` | 0 | also look for the Z3660 at its fixed base (amiberry's Z3660 has no AutoConfig entry) |
| `kvfb` | 0 | MiB of a framebuffer above 1 GB mapped for the kernel; 0 = the line's default, 8 on k46, 2 on k30 |
| `maxarea` | 8192 | pixels per blitter band (0 = the default) |

On the 68030 line a ZZ9000 Zorro III card's console needs `kvfb=3` for its 1920x800 mode;
with the default it takes 1280x720 and says so on the console.

## Loading on the released kernels

The module imports only what the 1.1 kits export (its kabi tags are `k30.1.2` and
`k46.1.2`, as the 1.1 module's), so it loads on the released 1.1 kernels of both lines.
