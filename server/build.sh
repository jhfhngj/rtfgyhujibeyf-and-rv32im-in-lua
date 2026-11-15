#!/usr/bin/env bash
set -e

riscv64-unknown-elf-gcc -march=rv32im -mabi=ilp32 -Os -nostdlib -ffreestanding -T link.ld os.c -o os.elf
riscv64-unknown-elf-objcopy -O binary os.elf os.bin

SIZE=$(wc -c < os.bin)
echo "Compiled os.bin: ${SIZE} bytes / 32768 bytes"

python3 -c '
import struct
data = open("os.bin", "rb").read()
data += b"\x00" * ((4 - len(data) % 4) % 4)
words = struct.unpack("<" + "I" * (len(data) // 4), data)
print("local prog = {\n\t" + ", ".join(f"0x{w:08x}" for w in words) + "\n}")
'
