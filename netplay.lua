--configuration [[
  --target [[
    local ip_addr = "*" --IP-address - host may specify "*"
    local port = 1337 --port used
    local role = 'host' --host xor client
  --]] target
  
  --host [[
    local max_connections = 1 --number of concurrent clients - irrelevant for client
  --]] host
--]] configuration

--"imports" [[
  local require = require
  
  local create_session = require "lpp".prepquire "networking"
  
  local print = print
  
  local pairs = pairs
  
  local string_gmatch = require "lua_version".string_gmatch
  
  local table_concat = table.concat
  
  local tonumber = tonumber
  
  local type = type
--]] "imports"

local session = create_session(role, max_connections, ip_addr, port)

local stylus = stylus

local function install_sending_generic_inputs(category, package_type)
  local category_get = category.get
  session:install_provider(package_type, function()
      local inputs = category_get(not stylus and 1)
      local data = {}
      local next_data_index = 1
      for k, v in pairs(inputs) do
        data[next_data_index] = k
        data[next_data_index+1] = "="
        data[next_data_index+2] = type(v) == 'boolean' and (v and 't' or 'f') or v
        data[next_data_index+3] = "|"
        next_data_index = next_data_index + 4
      end
      data[next_data_index-1] = nil
      data = table_concat(data)
    --  print("DATA:", data)
      return data
    end)
end

local function install_handling_generic_inputs(category, package_type)
  local category_set = category.set
  session:install_frame_handler(package_type, function(data, frame_number)
      if not data then
        return true
      end
    --  print("DATA:", data)
      local buttons = {}
      for k, v in string_gmatch(data, "(%w+)=(%w+)") do
        buttons[k] = v == 't' and true or tonumber(v) or false
      end
      if not stylus then
        category_set(1, buttons)
      else
        category_set(buttons)
      end
    end, nil, 1)
end

local install_action = role == 'client' and install_handling_generic_inputs or role == 'host' and install_sending_generic_inputs or function() print("role not recognized") end

install_action(joypad, "button_inputs")
if stylus then
  install_action(stylus, "touch_inputs")
end
if role == 'host' then
  session:accept(1)
end

print("Ready")