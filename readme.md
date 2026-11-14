# MeaOS & RV32IM in Lua

A bare-metal **RV32IM** RISC-V emulator written in Lua for **Mesecons Luacontrollers** in Luanti / Minetest (built on **VE-Creative**), paired with **MeaOS 1.0**—a freestanding C operating system compiled from scratch.

## Overview

Instead of using fake Lua-scripted terminal props, this project implements a real 32-bit RISC-V processor (`RV32IM`, `IALIGN=32`) inside a single Luacontroller block and runs genuine compiled C machine code (`riscv64-unknown-elf-gcc`).

### Hardware Specifications (Virtual CPU)
* **Architecture:** `RV32IM` (Unprivileged Base Integer + Hardware Multiply/Divide)
* **Instruction Alignment:** `IALIGN=32` (4-byte aligned instruction fetches)
* **Memory:** 32 KB (`32,768` bytes) flat RAM (`0x00000000` – `0x00007FFF`)
* **Stack Pointer:** Initialized at `0x7FF0`
* **Clock Speed:** ~154–240 Hz (12 instructions per `0.05s` Mesecons interrupt to stay server-friendly)
* **Physical Hardware Reset:** Pulsing **Pin B** warm-reboots the CPU (`PC = 0x00000000`, `SP = 0x7FF0`) while preserving RAM contents

### Memory-Mapped I/O (MMIO)

| Address | Peripheral | Description |
| :--- | :--- | :--- |
| `0x0200BFF8` | `CLINT mtime` (Low) | Standard 64-bit real-time counter lower 32 bits (10 MHz tick rate) |
| `0x0200BFFC` | `CLINT mtime` (High) | Standard 64-bit real-time counter upper 32 bits |
| `0x10000000` | UART TX / RX | Write ASCII bytes to output to Digilines LCD (`lcd`); read bytes from Digilines Keyboard (`kb`) |

---

## MeaOS 1.0 & Standard Libraries

**MeaOS** is a minimal freestanding operating system written in C (`os.c`) with zero external C standard library (`-nostdlib -ffreestanding`), supported by two custom headers:

* **`text.h`:** Memory-mapped UART console I/O (`putchar`, `puts`, `getchar`, `gets`), string comparison (`streq`), and integer formatting (`print_uint`).
* **`math.h`:** 64-bit software compiler runtime intrinsics (`__udivdi3`, `__ashldi3`, `__lshrdi3`) enabling full `uint64_t` division and bit shifts on a 32-bit processor without `libgcc`.

### Built-In Shell Commands
* `help` — Lists available shell commands.
* `sysinfo` — Dynamically probes live hardware stats (stack pointer depth, free/used RAM, measured CPU speed in Hz, endianness, and CLINT uptime).
* `bench` — Runs a prime-number sieve (`primes < 100`) timed against the 10 MHz `CLINT mtime` counter.
* `time` — Prints total uptime in seconds since boot or Pin B reset.
* `echo` — Prompts for text and echoes it back to the terminal.
* `exit` — Executes `ebreak` to cleanly halt the CPU until Pin B is triggered.

---

## Project Structure

* `os.c` — MeaOS kernel, startup routine (`_start`), dynamic hardware probe, benchmark, and interactive shell.
* `text.h` — Bare-metal UART I/O and string utilities.
* `math.h` — Freestanding 64-bit arithmetic intrinsics for RV32.
* `link.ld` — Custom linker script mapping `.text`, `.rodata`, `.data`, `.bss`, and `_end` starting at `0x00000000`.
* `build.sh` — One-command build script that compiles `os.c`, strips ELF headers into a raw binary (`os.bin`), checks the 32 KB size budget, and outputs a copy-pasteable Lua `local prog = { ... }` array.

---

## Building & Running

### Prerequisites
* `riscv64-unknown-elf-gcc` (and `binutils`)
* `python3`

### 1. Compile MeaOS
Run the build script to compile the C source and generate the Lua machine-code table:
```bash
./build.sh
```
This outputs the compiled byte size (`bytes / 32768 bytes`) followed by `local prog = { ... }`.

### 2. Flash to a Luacontroller
1. Place a **Mesecons Luacontroller** in Luanti / Minetest.
2. Wire a **Digilines LCD / Monitor** (channel `lcd`) and **Digilines Keyboard** (channel `kb`).
3. Optionally wire a button or switch to **Pin B** for hardware reset.
4. Paste the Lua emulator script with your generated `local prog = { ... }` table into the Luacontroller and click **Execute**.

---

## Credits & Acknowledgments
* Built and tested on **VE-Creative**.
* Also check out [cheapie's `rvcontroller`](https://cheapiesystems.com/git/rvcontroller).
