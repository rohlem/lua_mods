require "NES.base"
require "system.memory"

local nes_memory = {lower_bound = 0x0000, upper_bound = 0xFFFF}
nes.memory = nes_memory
setmetatable(nes_memory, {__index = memory})

local memory_region = system.memory.memory_region
nes_memory.ram =                    memory_region:new({lower_bound = 0x0000, upper_bound = 0x07FF})
nes_memory.zero_page =              memory_region:new({lower_bound = 0x0000, upper_bound = 0x00FF})
nes_memory.stack =                  memory_region:new({lower_bound = 0x0100, upper_bound = 0x01FF})
nes_memory.high_ram =               memory_region:new({lower_bound = 0x0200, upper_bound = 0x07FF})
nes_memory.low_mirror_a =           memory_region:new({lower_bound = 0x0800, upper_bound = 0x0FFF})
nes_memory.low_mirror_b =           memory_region:new({lower_bound = 0x1000, upper_bound = 0x17FF})
nes_memory.low_mirror_c =           memory_region:new({lower_bound = 0x1800, upper_bound = 0x1FFF})
nes_memory.io_regs_a =              memory_region:new({lower_bound = 0x2000, upper_bound = 0x2007})
nes_memory.io_regs_a_mirror =       memory_region:new({lower_bound = 0x2008, upper_bound = 0x3FFF})
nes_memory.io_regs_b =              memory_region:new({lower_bound = 0x4000, upper_bound = 0x401F})
nes_memory.expansion_rom =          memory_region:new({lower_bound = 0x4020, upper_bound = 0x5FFF})
nes_memory.sram =                   memory_region:new({lower_bound = 0x6000, upper_bound = 0x7FFF})
nes_memory.prg_rom =                memory_region:new({lower_bound = 0x8000, upper_bound = 0xFFFF})
nes_memory.nmi_handler =            memory_region:new({lower_bound = 0xFFFA, upper_bound = 0xFFFB})
nes_memory.power_on_reset_handler = memory_region:new({lower_bound = 0xFFFC, upper_bound = 0xFFFD})
nes_memory.brk_handler =            memory_region:new({lower_bound = 0xFFFE, upper_bound = 0xFFFF})

--has yet to prove useful
function nes_memory.categorize_address(addr)
	local candidate = nild
	local cache = nil
	for k,v in pairs(nes_memory) do
		if addr >= v[1] and addr <= v[2] then
			if candidate == nil or cache[1] < v[1] or cache[2] > v[2] then
				cache = v
				candidate = k
			end
		end
	end
	return candidate
end

--has yet to prove useful
function nes_memory.effective_address(addr)
	if addr >= 0x0000 and addr <= 0x1FFF then
		return bit.band(addr, 0x7FFF)
	elseif addr >= 0x2000 and addr <= 0x3FFF then
		return bit.bor(0x2000, bit.band(addr, 0x0007))
	end
	return addr
end
