--"imports" [[
  local require = require

  local class = require "class.lua"

  local memory = memory
  local memory_readbyte = memory.readbyte
  local memory_writebyte = memory.writebyte
--]] "imports"

--BizHawk safety check [[
  local temp = memory.usememorydomain
  if temp then
    --BizHawk being used - reset memory domain, just to be safe
    temp("System Bus")
    temp = nil
  end
--]] BizHawk safety check

--class definition [[
  local memory_region = class:new({lower_bound = 0})
  function memory_region:readbyte(addr)
    return memory_readbyte(addr+self.lower_bound)
  end
  function memory_region:writebyte(addr, value)
    return memory_writebyte(addr+self.lower_bound, value)
  end
--]] class definition

--integration [[
  local system_memory = {memory_region = memory_region}
  require "system.base".memory = system_memory
--]] integration

return system_memory

--[[future plan: wrap contents of _G.memory via manual __index-function, adding self.lower_bound to address arguments
  not really necessary though...]]