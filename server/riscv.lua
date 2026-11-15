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
if addr == 0x10001001 then
	if #mem.dl_rx > 0 then
		local c = sbyte(mem.dl_rx, 1)
		mem.dl_rx = ssub(mem.dl_rx, 2)
		return c
	end
	return 0
elseif addr == 0x10001002 then
	return math.min(#mem.dl_rx, 255)
end

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
	if addr == 0x10001000 then
	if val >= 32 and val <= 126 and #mem.dl_chan < 32 then
		mem.dl_chan = mem.dl_chan .. schar(val)
	end
	return
elseif addr == 0x10001001 then
	if val >= 1 and val <= 127 and #mem.dl_tx < 128 then
		mem.dl_tx = mem.dl_tx .. schar(val)
	end
	return
elseif addr == 0x10001002 then
	if val == 1 then
		if #mem.dl_chan > 0 then
			digiline_send(mem.dl_chan, mem.dl_tx)
		end
		mem.dl_chan = ""
		mem.dl_tx = ""
	elseif val == 2 then
		mem.dl_rx = ""
	end
	return
end
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
	if addr == 0x0200BFF8 then
		return (mem.mtime or 0) % MOD32
	elseif addr == 0x0200BFFC then
		return flr((mem.mtime or 0) / MOD32) % MOD32
	end
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
mem.mtime = 0
mem.dl_chan = ""
mem.dl_tx = ""
mem.dl_rx = ""
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
        0x00008137, 0xff010113, 0x100000ef, 0x00100073, 0x0200c7b7, 0x0200c737, 0xffc78793, 0xff870713, 0x0007a683, 0x00072503, 0x0007a583, 0xfed59ae3, 0x00008067, 0x10000737, 0x00054783, 0x00079463, 0x00008067, 0x00150513, 0x00f70023, 0xfedff06f, 0x10001737, 0x100016b7, 0x00002537, 0x00270713, 0x00168693, 0x00d00313, 0x07e00e13, 0x40150513, 0x10001f37, 0x00100f93, 0x00074783, 0x00079463, 0x00008067, 0x0006c803, 0x2b002783, 0x0ff87893, 0x05036e63, 0x01155833, 0x00187813, 0x04080863, 0xfcf05ce3, 0x23000813, 0x00f807b3, 0x00078023, 0x19800813, 0x23000793, 0x00084883, 0x00089c63, 0x0007c803, 0x00081e63, 0x01f70023, 0x2a002823, 0xfa9ff06f, 0x00180813, 0x011f0023, 0xfddff06f, 0x00178793, 0x01068023, 0xfd9ff06f, 0xf8fe46e3, 0x00178813, 0x2b002823, 0x23000813, 0x00f807b3, 0x01178023, 0xf75ff06f, 0xfe010113, 0x19c00513, 0x00112e23, 0x00812c23, 0x00912a23, 0x01212823, 0x01312623, 0x01412423, 0x01512223, 0xf09ff0ef, 0xee1ff0ef, 0x10001937, 0x23c349b7, 0x00050413, 0x00058493, 0x00290913, 0x5ff98993, 0x00094783, 0x00078c63, 0xebdff0ef, 0x00050413, 0x00058493, 0xef1ff0ef, 0xfe9ff06f, 0xea9ff0ef, 0x408507b3, 0x00f53533, 0x409585b3, 0x00a59463, 0xfef9f2e3, 0x1ac00513, 0xeb1ff0ef, 0x1c800513, 0xea9ff0ef, 0x00100073, 0xfcdff06f, 0x00006370, 0x4f61654d, 0x65532053, 0x72657672, 0x0000000a, 0x0a0a0a0a, 0x0a0a0a0a, 0x0a0a0a0a, 0x0a0a0a0a, 0x0a0a0a0a, 0x0a0a0a0a, 0x00000a0a, 0x2065204d, 0x204f2061, 0x65532053, 0x72657672, 0x65204d0a, 0x4f206120, 0x53205320, 0x65767265, 0x204d0a72, 0x20612065, 0x2053204f, 0x76726553, 0x4d0a7265, 0x61206520, 0x53204f20, 0x72655320, 0x0a726576, 0x2065204d, 0x204f2061, 0x65532053, 0x72657672, 0x65204d0a, 0x4f206120, 0x53205320, 0x65767265, 0x00000a72
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

if event.type == "digiline" and type(event.msg) == "string" then
	if event.channel == "kb" then
		mem.rx = mem.rx .. event.msg .. "\n"
	else
		mem.dl_rx = mem.dl_rx .. event.msg .. "\n"
	end
	return
end

if event.type == "on" and (event.pin == "B" or (type(event.pin) == "table" and event.pin.name == "B")) then
	if mem.halted then
		mem.dl_chan = ""
		mem.dl_tx = ""
		mem.dl_rx = ""
		mem.pc = 0
		mem.r[2] = 0x7FF0
		mem.tx = ""
		mem.rx = ""
		mem.halted = false
		print("[CPU awake]")
		interrupt(0.05)
	else 
		mem.dl_chan = ""
		mem.dl_tx = ""
		mem.dl_rx = ""
		mem.pc = 0
		mem.r[2] = 0x7FF0
		mem.tx = ""
		mem.rx = ""
		mem.halted = false
		print("[CPU reset]")
	end
	return
end

if event.type == "interrupt" and not mem.halted then
mem.mtime = (mem.mtime or 0) + 500000

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
