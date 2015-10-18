require "system.base"
require "class.lua"

temp = memory.usememorydomain
if temp ~= nil then
  temp("System Bus")
  temp = nil
end

local memory_region = class:new({lower_bound = 0})
function memory_region:readbyte(addr)
	return memory.readbyte(addr+self.lower_bound)
end
function memory_region:writebyte(addr, value)
	return memory.writebyte(addr+self.lower_bound, value)
end

system.memory = {memory_region = memory_region}

--[[future plan: wrap contents of _G.memory via manual __index-function, adding self.lower_bound to address arguments
  not really necessary though...]]
