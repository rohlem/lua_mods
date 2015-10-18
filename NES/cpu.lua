require "base"
require "memory"

local nes_cpu = {}
nes.cpu = nes_cpu

--register registers
local nes_cpu_register_count = 0
local nes_cpu_registers = {}
nes_cpu.registers = nes_cpu_registers
local nes_cpu_reg_cache = emu.getregisters()
local do_remove = false
local emu_getregister = emu.getregister
local function reg_reg(reg, reg_name)
	local nes_cpu_register = {}
	nes_cpu_registers[reg] = nes_cpu_register
	nes_cpu_register.name = reg_name
	do_remove = true
end
local expected_regs = {"A", "PC", "X", "Y"}
for outer_k, outer_v in pairs(nes_cpu_reg_cache) do
	for inner_k, inner_v in pairs(expected_regs) do --just values, actually
		if outer_k == inner_v then
			reg_reg(inner_v, inner_v)
		end
	end
	if (not do_remove) and bizstring.startswith(outer_k, "S") then
		reg_reg("SP", outer_k)
	end
	if do_remove then
		nes_cpu_reg_cache[outer_k] = nil
		nes_cpu_register_count = nes_cpu_register_count - 1
		do_remove = false
	else
		nes_cpu_register_count = nes_cpu_register_count + 1
	end
end

local nes_cpu_flags

--register flags
if nes_cpu_register_count > 1 then
	nes_cpu.flag_mode = 'separate'
	nes_cpu_flags = {}
	nes_cpu.flags = nes_cpu_flags
	for k,v in pairs(nes_cpu_reg_cache) do
		 if bizstring.startswith(k, "Flag ") then
			nes_cpu_flags[bizstring.substring(k, 5, string.len(k)-5)] = k
		end
	end
else
	nes_cpu.flag_mode = 'unified'
	for k,v in pairs(nes_cpu_reg_cache) do
		nes_cpu.flags = k
	end
end

local nes_cpu_flag_names = {
	'C', --carry
	'Z', --zero
	'I', --interrupt disable
	'D', --decimal
	'B', --break
	'T', --"unused" (always 1)
	'V', --overflow
	'N' --negative
}
nes_cpu.flag_names = nes_cpu_flag_names

--flag handling
local nes_cpu_flag = {}
nes_cpu.flag = nes_cpu_flag

local function nes_cpu_flag_handle(flag_name, handle)
	for k,v in pairs(nes_cpu_flag_names) do
		if v == flag_name then
			if nes_cpu.flag_mode == 'unified' then
				return handle(nes_cpu.flags, k-1)
			elseif nes_cpu.flag_mode == 'separate' then
				return handle(v)
			end
		end
	end
end

--get flag
local function nes_cpu_flag_get(flag_name, shift_count)
	if shift_count == nil then --separate
		return emu.getregister(nes_cpu_flags[flag_name])
	else --unified
		return bit.band(bit.rshift(emu.getregister(flag_name), shift_count), 1)
	end
end

function nes_cpu_flag.get(name)
	return nes_cpu_flag_handle(name, nes_cpu_flag_get)
end

--set flag
local nes_cpu_flag_set_closure_helper

local function nes_cpu_flag_set(flag_name, shift_count)
	if shift_count == nil then --separate
		emu.setregister(nes_cpu_flags[flag_name], nes_cpu_flag_set_closure_helper)
	else --unified
		local operation
			if nes_cpu_flag_set_closure_helper == 0 then
				operation = bit.clear
			else
				operation = bit.set
			end
		emu.setregister(flag_name, operation(emu.getregister(flag_name), shift_count))
	end
end

function nes_cpu_flag.set(name, value)
	nes_cpu_flag_set_closure_helper = value
	console.log("Blargh\n")
	nes_cpu_flag_handle(name, nes_cpu_flag_set)
end

--looping increment
local function inc_byte(value)
	if value == 0xFF then
		return 0
	end
	return value+1
end

--looping decrement
local function dec_byte(value)
	if value == 0 then
		return 0xFF
	end
	return value-1
end

--direct stack operations
local nes_cpu_stack = {}
nes_cpu.stack = nes_cpu_stack

--stack peek
function nes_cpu_stack.peek()
	return nes.memory.stack.read(emu.getregister(nes_cpu_registers.SP.name))
end

--stack pull
local function nes_cpu_stack_pull()
	local sp_name = nes_cpu_registers.SP
	local sp_value = emu.getregister(sp_name)
	local return_value = nes.memory.stack.read(sp_value)
	sp_value = inc_byte(sp_value)
	emu.setregister(sp_name, sp_value)
	return return_value
end
nes_cpu_stack.pull = nes_cpu_stack_pull

--stack push
local function nes_cpu_stack_push(value)
	local sp_name = nes_cpu_registers.SP
	local sp_value = emu.getregister(sp_name)
	nes.memory.stack.write(sp_value, value)
	sp_value = dec_byte(sp_value)
	emu.setregister(sp_name, sp_value)
end
nes_cpu_stack.push = nes_cpu_stack_push

--nes opcodes
local nes_cpu_ops = {}
nes_cpu.ops = nes_cpu_ops
--simulated execution
function nes_cpu_ops.JMP(addr)
	emu.setregister(nes_cpu_registers.PC, addr)
end
function nes_cpu_ops.JSR(addr)
	local return_address = nes_cpu_stack.emu.getregister(nes_cpu_registers.PC) + 2
	nes_cpu_stack_push(bit.rshift(return_address, 8), 0xFF)
	nes_cpu_stack_push(bit.band(return_address, 0xFF))
	emu.setregister(nes_cpu_registers.PC, addr)
end
