--documents differences between lua versions, to allow version-agnostic code (to some degree)
--supports [vanilla](http://www.lua.org/manual/) [5.0](http://www.lua.org/manual/5.0/manual.html), [5.1](http://www.lua.org/manual/5.1/manual.html), [5.2](http://www.lua.org/manual/5.2/manual.html), [5.3](http://www.lua.org/manual/5.3/manual.html) and [LuaJIT](http://luajit.org/extensions.html) up to [2.0.4](http://luajit.org/changes.html#LuaJIT-2.0.4) (see [luajit extensions](http://luajit.org/extensions.html))

--"imports" [[
  local debug = debug
  local math = math
  local package = package
  local string = string
--]] "imports"

--version deduction [[
  local version, _, find_version = (string.match or string.find)(_VERSION, "^Lua%s+(.*)$")
  version = tonumber(find_version or version)
  local isjit, possibly_jit_version = pcall(function() return require("jit").version_num end)
  local jit_version, isjit_compat
  if isjit then
    jit_version = possibly_jit_version or 10003 --assume first public release if version_num not present
    isjit_compat = rawlen and true or false --boolean conversion, to be able to distinguish between function values, assigned keys and unassigned keys
  end
--]] version deduction

--version shortcuts [[
  local until_5_1 = version < 5.1
  local since_5_1 = version >= 5.1
  local until_5_2 = version < 5.2
  local until_5_2_compat_jit = until_5_2 and not isjit_compat
  local since_5_2 = version >= 5.2
  local since_5_2_jit = since_5_2 or isjit and jit_version > 20000
  local since_5_2_compat_jit = since_5_2 or isjit_compat
  local only_5_2 = version == 5.2
  local only_5_2_compat_jit = only_5_2 or isjit_compat
  local until_5_3 = version < 5.3
  local since_5_3 = version >= 5.3
  --local since_5_3_jit = since_5_3 or isjit
--]] version shortcuts

--note: throughout this list "support" indicates presence of an argument/feature, whereas "accepts" indicates support for a specific argument's value
return {
  --version information [[
    is_luajit = isjit,
    is_luajit_lua52compat = isjit_compat,
    luajit_version = jit_version,
    version = version,
  --]] version information
  
  --syntactical changes [[
    --nomenclature [[
      goto_is_keyword = since_5_2_compat_jit,
      
      identifiers_accept_locale_dependants = until_5_2,
      
      varargs_identifier_expr = until_5_1 and "arg" or "...",
      varargs_via_arg = until_5_1,
      varargs_via_ellipsis = since_5_1,
    --]] nomenclature
    
    --literals [[
      numeric_literal_supports_hexadecimal_binary_exponent = since_5_2_jit,
      numeric_literal_supports_hexadecimal_fractional_part = since_5_2_jit,
      numeric_literal_supports_hexadecimal_integers = since_5_1,
      
      string_literal_bracket_escapes = until_5_1,
      string_literal_hex_escapes = since_5_2_jit,
      string_literal_long_brackets_support_levels = since_5_1,
      string_literal_long_brackets_support_nesting = until_5_1,
      string_literal_long_convert_eol_sequence_to_newline = since_5_2,
      string_literal_utf8_escapes = since_5_3,
      string_literal_white_space_skip_escape = since_5_2_jit,
    --]] literals
    
    --operators [[
      operator_band_support = since_5_3,
      operator_bnot_support = since_5_3,
      operator_bor_support = since_5_3,
      operator_bxor_support = since_5_3,
      operator_idiv_support = since_5_3,
      operator_len_support = since_5_1,
      operator_mod_support = since_5_1,
      operator_shl_support = since_5_3,
      operator_shr_support = since_5_3,
    --]] operators
    
    --structural [[
      break_anywhere = since_5_2_compat_jit,
      empty_statement_allowed = since_5_2_compat_jit,
      environment_supplied_by_env_upvalue = since_5_2,
      function_call_argument_list_after_line_break = since_5_2_jit, --not sure whether in plain non-compat jit (but I assume so, since it's a corner case all along)
      for_first_var_assignment_undefined = until_5_1,
      goto_support = since_5_2_jit,
      label_support = since_5_2_jit,
      until_condition_can_refer_to_inner_locals = since_5_1,
    --]] structural
  --]] syntactical changes
  
  --behaviour [[
    finalizer_entry_required_at_setmetatable = since_5_2,
    finalizers_called_in_reverse_construction_order = until_5_2,
    finalizers_called_in_reverse_marking_order = since_5_2,
    finalizers_called_on_tables = since_5_2,
    
    function_definition_may_reuse_value = since_5_2,
    function_return_value_number_min_limit = since_5_2 and 1001,
    
    operator_eq_only_calls_metamethod_of_both_operands = until_5_3,
    operator_eq_only_calls_metamethod_on_table_or_userdata = since_5_2,
    operator_len_calls_metamethod_on_table = since_5_2_compat_jit,
    operator_pow_calls_global_function_pow = until_5_1,
    operators_lt_le_only_call_metamethod_of_both_equally_typed_operands = until_5_2_compat_jit,
    operators_of_relation_convert_metamethod_results_to_boolean = since_5_2_compat_jit, --possibly also in normal jit, though rather unlikely
    
    table_weak_key_weak_value_is_ephemeron = since_5_2,
    
    unary_metamethods_called_with_second_argument_nil = until_5_1,
    unary_metamethods_called_with_duplicated_first_argument = since_5_2,
  --]] behaviour
  
  --library [[
    --basic [[
      assert_also_returns_message = since_5_1,
      
      collectgarbage_accepts_generational = only_5_2,
      collectgarbage_accepts_incremental = only_5_2,
      collectgarbage_accepts_isrunning = since_5_2,
      collectgarbage_by_limit = until_5_1,
      collectgarbage_count_also_returns_k_modulo = only_5_2,
      collectgarbage_step_arg_behaviour_specified = since_5_3,
      collectgarbage_step_full_collection_triggers_restart = until_5_2,
      collectgarbage_supports_option_arg = since_5_1,
      
      getfenv_setfenv_fenv_guard = until_5_1,
      
      ipairs_calls_ipairs_metamethod = only_5_2_compat_jit,
      ipairs_respects_index_metamethod = since_5_3,
      
      load_accepts_string_chunk = since_5_2_jit,
      load_library_functions_support_env = since_5_2_jit,
      load_library_functions_support_mode = since_5_2_jit,
      loadfile_accepts_nil_as_stdin = since_5_1,
      loadfile_accepts_utf8 = isjit,
      loadstring = until_5_2 and loadstring or load,
      
      pairs_calls_pairs_metamethod = since_5_2_compat_jit,
      
      rawset_returns_table = since_5_1,
      
      select_accepts_negative_index = since_5_2_jit, --not sure about plain non-compat jit, but it seems like a safe extension
      
      setmetatable_returns_table = since_5_1,
      
      tonumber_ignores_base_with_prefix = isjit,
      tonumber_supports_negative_non_decimal_values = since_5_2,
      
      xpcall_supports_function_arguments = since_5_2_jit,
    --]] basic
    
    --coroutine [[
      coroutine_create_wrap_accept_c_functions = since_5_3,
      
      coroutine_running_returns_nil_from_main_thread = until_5_2_compat_jit,
      coroutine_running_also_returns_main_boolean = since_5_2_compat_jit,
      
      coroutine_status_returns_normal = since_5_1,
      
      coroutine_yield_across_c_functions = since_5_2, --maybe also in jit, not sure whether "resumable vm" includes c functions...
      coroutine_yield_across_iterators = since_5_2_jit,
      coroutine_yield_across_metamethods = since_5_2_jit,
      coroutine_yield_across_protected_contexts = since_5_2_jit,
    --]] coroutine
    
    --debug [[
      debug_functions_operating_on_support_threads = since_5_1,
      
      debug_getinfo_checks_globals_for_name = until_5_1,
      debug_getinfo_namewhat_may_be_upvalue = since_5_1,
      debug_getinfo_namewhat_may_be_metamethod = isjit,
      debug_getinfo_return_includes_istailcall = since_5_2,
      debug_getinfo_return_includes_lastlinedefined = since_5_1,
      debug_getinfo_return_includes_nparams = since_5_1,
      debug_getinfo_return_includes_isvararg = since_5_1,
      debug_getinfo_supports_active_lines = since_5_1,
      debug_getinfo_what_may_be_tail = until_5_2,
      
      debug_getlocal_accepts_function = since_5_2_jit,
      debug_getlocal_setlocal_accept_negative_indices_for_varargs = since_5_2_jit,
      
      debug_getupvalue_setupvalue_handle_c_functions = since_5_2_jit, --they're never explicitly unsupported by the manuals...
      
      debug_getuservalue = until_5_2 and debug.getfenv or debug.getuservalue,
      
      debug_hook_tail_call = until_5_2 and "tail return" or "tail call",
      
      debug_setlocal_setupvalue_return_variable_name = since_5_1,
      
      debug_setmetatable_returns_object = since_5_2_compat_jit,
      
      debug_setuservalue = until_5_2 and debug.setfenv or debug.setuservalue,
      
      debug_traceback_returns_message_not_string_nil = since_5_2,
      debug_traceback_supports_level = since_5_1,
    --]] debug
    
    --io [[
      file_close_on_io_popen_result_returns_os_execute_return = since_5_2_compat_jit,
      io_file_accept_format_keep_eol = since_5_2_jit,
      io_file_format_prefixed_by_asterisk = since_5_3,
      io_file_lines_raise_errors = since_5_2_jit,
      io_file_lines_support_format = since_5_2_jit,
      io_file_write_return_file_handles = since_5_2_compat_jit,
      
      io_functions_also_return_system_dependent_error_code = since_5_1,
    --]] io
    
    --math [[
      math_atan_supports_second_argument = since_5_3,
      math_atan2 = until_5_3 and math.atan2 or math.atan,
      
      math_fmod = until_5_1 and math.mod or math.fmod,
      
      math_log_supports_base = since_5_2_jit,
      
      math_random_interval_cannot_be_empty = not isjit,
      math_random_args_must_have_integer_representation = since_5_3,
      math_random_randomseed_enhanced_prng = isjit,
    --]] math
    
    --os [[
      os_execute_accepts_nil_as_command = since_5_1,
      os_execute_also_returns_termination_type_and_exit_status = since_5_2_compat_jit,
      os_execute_returns_exit_status = until_5_2_compat_jit,
      os_execute_returns_true_on_success_else_nil = since_5_2_compat_jit,
      os_execute_returns_shell_availability_number = since_5_1,
      os_execute_returns_shell_availability_boolean = since_5_2_compat_jit,
      
      os_exit_accepts_boolean_code = since_5_2_jit,
      os_exit_supports_close = since_5_2_jit,
      
      os_remove_accepts_empty_directories_on_posix = since_5_1,
      os_rename_accepts_directory_names = since_5_1,
      
      os_setlocale_accepts_empty_string_as_locale = since_5_1,
      os_setlocale_accepts_nil_as_locale = since_5_1,
    --]] os
    
    --package [[
      package_loaded = until_5_1 and _LOADED or package.loaded,
      
      package_loadlib = until_5_1 and loadlib or package.loadlib,
      package_loadlib_accepts_funcname_asterisk = since_5_2_jit,
      
      package_path = until_5_1 and LUA_PATH or package.path,
      
      package_searcher_3_discards_version_separator_prefix = until_5_3,
      package_searcher_3_discards_version_separator_suffix = since_5_3,
      package_searchers = until_5_2 and package.loaders or package.searchers,
      package_searchers_also_return_file_name = since_5_2,
      
      require_calls_package_searchers = since_5_1,
      require_calls_loader_with_second_argument = since_5_2,
      require_defines_requiredname = until_5_1,
      require_loads_by_package_path = since_5_1,
      require_ignores_package_loaded_entry_once_loading = until_5_1,
    --]] package
    
    --string [[
      string_byte_supports_j = since_5_1,
      string_byte_range_checked = since_5_2_jit, --not sure about plain non-compat jit, but it seems like a safe extension
      
      string_dump_accepts_function_with_upvalues = since_5_2_jit,
      string_dump_supports_strip = since_5_3 or isjit, --since_5_3_jit
      string_dump_stripped_portable = isjit,
      
      string_format_percent_q_reversible = since_5_2_jit, --according to jit; standards before 5.2 aren't 100% clear, I assume? (They seem clear to me...)
      string_format_percent_s_checks_metamethod_tostring = since_5_2_jit,
      
      string_gmatch = until_5_1 and string.gfind or string.gmatch,
      
      string_gsub_accepts_table = since_5_1,
      string_gsub_false_nil_replacement_keeps_match = since_5_1,
      string_gsub_non_string_return_erases_match = until_5_1,
      string_gsub_pattern_0 = since_5_1,
      
      string_library_sets_metatable = since_5_1,
      
      string_pattern_can_contain_embedded_zeros = since_5_2,
      string_pattern_character_class_g = since_5_2_jit,
      string_pattern_character_class_z = until_5_2,
      string_pattern_item_f = since_5_2_jit, --not sure about plain non-compat jit, but it seems like a safe extension
      
      string_rep_supports_sep = since_5_2_jit,
      
      string_sub_range_checked = since_5_2_jit, --not sure about plain non-compat jit, but it seems like a safe extension
    --]] string
    
    --table [[
      table_functions_call_metamethods = since_5_3,
      table_functions_respect_length_via_n = until_5_1,
      table_functions_respect_length_via_internal_value = until_5_1,
      
      table_remove_accepts_pos_0 = since_5_2,
      
      table_unpack = until_5_2_compat_jit and unpack or table.unpack,
      table_unpack_supports_i_j = since_5_1,
    --]] table
  --]] library
  
  --implementation [[
    --stand-alone [[
      lua_sa_option_l_accepts_file_name = until_5_1,
      lua_sa_option_l_accepts_module_name = since_5_1,
      lua_sa_supports_option_E = since_5_2,
    --]] stand-alone
    
    lua_bytecode_verification = until_5_2, --is this even remotely relevant?
    non_strtod_tonumber = isjit --this refers to the implementation, consequences listed separately within library-basic
  --]] implementation
  }
--[[
    all values are explicitly first-class values since 5.1
    String explicitly declared "immutable" since 5.2 (but not modifiable in any way before that)
    Lua's strings are explicitly "encoding agnostic" since 5.3
    -- Numbers can be integers or real numbers since 5.3 / number has subtypes float, integer since 5.3 --
    userdata value is explicitly a pointer since 5.2
    table indexing disregards index's __eq metamethod by using rawget since 5.0, explicitly since 5.2
    string -> number input may explicitly have leading, trailing spaces since 5.2
    -- values other than tables and userdata may have metatables since 5.1 --
    -- __newindex is suggested to return result of function-type metamethod until 5.1 --
    -- some operations explicitly adjust their metamethod's results to one value since 5.1:
        add, sub, mul, div, mod, pow, unm, idiv, band, bor, bxor, bnot, shl, shr, concat, len, eq, lt, le, index (index not documented since 5.3) --
    -- support for none-function finalizers until 5.2 (?) --
    lua_close explicitly disallows marking objects for finalization during finalizers since 5.2
    marking objects for finalization during finalization is explicitly allowed since 5.3
    only objects that "have an explicit construction" are explicitly removed from weak tables since 5.2
    resurrected objects are explicitly removed as weak values before, as weak keys after running their finalizers since 5.2
    -- C functions all share the same "global" environment until 5.1 --
    -- error position information limited to strings since 5.2 (really?) --
    -- error position explicitly omitted with level of 0 since 5.2 --
    -- load explicitly doesn't check a binary chunk's "consistency" since 5.3 --
    -- upvalues of resulting functions from load other than _ENV are explicitly nil since 5.3 --
    -- all of load's result's upvalues are "fresh", not shared with other functions since 5.3 --
    -- rawget's index shall explicitly not be nil until 5.1 --
    io.lines() explicitly doesn't close the default input file since 5.1
    file:read explicitly stops at the format no data could be read with since 5.3
    daylight saving flag from os.time with format="*t" may be absent since 5.2
    os.time explicitly accepts out-of-range arguments since 5.3
    debug.getinfo explicitly doesn't support tail calls since 5.2
    debug.getlocal explicitly only counts active local variables since 5.3
]]