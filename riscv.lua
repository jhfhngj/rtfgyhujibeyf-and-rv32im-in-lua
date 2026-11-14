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
        0x00008137, 0xff010113, 0x688000ef, 0x00100073, 0x0200c7b7, 0x0200c737, 0xffc78793, 0xff870713, 0x0007a683, 0x00072503,0x0007a583, 0xfed59ae3, 0x00008067, 0x10000737, 0x00054783, 0x00079463, 0x00008067, 0x00150513, 0x00f70023, 0xfedff06f, 0x00054783, 0x0005c703, 0x00078663, 0x00070463, 0x00e78863, 0x40e78533, 0x00153513, 0x00008067, 0x00150513, 0x00158593, 0xfd9ff06f, 0xff010113, 0x00000793, 0x00410613, 0x00a00693, 0x00051c63, 0x00410713, 0x100006b7, 0x02079463, 0x01010113, 0x00008067, 0x02d57733,0x00f605b3, 0x00178793, 0x03070713, 0x02d55533, 0x00e58023, 0xfd1ff06f, 0xfff78793, 0x00f70633, 0x00064603, 0x00c68023, 0xfc9ff06f, 0x00051a63, 0x100007b7, 0x03000713, 0x00e78023, 0x00008067, 0xf95ff06f, 0xfc010113, 0x02812c23, 0x00058413, 0xfe040413, 0x00803433, 0x40800433, 0x02912a23, 0x03212823, 0x03312623, 0x03412423, 0x03512223, 0x03612023, 0x01712e23, 0x01812c23, 0x01912a23,0x01a12823, 0x02112e23, 0x01b12623, 0x00050913, 0x06047413, 0xed5ff0ef, 0x23c34ab7, 0x00050993, 0x00058a13, 0x01f40413, 0x00000493, 0x10000b37, 0x00a00b93, 0x00d00c13, 0x00800c93, 0x07f00d13, 0x5ffa8a93, 0x000b4783, 0x0ff7fd93, 0x02079863, 0xe99ff0ef, 0x413507b3, 0x00f53533, 0x414585b3, 0x00a59463, 0xfefaf0e3, 0x00001537, 0x92850513, 0xe9dff0ef, 0x00100073, 0xfcdff06f, 0xe6dff0ef,0x00050993, 0x00058a13, 0x037d8863, 0x038d8663, 0x019d8463, 0x01ad9863, 0x009027b3, 0x40f484b3, 0xfa5ff06f, 0xfa84d0e3, 0x009907b3, 0x01b78023, 0x00148493, 0xf91ff06f, 0x00990933, 0x00090023, 0x03c12083, 0x03812403, 0x03412483, 0x03012903, 0x02c12983, 0x02812a03, 0x02412a83, 0x02012b03, 0x01c12b83, 0x01812c03, 0x01412c83, 0x01012d03, 0x00c12d83, 0x04010113, 0x00008067, 0x00060e63,0x01f00793, 0x00c7dc63, 0xfe060613, 0x00c515b3, 0x00000713, 0x00070513, 0x00008067, 0x02000793, 0x40c787b3, 0x00c51733, 0x00c595b3, 0x00f55533, 0x00b565b3, 0xfe1ff06f, 0x00060e63, 0x01f00793, 0x00c7dc63, 0xfe060613, 0x00c5d533, 0x00000713, 0x00070593, 0x00008067, 0x02000793, 0x40c787b3, 0x00c5d733, 0x00c55533, 0x00f595b3, 0x00a5e533, 0xfe1ff06f, 0xfd010113, 0x02112623, 0x02812423,0x02912223, 0x03212023, 0x01312e23, 0x01412c23, 0x01512a23, 0x01612823, 0x01712623, 0x01812423, 0x01912223, 0x01a12023, 0x00d667b3, 0x0c078c63, 0x00050b13, 0x00058b93, 0x00060c93, 0x00068913, 0x03f00a93, 0x00000413, 0x00000493, 0x00000a13, 0x00000d13, 0xfff00c13, 0x01f45793, 0x00149993, 0x000a8613, 0x000b0513, 0x000b8593, 0x0137e9b3, 0xf49ff0ef, 0x00141413, 0x00157513, 0x00856433,0x00098493, 0x0329ec63, 0x01391463, 0x03946863, 0x419407b3, 0x000a8613, 0x00100513, 0x00000593, 0x00f434b3, 0x412989b3, 0x00078413, 0xed1ff0ef, 0x409984b3, 0x00aa6a33, 0x00bd6d33, 0xfffa8a93, 0xf98a9ce3, 0x02c12083, 0x02812403, 0x02412483, 0x02012903, 0x01c12983, 0x01412a83, 0x01012b03, 0x00c12b83, 0x00812c03, 0x00412c83, 0x000a0513, 0x000d0593, 0x01812a03, 0x00012d03, 0x03010113,0x00008067, 0xfff00a13, 0x000a0d13, 0xfb9ff06f, 0xfd010113, 0x02112623, 0x02812423, 0x02912223, 0x03212023, 0x01312e23, 0x01412c23, 0x01512a23, 0x00010493, 0x112237b7, 0x34478793, 0x00f12423, 0x00814983, 0xc25ff0ef, 0x03c00793, 0x0ff9f993, 0x00050413, 0x00058a13, 0x00f12623, 0x00c12903, 0xfff90793, 0x00f12623, 0x18091063, 0xbfdff0ef, 0x40850633, 0x414586b3, 0x00c53533, 0x40a686b3,0x00d667b3, 0x00000a13, 0x00078c63, 0x8f0d2537, 0x80050513, 0x00000593, 0xe5dff0ef, 0x00050a13, 0x000017b7, 0x00008437, 0xbaa78793, 0xff040413, 0x00878433, 0x0097f463, 0x40f48933, 0xbadff0ef, 0x00989637, 0x68060613, 0x00000693, 0xe29ff0ef, 0x00050a93, 0x00001537, 0x95c50513, 0xbb1ff0ef, 0x00001537, 0x98050513, 0xba5ff0ef, 0x02000513, 0xbe5ff0ef, 0x00001537, 0x98c50513, 0xb91ff0ef,0x04400793, 0x0ef99663, 0x000017b7, 0x94078513, 0xb7dff0ef, 0x00001537, 0x99450513, 0xb71ff0ef, 0x00001537, 0x99850513, 0xb65ff0ef, 0x000a0513, 0xbfdff0ef, 0x00001537, 0x9a450513, 0xb51ff0ef, 0x00001537, 0x9b450513, 0xb45ff0ef, 0x00048513, 0xbddff0ef, 0x00001537, 0x9c050513, 0xb31ff0ef, 0x00001537, 0x9c450513, 0xb25ff0ef, 0x40940533, 0xbbdff0ef, 0x00001537, 0x9d050513, 0xb11ff0ef,0x00008537, 0xb51ff0ef, 0x00001537, 0x9d450513, 0xafdff0ef, 0x00090513, 0xb95ff0ef, 0x00001537, 0x9e050513, 0xae9ff0ef, 0x00001537, 0x9ec50513, 0xaddff0ef, 0x000a8513, 0xb75ff0ef, 0x02812403, 0x02c12083, 0x02412483, 0x02012903, 0x01c12983, 0x01812a03, 0x01412a83, 0x00001537, 0x9f850513, 0x03010113, 0xaa9ff06f, 0x00000013, 0xe71ff06f, 0x000017b7, 0x95078513, 0xf19ff06f, 0x00001537,0xfd010113, 0x9fc50513, 0x02112623, 0x02812423, 0x01312e23, 0x02912223, 0x03212023, 0xa71ff0ef, 0xa49ff0ef, 0x06400793, 0x00f12423, 0x00050413, 0x00058993, 0x00012623, 0x00200793, 0x00812703, 0x0ae7e063, 0xa25ff0ef, 0x00050493, 0x00001537, 0xa2450513, 0x00058913, 0xa35ff0ef, 0x00c12503, 0xacdff0ef, 0x00001537, 0xa2c50513, 0xa21ff0ef, 0x40848533, 0x00a4b4b3, 0x413905b3, 0x00002637,0x71060613, 0x00000693, 0x409585b3, 0xc69ff0ef, 0xa9dff0ef, 0x02812403, 0x02c12083, 0x02412483, 0x02012903, 0x01c12983, 0x00001537, 0xa3850513, 0x03010113, 0x9d9ff06f, 0x02e7f6b3, 0x00068e63, 0x00170713, 0x02e706b3, 0xfed7f8e3, 0x00c12703, 0x00170713, 0x00e12623, 0x00178793, 0xf61ff06f, 0x00200713, 0xfe1ff06f, 0x00001537, 0xf3010113, 0xa4050513, 0x0c112623, 0x0c812423, 0x0c912223,0x0d212023, 0x0b312e23, 0x0b412c23, 0x0b512a23, 0x97dff0ef, 0x00001537, 0xa4850513, 0x971ff0ef, 0x000014b7, 0x00001437, 0x00001937, 0x000019b7, 0x00001a37, 0xa5c48513, 0x955ff0ef, 0xa3c40513, 0x94dff0ef, 0x08000593, 0x03010513, 0x9f9ff0ef, 0x03010513, 0x939ff0ef, 0xa3c40513, 0x931ff0ef, 0xa6490593, 0x03010513, 0x941ff0ef, 0x00050a63, 0x00001537, 0xa6c50513, 0x915ff0ef, 0xfb9ff06f,0xb1498593, 0x03010513, 0x921ff0ef, 0x00050663, 0xc81ff0ef, 0xfa1ff06f, 0xb1ca0593, 0x03010513, 0x909ff0ef, 0x00050663, 0xe55ff0ef, 0xf89ff06f, 0x000015b7, 0xb2458593, 0x03010513, 0x8edff0ef, 0x04050263, 0x8a5ff0ef, 0x00050a93, 0x00001537, 0x9ec50513, 0x00b12623, 0x8b5ff0ef, 0x00c12583, 0x00989637, 0x68060613, 0x00000693, 0x000a8513, 0xb05ff0ef, 0x939ff0ef, 0x00001537, 0x9f850513,0xf79ff06f, 0x000015b7, 0xb2c58593, 0x03010513, 0x899ff0ef, 0x00050c63, 0x00001537, 0xb3450513, 0x86dff0ef, 0x00100073, 0xf0dff06f, 0x000015b7, 0xb4858593, 0x03010513, 0x871ff0ef, 0x02050663, 0x00001537, 0xb5050513, 0x845ff0ef, 0x08000593, 0x03010513, 0x8f1ff0ef, 0x03010513, 0x831ff0ef, 0xa3c40513, 0xf15ff06f, 0x000015b7, 0xb5858593, 0x03010513, 0x835ff0ef, 0x08050463, 0x00001537,0xb6050513, 0x809ff0ef, 0x02000593, 0x01010513, 0x8b5ff0ef, 0x00001537, 0xb6c50513, 0xff0ff0ef, 0x08000593, 0x03010513, 0x89dff0ef, 0x01010793, 0x100016b7, 0x0007c703, 0x02071863, 0x10001737, 0x03010793, 0x00170713, 0x0007c683, 0x02069463, 0x100017b7, 0x00100713, 0x00001537, 0x00e78123, 0xb7850513, 0xe95ff06f, 0x00178793, 0x00e68023, 0xfc5ff06f, 0x00178793, 0x00d70023, 0xfcdff06f,0x000015b7, 0xb8058593, 0x03010513, 0xf9cff0ef, 0x04050263, 0x100017b7, 0x0027c703, 0x00278793, 0x02070463, 0x10001737, 0x00170713, 0x10000637, 0x0007c683, 0xe00680e3, 0x00074683, 0x0ff6f693, 0x00d60023, 0xfedff06f, 0x00001537, 0xb8850513, 0xe29ff06f, 0x03014783, 0xdc078ee3, 0x00001537, 0xb9850513, 0xf28ff0ef, 0x03010513, 0xf20ff0ef, 0x100007b7, 0x00a00713, 0x00e78023, 0xdb9ff06f,0x4f61654d, 0x73692053, 0x776f6e20, 0x656c7320, 0x6e697065, 0x000a2e67, 0x7474694c, 0x452d656c, 0x6169646e, 0x0000006e, 0x2d676942, 0x69646e45, 0x00006e61, 0x203d3d3d, 0x4f61654d, 0x694c2053, 0x48206576, 0x77647261, 0x20657261, 0x626f7250, 0x3d3d2065, 0x00000a3d, 0x68637241, 0x2020203a, 0x00005652, 0x28204d49, 0x00000000, 0x00000a29, 0x65657053, 0x20203a64, 0x0000007e, 0x207a4820,0x61656d28, 0x65727573, 0x000a2964, 0x203a5053, 0x20202020, 0x00000000, 0x000a4220, 0x3a4d4152, 0x20202020, 0x00000000, 0x00202f20, 0x75204220, 0x20646573, 0x00000028, 0x66204220, 0x29656572, 0x0000000a, 0x69747055, 0x203a656d, 0x00000000, 0x000a7320, 0x636e6542, 0x72616d68, 0x676e696b, 0x33565220, 0x204d4932, 0x69727028, 0x2073656d, 0x3031203c, 0x2e2e2930, 0x00000a2e, 0x6e756f46,0x00002064, 0x69727020, 0x2073656d, 0x00206e69, 0x21736d20, 0x0000000a, 0x4f61654d, 0x00000a53, 0x74696e49, 0x696c6169, 0x676e697a, 0x706e6920, 0x000a7475, 0x4f61654d, 0x003e2053, 0x706c6568, 0x00000000, 0x6d6d6f43, 0x73646e61, 0x65680a3a, 0x203a706c, 0x6e65704f, 0x68742073, 0x730a7369, 0x6e697379, 0x203a6f66, 0x6576694c, 0x72616820, 0x72617764, 0x74732065, 0x0a737461, 0x636e6562,0x52203a68, 0x62206e75, 0x68636e65, 0x6b72616d, 0x6d69740a, 0x52203a65, 0x696e6e75, 0x7420676e, 0x0a656d69, 0x74697865, 0x6148203a, 0x2073746c, 0x0a555043, 0x6f686365, 0x6345203a, 0x640a6f68, 0x6e65736c, 0x53203a64, 0x20646e65, 0x69676964, 0x656e696c, 0x726c640a, 0x3a766365, 0x61655220, 0x69642064, 0x696c6967, 0x000a656e, 0x69737973, 0x006f666e, 0x636e6562, 0x00000068, 0x656d6974,0x00000000, 0x74697865, 0x00000000, 0x746c6148, 0x20676e69, 0x4f61654d, 0x2e2e2e53, 0x0000000a, 0x6f686365, 0x00000000, 0x74786554, 0x00000a3a, 0x65736c64, 0x0000646e, 0x6e616843, 0x3a6c656e, 0x0000000a, 0x7373654d, 0x3a656761, 0x0000000a, 0x746e6553, 0x00000a21, 0x65726c64, 0x00007663, 0x6d206f4e, 0x61737365, 0x2e736567, 0x0000000a, 0x6e6b6e55, 0x206e776f, 0x6d6d6f63, 0x3a646e61,0x00000020
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
