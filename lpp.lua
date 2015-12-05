--EXTENSION replace level long strings in 5.0 (disallowing long strings in layer-2 code, because layer-1 is inescapable)
--EXTENSION numeric literal syntax

--note: This file is loaded in two "stages", first as plain Lua 5.1-5.3 and then parsed by itself. That's why it might look a bit odd in places.

--"imports" [[
  local error = error
  
  local io = io
  local io_open = io.open
  
  local lua_version = require "lua_version"
  
  local pairs = pairs
  
--  local print = print
  
  local string = string
  local string_find = string.find
  local string_format = string.format
  local string_len = string.len
  local string_sub = string.sub
  
  local table_concat = table.concat
--]] "imports"

--parses files, uses loadstring to interpret them and returns the resulting function
--this is the "compatibility" version, to be read by the standard Lua interpreter
local mode = {nil, nil}
local long_string_end_indicator = {nil, nil}
local find_masks = {}
do
  local mode_masks =
    {['default'] = "%-'\"%[",
     ['long'] = "%]",
     ['quote string'] = "\\\"",
     ['apostrophe string'] = "\\'",
     ['line comment'] = "\n"}
  local layer_masks =
    {['line 1'] = "\n",
     ['inline 1'] = "%)",
     ['2'] = "$\n%]"} --] to hide layer-2 closing double square brackets from layer-1 code
  local find_mask = {".-([", nil,  nil, "\n])"} --\n to keep track of line_nr
  for mk, mv in pairs(mode_masks) do
    find_mask[2] = mv
    find_masks[mk] = {}
    for lk, lv in pairs(layer_masks) do
      find_mask[3] = lv
      find_masks[mk][lk] = table_concat(find_mask)
    end
  end
end
local write = {nil, nil}
local warn_table = {nil, " on line nr ", nil, " on layer ", nil, " with modes ", nil, ", ", nil, nil, nil}
local long_string_end_table = {"^", nil, "]"}

--[=[
#--[=[
--]=]

local function prep_compat(contents)
  local chunk, next_chunk_index =
    {"local _pr_,_npi_,_={},1"}, 2 --_prep_result_, _next_pr_index_, temporary for parsing omissible inline layer-1 expressions
  local begin_index = string_sub(contents, 1, 1) == "#" and string_find(contents, "\n", 2, true) or 1
  local last_index = begin_index
  
  local layer = 2
  local layer_mode = '2'
  mode[1] = 'default'
  mode[2] = mode[1]
  local l1_inline_type, l1_inline_end
  
  local parsed_long_string_flag = false
  local function parse_long_string(index)
    local _, _2, level_indicator = string_find(contents, "^(=*)%[", index)
    if _ then
      long_string_end_indicator[layer] = level_indicator
      parsed_long_string_flag = _2 - _
      return true
    else
      parsed_long_string_flag = nil
    end
  end
  
  write[1] = function(next_chunk_index, start_index, end_index)
      chunk[next_chunk_index] = string_sub(contents, start_index, end_index)
    end
  write[2] = function(next_chunk_index, start_index, end_index)
      chunk[next_chunk_index] = " _pr_[_npi_]="
      chunk[next_chunk_index+1] = string_format("%q", string_sub(contents, start_index, end_index))
    end
  
  local force_write_flag = false
  
  local line_nr = 1
  local function warn(assertion, msg, arg)
    if not assertion then
      warn_table[1] = msg
      warn_table[3] = line_nr
      warn_table[5] = layer_mode
      warn_table[7] = mode[1]
      warn_table[9] = mode[2]
      warn_table[10] = arg and "|"
      warn_table[11] = arg
      error(table_concat(warn_table))
    end
  end
  local last_last_index
  while true do
    if last_last_index == last_index then warn(false, "stopped moving") end
    last_last_index = last_index
    local current_mode = mode[layer]
    local start_index, char_index, char = string_find(contents, find_masks[current_mode][layer_mode], last_index)
  if not start_index then break end
--    print("AT ", start_index, "-", char_index, ": ", char)
    if char == "\\" then
      if current_mode == 'quote string' or current_mode == 'apostrophe string' then
        last_index = char_index + 2 --as long as no special characters may appear (and should be ignored) within escapes, we should be all good
      else
        warn(false, "non-useful backslash encountered")
      end
    else
      local next_index = char_index + 1
      if (current_mode == 'quote string' and char == "\"") or (current_mode == 'apostrophe string' and char == "'") then
--        print("closing string!")
        mode[layer] = 'default'
        last_index = next_index
      else
        local previous_chunk_index, previous_layer = next_chunk_index, layer
        if char == "\n" then
          line_nr = line_nr + 1
          if current_mode == 'line comment' then
            mode[layer] = 'default'
          end
          if string_sub(contents, next_index, next_index) == "#" then --line layer-1 code
            warn(layer_mode ~= 'inline l1', "line l1 starting # encountered within inline l1")
            char_index = char_index + 1 --include \n when writing
            next_index = next_index + 1
            if layer == 1 then
              next_chunk_index = next_chunk_index + 1
              force_write_flag = true --flush to omit "#"
            else
              layer_mode, layer = 'line 1', 1
--              print("switching layer: line 1 | 1 ")
              chunk[next_chunk_index+2] = "_npi_=_npi_+1 "
              next_chunk_index = next_chunk_index + 3
              force_write_flag = true
            end
          elseif layer_mode == 'line 1' then
            warn(layer == 1, "layer_mode = 'line 1', but layer ~= 1")
            char_index = char_index + 1 --include \n when writing
            next_chunk_index = next_chunk_index + 1
            layer_mode, layer = '2', 2
--            print("switching layer: 2")
            force_write_flag = true
          end
          last_index = next_index
        elseif char == "$" then
          warn(layer == 2, "dollar sign encountered within layer-1 code")
          local start_index
          start_index, l1_inline_end = string_find(contents, "^%b()", next_index)
--          print("l1 inline expression from", start_index, "to", l1_inline_end)
          if start_index then --layer-1 code
            local excl_index = start_index+1
            local str_sub = string_sub(contents, excl_index, excl_index)
            l1_inline_type = str_sub == "!" and 'omissible' or str_sub == "?" and 'omissible boolean-aware'
            if l1_inline_type then --some form of omissible
              chunk[next_chunk_index+2] = "_npi_=_npi_+1 _=("
              last_index = start_index + 2
            else
              chunk[next_chunk_index+2] = "_npi_=_npi_+2 _pr_[_npi_-1]="
              last_index = start_index + 1
            end
            next_chunk_index = next_chunk_index + 3
            layer_mode, layer = 'inline 1', 1
--            print("switching layer: inline 1 | 1")
            force_write_flag = true
          else
            warn(current_mode ~= 'default', "dollar sign not followed by parentheses in mode default")
            last_index = next_index
          end
        elseif char == ")" then
--          print("char_index", char_index, "l1_inline_end", l1_inline_end)
          if char_index == l1_inline_end then
            warn(layer == 1, "l1_inline_end reached within layer-2 code")
            start_index = start_index + 1
            if l1_inline_type then --some form of omissible
              start_index = start_index + 1
              chunk[next_chunk_index+1] = l1_inline_type == 'omissible' and ")if _ then _pr_[_npi_]=_ _npi_=_npi_+1 end " or ")if _~=nil then _pr_[_npi_]=_ _npi_=_npi_+1 end "
              next_chunk_index = next_chunk_index + 2
            else --non-omissible
              next_chunk_index = next_chunk_index + 1
            end
            layer_mode, layer = '2', 2
--            print("switching layer: 2")
            force_write_flag = true
          end
          last_index = next_index
        elseif char == "-" then
          warn(current_mode == 'default', "- encountered in non-default mode")
          if string_sub(contents, next_index, next_index) == "-" then
            next_index = next_index + 2
            if not parse_long_string(next_index) then
              mode[layer] = 'line comment'
              last_index = next_index
            end
          else
            last_index = next_index
          end
        elseif char == "[" then
          warn(current_mode == 'default' or current_mode == 'long', "[ encountered in non-default, non-long mode")
          if not parse_long_string(next_index) then
            last_index = next_index
          end
        elseif char == "]" then
          last_index = next_index
          local lsei = long_string_end_indicator[layer]
          long_string_end_table[2] = lsei
          if current_mode == 'long' and string_find(contents, table_concat(long_string_end_table), next_index) then
            mode[layer] = 'default'
            last_index = next_index + string_len(lsei) + 1
          end
          if layer == 2 and mode[1] == 'long' then
            local lsei = long_string_end_indicator[1]
            long_string_end_table[2] = lsei
            if string_find(contents, table_concat(long_string_end_table), next_index) then
--              print("====IN====")
              char_index = next_index + string_len(lsei)
              last_index = char_index
              chunk[next_chunk_index+2] = "_npi_=_npi_+1"
              next_chunk_index = next_chunk_index + 3
              force_write_flag = true
            else
              last_index = next_index
            end
          end
        else
          mode[layer] = (char == "\"" and 'quote string') or (char == "'" and 'apostrophe string') or warn(false, "triggered by non-useful symbol", char)
--          print("opening string!")
          last_index = next_index
        end
        if parsed_long_string_flag then
            mode[layer] = 'long'
            last_index = next_index + 1 + parsed_long_string_flag
            parsed_long_string_flag = false
        end
        if force_write_flag then
--          print("around line ", line_nr, " forced write of ", begin_index, " to ", char_index - 1, " at layer ", previous_layer)
          write[previous_layer](previous_chunk_index, begin_index, char_index - 1)
          begin_index = last_index
          force_write_flag = false
        end
      end
    end
  end
  write[layer](next_chunk_index, begin_index, -1)
  chunk[next_chunk_index+layer] = " return require\"lua_version\".loadstring(table.concat(_pr_))"
  return lua_version.loadstring(table_concat(chunk)), chunk
end

local _, file_name = ...
local lpp_file = file_name and io_open(file_name)
if not lpp_file then
  lpp_file = debug
  if lpp_file then
    lpp_file = lpp_file.getinfo(1).source
    lpp_file = string_sub(lpp_file, 1, 1) == "@" and io_open(string_sub(lpp_file, 2))
  end
  if not lpp_file then
    local string_gsub = string.gsub
    local paths = string_gsub(package.path, "%?", "lpp")
    for path in lua_version.string_gmatch(paths, "([^;]+);?") do -- ";;" is currently ignored
      lpp_file = io_open(path)
      if lpp_file then
        break
      end
    end
  end
end
local result = prep_compat(lpp_file:read("*a"))()()
io.close(lpp_file)
return result

--[===[
--[=[
#--]=]
--]=]

--"imports" [[
  local assert = assert
  
  local io_close = io.close
  
# local lua_version = require "lua_version"
  
  local loadstring = lua_version.loadstring
  
#local package = package
  local package = package
  local package_config = package.config
  local package_loaded = lua_version.package_loaded
  local package_path = lua_version.package_path
  
  local string_gmatch = lua_version.string_gmatch
  local string_gsub = string.gsub
--]] "imports"

#local use_goto = lua_version.goto_support and lua_version.label_support
#local force_write = use_goto and "goto force_write" or "force_write_flag = true"

local function prep(contents)
  local chunk, next_chunk_index =
    {"local _pr_,_npi_,_={},1"}, 2 --_prep_result_, _next_pr_index_, temporary for parsing omissible inline layer-1 expressions
  local begin_index = string_sub(contents, 1, 1) == "#" and string_find(contents, "\n", 2, true) or 1
  local last_index = begin_index
  
  local layer = 2
  local layer_mode = '2'
  mode[1] = 'default'
  mode[2] = mode[1]
  local l1_inline_type, l1_inline_end
  
  local parsed_long_string_flag = false
  local function parse_long_string(index)
    local _, _2, level_indicator = string_find(contents, "^(=*)%[", index)
    if _ then
      long_string_end_indicator[layer] = level_indicator
      parsed_long_string_flag = _2 - _
      return true
    else
      parsed_long_string_flag = nil
    end
  end
  
  write[1] = function(next_chunk_index, start_index, end_index)
      chunk[next_chunk_index] = string_sub(contents, start_index, end_index)
    end
  write[2] = function(next_chunk_index, start_index, end_index)
      chunk[next_chunk_index] = " _pr_[_npi_]="
      chunk[next_chunk_index+1] = string_format("%q", string_sub(contents, start_index, end_index))
    end
  
  local force_write_flag = false
  
  local line_nr = 1
  local function warn(assertion, msg, arg)
    if not assertion then
      warn_table[1] = msg
      warn_table[3] = line_nr
      warn_table[5] = layer_mode
      warn_table[7] = mode[1]
      warn_table[9] = mode[2]
      warn_table[10] = arg and "|"
      warn_table[11] = arg
      error(table_concat(warn_table))
    end
  end
  local last_last_index
  while true do
    if last_last_index == last_index then warn(false, "stopped moving") end
    last_last_index = last_index
    local current_mode = mode[layer]
    local start_index, char_index, char = string_find(contents, find_masks[current_mode][layer_mode], last_index)
  if not start_index then break end
--    print("AT ", start_index, "-", char_index, ": ", char)
    if char == "\\" then
      if current_mode == 'quote string' or current_mode == 'apostrophe string' then
        last_index = char_index + 2 --as long as no special characters may appear (and should be ignored) within escapes, we should be all good
      else
        warn(false, "non-useful backslash encountered")
      end
    else
      local next_index = char_index + 1
      if (current_mode == 'quote string' and char == "\"") or (current_mode == 'apostrophe string' and char == "'") then
--        print("closing string!")
        mode[layer] = 'default'
        last_index = next_index
      else
        local previous_chunk_index, previous_layer = next_chunk_index, layer
        if char == "\n" then
          line_nr = line_nr + 1
          if current_mode == 'line comment' then
            mode[layer] = 'default'
          end
          if string_sub(contents, next_index, next_index) == "#" then --line layer-1 code
            warn(layer_mode ~= 'inline l1', "line l1 starting # encountered within inline l1")
            char_index = char_index + 1 --include \n when writing
            next_index = next_index + 1
            $(!use_goto and "last_index = next_index") --skipped if goto is used
            if layer == 1 then
              next_chunk_index = next_chunk_index + 1
              $(force_write) --flush to omit "#"
            else
              layer_mode, layer = 'line 1', 1
--              print("switching layer: line 1 | 1 ")
              chunk[next_chunk_index+2] = "_npi_=_npi_+1 "
              next_chunk_index = next_chunk_index + 3
              $(force_write)
            end
          elseif layer_mode == 'line 1' then
            warn(layer == 1, "layer_mode = 'line 1', but layer ~= 1")
            $(!use_goto and "last_index = next_index") --skipped if goto is used
            char_index = char_index + 1 --include \n when writing
            next_chunk_index = next_chunk_index + 1
            layer_mode, layer = '2', 2
--            print("switching layer: 2")
            $(force_write)
          end
          last_index = next_index
        elseif char == "$" then
          warn(layer == 2, "dollar sign encountered within layer-1 code")
          local start_index
          start_index, l1_inline_end = string_find(contents, "^%b()", next_index)
--          print("l1 inline expression from", start_index, "to", l1_inline_end)
          if start_index then --layer-1 code
            local excl_index = start_index+1
            local str_sub = string_sub(contents, excl_index, excl_index)
            l1_inline_type = str_sub == "!" and 'omissible' or str_sub == "?" and 'omissible boolean-aware'
            if l1_inline_type then --some form of omissible
              chunk[next_chunk_index+2] = "_npi_=_npi_+1 _=("
              last_index = start_index + 2
            else
              chunk[next_chunk_index+2] = "_npi_=_npi_+2 _pr_[_npi_-1]="
              last_index = start_index + 1
            end
            next_chunk_index = next_chunk_index + 3
            layer_mode, layer = 'inline 1', 1
--            print("switching layer: inline 1 | 1")
            $(force_write)
          else
            warn(current_mode ~= 'default', "dollar sign not followed by parentheses in mode default")
            last_index = next_index
          end
        elseif char == ")" then
--          print("char_index", char_index, "l1_inline_end", l1_inline_end)
          last_index = next_index
          if char_index == l1_inline_end then
            warn(layer == 1, "l1_inline_end reached within layer-2 code")
            start_index = start_index + 1
            if l1_inline_type then --some form of omissible
              start_index = start_index + 1
              chunk[next_chunk_index+1] = l1_inline_type == 'omissible' and ")if _ then _pr_[_npi_]=_ _npi_=_npi_+1 end " or ")if _~=nil then _pr_[_npi_]=_ _npi_=_npi_+1 end "
              next_chunk_index = next_chunk_index + 2
            else --non-omissible
              next_chunk_index = next_chunk_index + 1
            end
            layer_mode, layer = '2', 2
--            print("switching layer: 2")
            $(force_write)
          end
        elseif char == "-" then
          warn(current_mode == 'default', "- encountered in non-default mode")
          if string_sub(contents, next_index, next_index) == "-" then
            next_index = next_index + 2
            if not parse_long_string(next_index) then
              mode[layer] = 'line comment'
              last_index = next_index
            end
          else
            last_index = next_index
          end
        elseif char == "[" then
          warn(current_mode == 'default' or current_mode == 'long', "[ encountered in non-default, non-long mode")
          if not parse_long_string(next_index) then
            last_index = next_index
          end
        elseif char == "]" then
          last_index = next_index
          local lsei = long_string_end_indicator[layer]
          long_string_end_table[2] = lsei
          if current_mode == 'long' and string_find(contents, table_concat(long_string_end_table), next_index) then
            mode[layer] = 'default'
            last_index = next_index + string_len(lsei) + 1
          end
          if layer == 2 and mode[1] == 'long' then
            local lsei = long_string_end_indicator[1]
            long_string_end_table[2] = lsei
            if string_find(contents, table_concat(long_string_end_table), next_index) then
--              print("====IN====")
              char_index = next_index + string_len(lsei)
              last_index = char_index
              chunk[next_chunk_index+2] = "_npi_=_npi_+1"
              next_chunk_index = next_chunk_index + 3
              $(force_write)
            else
              last_index = next_index
            end
          end
        else
          mode[layer] = (char == "\"" and 'quote string') or (char == "'" and 'apostrophe string') or warn(false, "triggered by non-useful symbol", char)
--          print("opening string!")
          last_index = next_index
        end
        if parsed_long_string_flag then
            mode[layer] = 'long'
            last_index = next_index + 1 + parsed_long_string_flag
            parsed_long_string_flag = false
        end
        $(use_goto and [[goto no_write
        ::force_write::]] or [[if force_write_flag then
          force_write_flag = false]])
--          print("around line ", line_nr, " forced write of ", begin_index, " to ", char_index - 1, " at layer ", previous_layer)
          write[previous_layer](previous_chunk_index, begin_index, char_index - 1)
          begin_index = last_index
        $(use_goto and "::no_write::" or "end")
      end
    end
  end
  write[layer](next_chunk_index, begin_index, -1)
  chunk[next_chunk_index+layer] = " return require\"lua_version\".loadstring(table.concat(_pr_))"
  return lua_version.loadstring(table_concat(chunk)), chunk
end

local prep_path = {string_gsub(package_path, "%.lua", ".lpp"), nil, string_gsub(package_path, "%.lua", ".lpp.lua"), nil, package_path}

local dir_sep, temp_sep, sub_mark
  
if package_config then
  dir_sep, temp_sep, sub_mark = string.match(package_config, "^(.-)\n(.-)\n(.-)\n")
  sub_mark = string_find("$^()%.[]*+-?", sub_mark, 1, true) and "%"..sub_mark or sub_mark
else
  dir_sep, temp_sep, sub_mark = "/", ";", "%?"
end
local package_path_gmatch_pattern = table_concat({"([^", temp_sep, "]+)", temp_sep, "?"})

--retrieves files by module name
local search_function --only done for clarity; not necessary, because layer-1 blocks don't interfer with layer-2 visibility
#local package_searchpath = package.searchpath
#if not package_searchpath then
  
  prep_path[2] = dir_sep
  prep_path[4] = dir_sep
  prep_path = table_concat(prep_path)
  local fnf_table = {"file not found (searchpaths: ", nil, ")"}
  function search_function(modname)
    modname = string_gsub(modname, "%.", dir_sep)
    local paths = string_gsub(prep_path, sub_mark, modname) -- done in advance; assuming temp_sep isn't contained in modname
    for path in string_gmatch(paths, package_path_gmatch_pattern) do -- ";;" is currently ignored
      local file, err_msg = io_open(path)
      if file then return file end
    end
    fnf_table[2] = paths
    return nil, table_concat(fnf_table)
  end
  
#else

  prep_path[2] = ";"
  prep_path[4] = ";"
  prep_path = table_concat(prep_path)
  --"imports" [[
    local package_searchpath = package.searchpath
  --]] "imports"
  
  function search_function(modname)
    local file, err_msg = package_searchpath(modname, prep_path)
    return (file and io_open(file)), err_msg
  end
  
#end

--used to log which modules were prepped and cache the resulting functions
local prep_loaded = {}

--preps a file by module name and caches and returns the resulting function
local function prep_mod(modname)
  local result = prep_loaded[modname]
  if result then return result end
  local file = assert(search_function(modname))
  result = prep(file:read("*a"))
  io_close(file)
  prep_loaded[modname] = result
  return result
end

local function prepquire(modname)
  local result = package_loaded[modname]
  if result then return result end
  result = prep_mod(modname)()()
  package_loaded[modname] = result ~= nil and result or true
  return result
end

#local package_searchers = lua_version.package_searchers
#if package_searchers then
  
  local function prepquire_file(path)
    local file = io_open(path)
    local result = prep(file:read("*a"))
    io_close(file)
    return result()()
  end
  
#local package_searcher = lua_version.require_calls_loader_with_second_argument and "prepquire_file, path" or "function () return prepquire_file(path) end"
  
  local searcher_function
  
#if not package_searchpath then
  
  function searcher_function(modname)
    modname = string_gsub(modname, "%.", dir_sep)
    local paths = string_gsub(prep_path, sub_mark, modname) -- done in advance; assuming temp_sep isn't contained in modname
    for path in string_gmatch(paths, package_path_gmatch_pattern) do -- ";;" is currently ignored
      local file, err_msg = io_open(path)
      if file then
        io_close(file)
        return $(package_searcher)
      end
    end
    fnf_table[2] = paths
    return nil
  end
  
#else

  function searcher_function(modname)
    local file, err_msg = package_searchpath(modname, prep_path)
    return file and $(package_searcher)
  end
  
#end

local package_searchers = lua_version.package_searchers
package_searchers[#package_searchers+1] = searcher_function

#end

return {
  prep = prep,
  search_function = search_function,
  prep_loaded = prep_loaded,
  prep_mod = prep_mod,
  prep_path = prep_path,
  --preps a file, executes the resulting function and caches and returns its result
  prepquire = prepquire$(!package_searchers and [[,
  searcher_function = searcher_function]])
  }
--]===]