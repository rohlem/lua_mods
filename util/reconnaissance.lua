--pretty-prints the contents of a table and its elements recursively
--automatically pretty-prints (require "lua_version") and _G, by default

--"imports" [[
  local _LOADED = _LOADED
  
  local assert = assert
  
  local lua_version = require "lua_version"

  local package_loaded = package.loaded

  local pairs = pairs

  local print = print
  
  local string = string
  local string_rep = string.rep
  local string_format = string.format

  local type = type
--]] "imports"

local rec

local function look_for(k, v, t, l, msg, indentation_string)
  for i = 1, l do
    local j = i*2
    if v == t[j-1] then
      print(indentation_string, "<", msg, k, ":", t[j], ">")
      return true
    end
  end
end

local function table_rec(k, v, stack, stack_size, set, set_size, indentation_string)
  if look_for(k, v, stack, stack_size, "recursive", indentation_string) or
     look_for(k, v, set, set_size, "duplicate", indentation_string) then
       return
  end
  local stack_length = stack_size*2
  stack[stack_length+1], stack[stack_length+2] = v, k
  print(indentation_string, "table", k, "{")
  rec(v, stack, stack_size+1, set, set_size, indentation_string)
  --stack[stack_length+1], stack[stack_length+2] = nil
  print(indentation_string, "}")
end

--[[local]] function rec(t, stack, stack_size, set, set_size, indentation_string)
  if stack_size and stack_size > 12 then
    print("ABORT -- stack_size > 12")
    return
  end
  indentation_string = indentation_string and (indentation_string .. " ") or " "
  for k, v in pairs(t) do
    local type_string = type(v)
    if type_string == 'table' then
      table_rec(k, v, stack, stack_size, set, set_size, indentation_string)
    elseif type_string == 'string' then
      print(indentation_string, "string", k, ":", string_format("%q", v))
    else
      print(indentation_string, type(v), k, ":", v)
    end
  end
end

local function start_rec(t, name, set, set_size, stack, stack_size)
  stack, stack_size, set, set_size = stack or {}, stack_size or 0, set or {}, set_size or 0
  print("===", name, "===")
  table_rec(name, t, stack, stack_size, set, set_size, string_rep(" ", stack_size+1))
end

start_rec(lua_version, "lua_version", {_LOADED or package_loaded, _LOADED and "_LOADED" or package_loaded and "package.loaded"}, 1)
start_rec(_G, "_G", {lua_version, "lua_version"}, 1)

return start_rec