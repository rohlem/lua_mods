--"imports" [[
  local require = require

  local gb = require "GB.base"

  local system_memory = require "system.memory"
--]] "imports"

--integration [[
  local gb_memory = {lower_bound = 0x0000, upper_bound = 0xFFFF}
  gb.memory = gb_memory
--]] integration

--setup [[
  setmetatable(gb_memory, {__index = memory})

  local memory_region = system_memory.memory_region
  gb_memory.rom_bank_0                = memory_region:new({lower_bound = 0x0000, upper_bound = 0x3FFF})
  gb_memory.switchable_rom_bank       = memory_region:new({lower_bound = 0x4000, upper_bound = 0x7FFF})
  gb_memory.video_ram                 = memory_region:new({lower_bound = 0x8000, upper_bound = 0x9FFF})
  gb_memory.switchable_ram_bank       = memory_region:new({lower_bound = 0xA000, upper_bound = 0xBFFF})
  gb_memory.internal_ram              = memory_region:new({lower_bound = 0xC000, upper_bound = 0xDFFF})
  gb_memory.internal_ram_echo         = memory_region:new({lower_bound = 0xE000, upper_bound = 0xFDFF})
  gb_memory.oam                       = memory_region:new({lower_bound = 0xFE00, upper_bound = 0xFE9F})
  gb_memory.empty_1                   = memory_region:new({lower_bound = 0xFEA0, upper_bound = 0xFE99})
  gb_memory.io_ports                  = memory_region:new({lower_bound = 0xFF00, upper_bound = 0xFF4B})
  gb_memory.empty_2                   = memory_region:new({lower_bound = 0xFF4C, upper_bound = 0xFF7F})
  gb_memory.high_internal_ram         = memory_region:new({lower_bound = 0xFF80, upper_bound = 0xFFFE})
  gb_memory.interrupt_enable_register = memory_region:new({lower_bound = 0xFFFF, upper_bound = 0xFFFF})
  
  gb_memory.reserved = {
    restart_00_address                           = 0x0000,
    restart_08_address                           = 0x0008,
    restart_10_address                           = 0x0010,
    restart_18_address                           = 0x0018,
    restart_20_address                           = 0x0020,
    restart_28_address                           = 0x0028,
    restart_30_address                           = 0x0030,
    restart_38_address                           = 0x0038,
    vblank_interrupt_address                     = 0x0040,
    lcdc_interrupt_address                       = 0x0048,
    timer_overflow_interrupt_address             = 0x0050,
    serial_transfer_completion_interrupt_address = 0x0058,
    high_to_low_input_interrupt_address          = 0x0060,
    begin_code_execution_point                   = 0x0100, --0x0103
    nintendo_logo                                = 0x0104, --0x0133
    game_title                                   = 0x0134, --0x0142
    gbc_switch                                   = 0x0143,
    high_new_license_code_ascii_hex_digit        = 0x0144,
    low_new_license_code_ascii_hex_digit         = 0x0145,
    sgb_switch                                   = 0x0146,
    cartridge_type                               = 0x0147,
    rom_size                                     = 0x0148,
    ram_size                                     = 0x0149,
    region_code                                  = 0x014A,
    old_license_code                             = 0x014B,
    mask_rom_version_number                      = 0x014C,
    complement_check                             = 0x014D,
    checksum                                     = 0x014E  --0x014F
  }
--]] setup

return gb_memory