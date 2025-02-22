local _2afile_2a = "fnl/conjure/client/hy/stdio.fnl"
local _2amodule_name_2a = "conjure.client.hy.stdio"
local _2amodule_2a
do
  package.loaded[_2amodule_name_2a] = {}
  _2amodule_2a = package.loaded[_2amodule_name_2a]
end
local _2amodule_locals_2a
do
  _2amodule_2a["aniseed/locals"] = {}
  _2amodule_locals_2a = (_2amodule_2a)["aniseed/locals"]
end
local autoload = (require("conjure.aniseed.autoload")).autoload
local a, client, config, extract, log, mapping, nvim, stdio, str, text, _ = autoload("conjure.aniseed.core"), autoload("conjure.client"), autoload("conjure.config"), autoload("conjure.extract"), autoload("conjure.log"), autoload("conjure.mapping"), autoload("conjure.aniseed.nvim"), autoload("conjure.remote.stdio"), autoload("conjure.aniseed.string"), autoload("conjure.text"), nil
_2amodule_locals_2a["a"] = a
_2amodule_locals_2a["client"] = client
_2amodule_locals_2a["config"] = config
_2amodule_locals_2a["extract"] = extract
_2amodule_locals_2a["log"] = log
_2amodule_locals_2a["mapping"] = mapping
_2amodule_locals_2a["nvim"] = nvim
_2amodule_locals_2a["stdio"] = stdio
_2amodule_locals_2a["str"] = str
_2amodule_locals_2a["text"] = text
_2amodule_locals_2a["_"] = _
config.merge({client = {hy = {stdio = {mapping = {start = "cs", stop = "cS", interrupt = "ei"}, command = "hy --repl-output-fn=hy.repr", prompt_pattern = "=> "}}}})
local cfg = config["get-in-fn"]({"client", "hy", "stdio"})
do end (_2amodule_locals_2a)["cfg"] = cfg
local state
local function _1_()
  return {repl = nil}
end
state = ((_2amodule_2a).state or client["new-state"](_1_))
do end (_2amodule_locals_2a)["state"] = state
local buf_suffix = ".hy"
_2amodule_2a["buf-suffix"] = buf_suffix
local comment_prefix = "; "
_2amodule_2a["comment-prefix"] = comment_prefix
local function with_repl_or_warn(f, opts)
  local repl = state("repl")
  if repl then
    return f(repl)
  else
    return log.append({(comment_prefix .. "No REPL running"), (comment_prefix .. "Start REPL with " .. config["get-in"]({"mapping", "prefix"}) .. cfg({"mapping", "start"}))})
  end
end
_2amodule_locals_2a["with-repl-or-warn"] = with_repl_or_warn
local function display_result(msg)
  local prefix
  local function _3_()
    if msg.err then
      return "(err)"
    else
      return "(out)"
    end
  end
  prefix = (comment_prefix .. _3_() .. " ")
  local function _4_(_241)
    return (prefix .. _241)
  end
  local function _5_(_241)
    return ("" ~= _241)
  end
  return log.append(a.map(_4_, a.filter(_5_, str.split((msg.err or msg.out), "\n"))))
end
_2amodule_locals_2a["display-result"] = display_result
local function prep_code(s)
  return (s .. "\n")
end
_2amodule_locals_2a["prep-code"] = prep_code
local function eval_str(opts)
  local last_value = nil
  local function _6_(repl)
    local function _7_(msg)
      log.dbg("msg", msg)
      local msgs
      local function _8_(_241)
        return not ("" == _241)
      end
      msgs = a.filter(_8_, str.split((msg.err or msg.out), "\n"))
      last_value = (a.last(msgs) or last_value)
      display_result(msg)
      if msg["done?"] then
        log.append({""})
        if opts["on-result"] then
          return opts["on-result"](last_value)
        else
          return nil
        end
      else
        return nil
      end
    end
    return repl.send(prep_code(opts.code), _7_)
  end
  return with_repl_or_warn(_6_)
end
_2amodule_2a["eval-str"] = eval_str
local function eval_file(opts)
  return log.append({(comment_prefix .. "Not implemented")})
end
_2amodule_2a["eval-file"] = eval_file
local function doc_str(opts)
  local obj
  if ("." == string.sub(opts.code, 1, 1)) then
    obj = extract.prompt("Specify object or module: ")
  else
    obj = nil
  end
  local obj0 = ((obj or "") .. opts.code)
  local code = ("(if (in (mangle '" .. obj0 .. ") --macros--)\n                    (doc " .. obj0 .. ")\n                    (help " .. obj0 .. "))")
  local function _12_(repl)
    local function _13_(msg)
      local function _14_()
        if msg.err then
          return "(err) "
        else
          return "(doc) "
        end
      end
      return log.append(text["prefixed-lines"]((msg.err or msg.out), (comment_prefix .. _14_())))
    end
    return repl.send(prep_code(code), _13_)
  end
  return with_repl_or_warn(_12_)
end
_2amodule_2a["doc-str"] = doc_str
local function display_repl_status(status)
  local repl = state("repl")
  if repl then
    return log.append({(comment_prefix .. a["pr-str"](a["get-in"](repl, {"opts", "cmd"})) .. " (" .. status .. ")")}, {["break?"] = true})
  else
    return nil
  end
end
_2amodule_locals_2a["display-repl-status"] = display_repl_status
local function stop()
  local repl = state("repl")
  if repl then
    repl.destroy()
    display_repl_status("stopped")
    return a.assoc(state(), "repl", nil)
  else
    return nil
  end
end
_2amodule_2a["stop"] = stop
local function start()
  if state("repl") then
    return log.append({(comment_prefix .. "Can't start, REPL is already running."), (comment_prefix .. "Stop the REPL with " .. config["get-in"]({"mapping", "prefix"}) .. cfg({"mapping", "stop"}))}, {["break?"] = true})
  else
    local function _17_()
      display_repl_status("started")
      local function _18_(repl)
        return repl.send(prep_code("(import sys) (setv sys.ps2 \"\") (del sys)"))
      end
      return with_repl_or_warn(_18_)
    end
    local function _19_(err)
      return display_repl_status(err)
    end
    local function _20_(code, signal)
      if (("number" == type(code)) and (code > 0)) then
        log.append({(comment_prefix .. "process exited with code " .. code)})
      else
      end
      if (("number" == type(signal)) and (signal > 0)) then
        log.append({(comment_prefix .. "process exited with signal " .. signal)})
      else
      end
      return stop()
    end
    local function _23_(msg)
      return display_result(msg)
    end
    return a.assoc(state(), "repl", stdio.start({["prompt-pattern"] = cfg({"prompt_pattern"}), cmd = cfg({"command"}), ["on-success"] = _17_, ["on-error"] = _19_, ["on-exit"] = _20_, ["on-stray-output"] = _23_}))
  end
end
_2amodule_2a["start"] = start
local function on_load()
  return start()
end
_2amodule_2a["on-load"] = on_load
local function on_exit()
  return stop()
end
_2amodule_2a["on-exit"] = on_exit
local function interrupt()
  log.dbg("sending interrupt message", "")
  local function _25_(repl)
    local uv = vim.loop
    return uv.kill(repl.pid, uv.constants.SIGINT)
  end
  return with_repl_or_warn(_25_)
end
_2amodule_2a["interrupt"] = interrupt
local function on_filetype()
  mapping.buf("n", "HyStart", cfg({"mapping", "start"}), _2amodule_name_2a, "start")
  mapping.buf("n", "HyStop", cfg({"mapping", "stop"}), _2amodule_name_2a, "stop")
  return mapping.buf("n", "HyInterrupt", cfg({"mapping", "interrupt"}), _2amodule_name_2a, "interrupt")
end
_2amodule_2a["on-filetype"] = on_filetype
return _2amodule_2a