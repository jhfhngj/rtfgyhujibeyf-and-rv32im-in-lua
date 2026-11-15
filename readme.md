# MeaOS on RV32IM
Hello! You have probably never wanted to put RV32IM on a Luacontroller. I don't care! I did it anyway.

I built an OS for it, named MeaOS, with 3 tiers: MeaOS, MeaOS Server, and MeaOS Micro.

## What are the differences between the tiers?

MeaOS is the heavy one. About 3KB, and has all of the features.

MeaOS Server, is the medium one, without the shell, and a function() {} in cfg.h so you can configure it to run tasks endlessly. Until it halts. You can still turn that off.

MeaOS Micro, is the smallest one. The micro one. It has no shell, a function() {} in cfg.h, no lcd/kb I/O, and other features are missing! It's based on MeaOS Server, which itself is based off of MeaOS. It can reach ~400 bytes!


| Compare      | Server   | Micro      | Normal      |
| --------     | -------- | --------   | --------    |
| Size         | ~0.6KB   | ~0.4KB     | ~3KB        |
| Needs        | RV32IM   | RV32IM     | RV32IM      |
| Functions    | Medium   | Medium-low | Medium-high |

## Why are there tiers?
Why not?

## How do I get it?
Copy the `riscv.lua` of the tier you want, paste it into your Luacontroller PC, and run it! You can use it through terminal (if Server or Normal) or through keyboard on channel `kb` and screen on channel `lcd`!

## How do I reset it, or wake it up from `[CPU HALTED]`?
Either press `Execute` in the `Code` menu, or toggle Pin B.