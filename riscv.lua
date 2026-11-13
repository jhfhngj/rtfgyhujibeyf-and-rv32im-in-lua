-- RV32IM Bare-Metal Emulator for Mesecons Luacontroller
local orig_print = print
print = function(...)
    orig_print(...)
    local args = {...}
    local parts = {}
    for i = 1, select("#", ...) do
        parts[i] = tostring(args[i])
    end
    digiline_send("lcd", table.concat(parts, "\t"))
end

local flr = math.floor
local schar, sbyte, ssub = string.char, string.byte, string.sub

local MOD32 = 4294967296
local function u32(x) return x % MOD32 end
local function s32(x) x = x % MOD32; return x >= 2147483648 and x - MOD32 or x end

local POW2 = {}
for i = 0, 32 do POW2[i] = 2 ^ i end

local function shl(a, b) b = b % 32; return (a * POW2[b]) % MOD32 end
local function shr(a, b) b = b % 32; return flr((a % MOD32) / POW2[b]) end
local function sra(a, b)
	b = b % 32
	local v = flr((a % MOD32) / POW2[b])
	if a >= 2147483648 and b > 0 then v = v + (MOD32 - POW2[32 - b]) end
	return v
end

local function bitop(a, b, mode)
	a, b = a % MOD32, b % MOD32
	local res, p = 0, 1
	for _ = 1, 32 do
		local aa, bb = a % 2, b % 2
		local bit
		if mode == 0 then bit = (aa == 1 and bb == 1) and 1 or 0
		elseif mode == 1 then bit = (aa == 1 or bb == 1) and 1 or 0
		else bit = (aa ~= bb) and 1 or 0 end
		if bit == 1 then res = res + p end
		a, b, p = (a - aa) / 2, (b - bb) / 2, p * 2
	end
	return res
end

local function sext(val, bits)
	local m = POW2[bits - 1]
	return (val % POW2[bits]) >= m and (val % POW2[bits]) - POW2[bits] or (val % POW2[bits])
end

local function read8(ram, addr)
	if addr == 0x10000000 then
		if #mem.rx > 0 then
			local c = sbyte(mem.rx, 1)
			mem.rx = ssub(mem.rx, 2)
			return c
		end
		return 0
	end
	local p = flr(addr / 256) + 1
	local page = ram[p]
	if not page then return 0 end
	return sbyte(page, (addr % 256) + 1) or 0
end

local function write8(ram, addr, val)
	val = val % 256
	if addr == 0x10000000 then
		if val == 10 then
			print(mem.tx)
			mem.tx = ""
		elseif val >= 32 and val <= 126 then
			mem.tx = mem.tx .. schar(val)
			if #mem.tx >= 64 then
				print(mem.tx)
				mem.tx = ""
			end
		end
		return
	end
	local p = flr(addr / 256) + 1
	if p < 1 or p > 128 then return end
	local page = ram[p] or string.rep("\0", 256)
	local off = (addr % 256) + 1
	ram[p] = ssub(page, 1, off - 1) .. schar(val) .. ssub(page, off + 1)
end

local function read32(ram, addr)
	return read8(ram, addr)
		+ read8(ram, addr + 1) * 256
		+ read8(ram, addr + 2) * 65536
		+ read8(ram, addr + 3) * 16777216
end

local function write32(ram, addr, val)
	val = val % MOD32
	write8(ram, addr, val % 256)
	write8(ram, addr + 1, flr(val / 256) % 256)
	write8(ram, addr + 2, flr(val / 65536) % 256)
	write8(ram, addr + 3, flr(val / 16777216) % 256)
end

if event.type == "program" then
	mem.r = {}
	for i = 0, 31 do mem.r[i] = 0 end
	mem.r[2] = 0x7FF0
	mem.pc = 0
	mem.ram = {}
	mem.tx = ""
	mem.rx = ""
	mem.halted = false

	-- Code:
local prog = {
        0x00008137, 0xff010113, 0x0b4000ef, 0x00100073, 0x10000737, 0x00054783, 0x00079463, 0x00008067, 0x00150513, 0x00f70023, 0xfedff06f, 0x00054783, 0x0005c703, 0x00078663, 0x00070463, 0x00e78863, 0x40e78533, 0x00153513, 0x00008067, 0x00150513, 0x00158593, 0xfd9ff06f, 0x00000793, 0x10000637, 0x00a00593, 0x00d00813, 0x00800893, 0x07f00313, 0x07e00e13, 0x00064683, 0x0ff6f713, 0xfe068ce3, 0x02b70863, 0x03070663, 0x01170463, 0x00671863, 0x00f02733, 0x40e787b3, 0xfddff06f, 0xfcfe4ce3, 0x00f506b3, 0x00e68023, 0x00178793, 0xfc9ff06f, 0x00f50533, 0x00050023, 0x00008067, 0xf6010113, 0x1a800513, 0x08112e23, 0x08812c23, 0x08912a23, 0x09212823, 0x09312623, 0x09412423, 0x09512223, 0xf31ff0ef, 0x1b800513, 0xf29ff0ef, 0x1cc00513, 0xf21ff0ef, 0x00010513, 0xf61ff0ef, 0x00010513, 0xf11ff0ef, 0x23000513, 0xf09ff0ef, 0x1d800593, 0x00010513, 0xf19ff0ef, 0x00050863, 0x1e000513, 0xef1ff0ef, 0xfc9ff06f, 0x21800593, 0x00010513, 0xefdff0ef, 0x00050a63, 0x22000513, 0xed5ff0ef, 0x00100073, 0xfa9ff06f, 0x23400593, 0x00010513, 0xeddff0ef, 0x02050663, 0x23c00513, 0xeb5ff0ef, 0x00010513, 0xef5ff0ef, 0x00010513, 0xea5ff0ef, 0x00010513, 0xe9dff0ef, 0x23000513, 0xfa5ff06f, 0x00014783, 0xf60784e3, 0x24400513, 0xe85ff0ef, 0x00010513, 0xe7dff0ef, 0x100007b7, 0x00a00713, 0x00e78023, 0xf49ff06f, 0x4f61654d, 0x2e312053, 0x00000a30, 0x00000000, 0x74696e49, 0x696c6169, 0x676e697a, 0x706e6920, 0x000a7475, 0x4f61654d, 0x0a3e2053, 0x00000000, 0x706c6568, 0x00000000, 0x6d6d6f43, 0x73646e61, 0x65680a3a, 0x203a706c, 0x6e65704f, 0x68742073, 0x650a7369, 0x3a746978, 0x6c614820, 0x43207374, 0x650a5550, 0x3a6f6863, 0x68634520, 0x00000a6f, 0x74697865, 0x00000000, 0x746c6148, 0x20676e69, 0x4f61654d, 0x2e2e2e53, 0x0000000a, 0x6f686365, 0x00000000, 0x74786554, 0x00000a3a, 0x6e6b6e55, 0x206e776f, 0x6d6d6f63, 0x3a646e61, 0x00000020
}
	for i, inst in ipairs(prog) do
		write32(mem.ram, (i - 1) * 4, inst)
	end
	interrupt(0.05)
	return
end

if event.type == "terminal" and event.text then
	mem.rx = mem.rx .. event.text .. "\n"
	return
end

if event.type == "digiline" and event.channel == "kb" and type(event.msg) == "string" then
	mem.rx = mem.rx .. event.msg .. "\n"
	return
end

if event.type == "on" and (event.pin == "B" or (type(event.pin) == "table" and event.pin.name == "B")) then
	if mem.halted then
		mem.pc = 0
		mem.r[2] = 0x7FF0
		mem.tx = ""
		mem.rx = ""
		mem.halted = false
		print("[CPU RESET]")
		interrupt(0.05)
	end
	return
end

if event.type == "interrupt" and not mem.halted then
	local r, ram, pc = mem.r, mem.ram, mem.pc

	for _ = 1, 12 do
		r[0] = 0
		local inst = read32(ram, pc)
		local op = inst % 128
		local rd = flr(inst / 128) % 32
		local f3 = flr(inst / 4096) % 8
		local rs1 = flr(inst / 32768) % 32
		local rs2 = flr(inst / 1048576) % 32
		local f7 = flr(inst / 33554432)
		local next_pc = u32(pc + 4)

		if op == 0x37 then
			r[rd] = u32(flr(inst / 4096) * 4096)
		elseif op == 0x17 then
			r[rd] = u32(pc + flr(inst / 4096) * 4096)
		elseif op == 0x6F then
			local imm = (flr(inst / 2147483648) * 1048576)
				+ ((flr(inst / 4096) % 256) * 4096)
				+ ((flr(inst / 1048576) % 2) * 2048)
				+ ((flr(inst / 2097152) % 1024) * 2)
			r[rd] = next_pc
			next_pc = u32(pc + sext(imm, 21))
		elseif op == 0x67 then
			local imm = sext(flr(inst / 1048576), 12)
			local t = u32(r[rs1] + imm)
			r[rd] = next_pc
			next_pc = t - (t % 2)
		elseif op == 0x63 then
			local imm = (flr(inst / 2147483648) * 4096)
				+ ((flr(inst / 128) % 2) * 2048)
				+ ((flr(inst / 33554432) % 64) * 32)
				+ ((flr(inst / 256) % 16) * 2)
			local a, b = r[rs1], r[rs2]
			local take = false
			if f3 == 0 then take = (a == b)
			elseif f3 == 1 then take = (a ~= b)
			elseif f3 == 4 then take = (s32(a) < s32(b))
			elseif f3 == 5 then take = (s32(a) >= s32(b))
			elseif f3 == 6 then take = (a < b)
			elseif f3 == 7 then take = (a >= b) end
			if take then next_pc = u32(pc + sext(imm, 13)) end
		elseif op == 0x03 then
			local addr = u32(r[rs1] + sext(flr(inst / 1048576), 12))
			if f3 == 0 then r[rd] = u32(sext(read8(ram, addr), 8))
			elseif f3 == 1 then r[rd] = u32(sext(read8(ram, addr) + read8(ram, addr + 1) * 256, 16))
			elseif f3 == 2 then r[rd] = read32(ram, addr)
			elseif f3 == 4 then r[rd] = read8(ram, addr)
			elseif f3 == 5 then r[rd] = read8(ram, addr) + read8(ram, addr + 1) * 256 end
		elseif op == 0x23 then
			local imm = sext(flr(inst / 33554432) * 32 + (flr(inst / 128) % 32), 12)
			local addr = u32(r[rs1] + imm)
			local v = r[rs2]
			if f3 == 0 then write8(ram, addr, v)
			elseif f3 == 1 then write8(ram, addr, v); write8(ram, addr + 1, flr(v / 256))
			elseif f3 == 2 then write32(ram, addr, v) end
		elseif op == 0x13 then
			local imm = sext(flr(inst / 1048576), 12)
			local uimm = u32(imm)
			local a = r[rs1]
			if f3 == 0 then r[rd] = u32(a + imm)
			elseif f3 == 2 then r[rd] = (s32(a) < imm) and 1 or 0
			elseif f3 == 3 then r[rd] = (a < uimm) and 1 or 0
			elseif f3 == 4 then r[rd] = bitop(a, uimm, 2)
			elseif f3 == 6 then r[rd] = bitop(a, uimm, 1)
			elseif f3 == 7 then r[rd] = bitop(a, uimm, 0)
			elseif f3 == 1 then r[rd] = shl(a, rs2)
			elseif f3 == 5 then r[rd] = (f7 == 32) and sra(a, rs2) or shr(a, rs2) end
		elseif op == 0x33 then
			local a, b = r[rs1], r[rs2]
			if f7 == 1 then
				if f3 == 0 then r[rd] = u32(s32(a) * s32(b))
				elseif f3 == 1 then r[rd] = u32(flr((s32(a) * s32(b)) / MOD32))
				elseif f3 == 2 then r[rd] = u32(flr((s32(a) * b) / MOD32))
				elseif f3 == 3 then r[rd] = u32(flr((a * b) / MOD32))
				elseif f3 == 4 then
					local sa, sb = s32(a), s32(b)
					r[rd] = (sb == 0) and 0xFFFFFFFF or u32(sa / sb >= 0 and flr(sa / sb) or math.ceil(sa / sb))
				elseif f3 == 5 then
					r[rd] = (b == 0) and 0xFFFFFFFF or flr(a / b)
				elseif f3 == 6 then
					local sa, sb = s32(a), s32(b)
					if sb == 0 then r[rd] = a
					else local q = sa / sb >= 0 and flr(sa / sb) or math.ceil(sa / sb); r[rd] = u32(sa - q * sb) end
				elseif f3 == 7 then
					r[rd] = (b == 0) and a or (a % b)
				end
			else
				if f3 == 0 then r[rd] = (f7 == 32) and u32(a - b) or u32(a + b)
				elseif f3 == 1 then r[rd] = shl(a, b % 32)
				elseif f3 == 2 then r[rd] = (s32(a) < s32(b)) and 1 or 0
				elseif f3 == 3 then r[rd] = (a < b) and 1 or 0
				elseif f3 == 4 then r[rd] = bitop(a, b, 2)
				elseif f3 == 5 then r[rd] = (f7 == 32) and sra(a, b % 32) or shr(a, b % 32)
				elseif f3 == 6 then r[rd] = bitop(a, b, 1)
				elseif f3 == 7 then r[rd] = bitop(a, b, 0) end
			end
		elseif op == 0x73 then
			if #mem.tx > 0 then print(mem.tx); mem.tx = "" end
			print("[CPU HALTED]")
			mem.halted = true
			return
		end
        if next_pc % 4 ~= 0 then
			if #mem.tx > 0 then print(mem.tx); mem.tx = "" end
			print(string.format("[Instruction address misaligned at 0x%08x -> 0x%08x - Halt]", pc, next_pc))
			mem.halted = true
			return
		end
		pc = next_pc
	end

	r[0] = 0
	mem.pc = pc
	interrupt(0.05)
end
