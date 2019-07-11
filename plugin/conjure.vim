let s:cwd = resolve(expand("<sfile>:p:h") . "/..")

" Don't load if...
"  * Not in Neovim
"  * Already loaded
"  * Blocked by CONJURE_ALLOWED_DIR (bin/dev)
if !has('nvim') || exists("g:conjure_loaded") || ($CONJURE_ALLOWED_DIR != "" && $CONJURE_ALLOWED_DIR != s:cwd)
  finish
endif

let g:conjure_loaded = v:true
let g:conjure_initialised = v:false
let g:conjure_ready = v:false

" User config with defaults.
function! s:def_config(name, default)
  execute "let g:conjure_" . a:name . " = get(g:, 'conjure_" . a:name . "', " . string(a:default) . ")"
endfunction

call s:def_config("log_direction", "vertical") " vertical/horizontal
call s:def_config("log_size_small", 25) " %
call s:def_config("log_size_large", 50) " %
call s:def_config("log_auto_close", v:true) " boolean
call s:def_config("log_auto_open", ["eval", "ret", "ret-multiline", "out", "err", "tap", "doc", "load-file", "test"]) " set
call s:def_config("fold_results", v:false) " boolean
call s:def_config("quick_doc_normal_mode", v:true) " boolean
call s:def_config("quick_doc_insert_mode", v:true) " boolean
call s:def_config("quick_doc_time", 250) " ms
call s:def_config("omnifunc", v:true) " boolean

" TODO Use these values in mappings, disable if v:null.
call s:def_config("default_mappings", v:true) " boolean
call s:def_config("map_prefix", "<localleader>")
call s:def_config("nmap_eval_word", "ew")
call s:def_config("nmap_eval_current_form", "ee")
call s:def_config("nmap_eval_root_form", "er")
call s:def_config("nmap_eval_buffer", "eb")
call s:def_config("nmap_eval_file", "ef")
call s:def_config("vmap_eval_selection", "ee")
call s:def_config("nmap_up", "cu")
call s:def_config("nmap_status", "cs")
call s:def_config("nmap_open_log", "cl")
call s:def_config("nmap_close_log", "cq")
call s:def_config("nmap_toggle_log", "cL")
call s:def_config("nmap_run_tests", "tt")
call s:def_config("nmap_run_all_tests", "ta")

let s:jobid = v:null
let s:dev = $CONJURE_ALLOWED_DIR != ""

if $CONJURE_JOB_OPTS != ""
  let s:job_opts = $CONJURE_JOB_OPTS
else
  let s:job_opts = "-A:fast"
endif

" Create commands for RPC calls handled by main.clj.
command! -nargs=* ConjureUp call conjure#notify("up", <q-args>)
command! -nargs=0 ConjureStatus call conjure#notify("status")

command! -nargs=1 ConjureEval call conjure#notify("eval", <q-args>)
command! -range   ConjureEvalSelection call conjure#notify("eval_selection")
command! -nargs=0 ConjureEvalCurrentForm call conjure#notify("eval_current_form")
command! -nargs=0 ConjureEvalRootForm call conjure#notify("eval_root_form")
command! -nargs=0 ConjureEvalBuffer call conjure#notify("eval_buffer")
command! -nargs=1 ConjureLoadFile call conjure#notify("load_file", <q-args>)

command! -nargs=1 ConjureDefinition call conjure#notify("definition", <q-args>)
command! -nargs=1 ConjureDoc call conjure#notify("doc", <q-args>)
command! -nargs=0 ConjureQuickDoc call conjure#quick_doc()
command! -nargs=0 ConjureClearVirtual call conjure#notify("clear_virtual")
command! -nargs=0 ConjureOpenLog call conjure#notify("open_log")
command! -nargs=0 ConjureCloseLog call conjure#notify("close_log")
command! -nargs=0 ConjureToggleLog call conjure#notify("toggle_log")
command! -nargs=* ConjureRunTests call conjure#notify("run_tests", <q-args>)
command! -nargs=? ConjureRunAllTests call conjure#notify("run_all_tests", <q-args>)

augroup conjure
  autocmd!
  autocmd BufEnter *.clj,*.clj[cs] call conjure#init()
  autocmd VimLeavePre * call conjure#stop()

  if g:conjure_default_mappings
    autocmd FileType clojure nnoremap <silent> <buffer> <localleader>ew :ConjureEval <c-r><c-w><cr>
    autocmd FileType clojure nnoremap <silent> <buffer> <localleader>ee :ConjureEvalCurrentForm<cr>
    autocmd FileType clojure nnoremap <silent> <buffer> <localleader>er :ConjureEvalRootForm<cr>
    autocmd FileType clojure vnoremap <silent> <buffer> <localleader>ee :ConjureEvalSelection<cr>
    autocmd FileType clojure nnoremap <silent> <buffer> <localleader>eb :ConjureEvalBuffer<cr>
    autocmd FileType clojure nnoremap <silent> <buffer> <localleader>ef :ConjureLoadFile <c-r>=expand('%:p')<cr><cr>

    autocmd FileType clojure nnoremap <silent> <buffer> <localleader>cu :ConjureUp<cr>
    autocmd FileType clojure nnoremap <silent> <buffer> <localleader>cs :ConjureStatus<cr>
    autocmd FileType clojure nnoremap <silent> <buffer> <localleader>cl :ConjureOpenLog<cr>
    autocmd FileType clojure nnoremap <silent> <buffer> <localleader>cq :ConjureCloseLog<cr>
    autocmd FileType clojure nnoremap <silent> <buffer> <localleader>cL :ConjureToggleLog<cr>

    autocmd FileType clojure nnoremap <silent> <buffer> <localleader>tt :ConjureRunTests<cr>
    autocmd FileType clojure nnoremap <silent> <buffer> <localleader>ta :ConjureRunAllTests<cr>

    autocmd FileType clojure nnoremap <silent> <buffer> K :ConjureDoc <c-r><c-w><cr>
    autocmd FileType clojure nnoremap <silent> <buffer> gd :ConjureDefinition <c-r><c-w><cr>
  endif

  if g:conjure_log_auto_close
    autocmd InsertEnter *.edn,*.clj,*.clj[cs] :call conjure#close_unused_log()
  endif

  if g:conjure_quick_doc_normal_mode
    autocmd CursorMoved *.edn,*.clj,*.clj[cs] :call conjure#quick_doc()

    if !g:conjure_quick_doc_insert_mode
      autocmd InsertEnter *.edn,*.clj,*.clj[cs] :ConjureClearVirtual
    endif
  endif

  if g:conjure_quick_doc_insert_mode
    autocmd CursorMovedI *.edn,*.clj,*.clj[cs] :call conjure#quick_doc()

    if !g:conjure_quick_doc_normal_mode
      autocmd InsertEnter *.edn,*.clj,*.clj[cs] :call conjure#quick_doc()
      autocmd InsertLeave *.edn,*.clj,*.clj[cs] :ConjureClearVirtual
    endif
  endif

  if g:conjure_quick_doc_normal_mode || g:conjure_quick_doc_insert_mode
    autocmd BufLeave *.edn,*.clj,*.clj[cs] :call conjure#quick_doc_cancel()
  endif

  if g:conjure_omnifunc
    autocmd FileType clojure setlocal omnifunc=conjure#omnicomplete
  endif
augroup END

" Handles all stderr from the Clojure process.
" Simply prints it in red.
function! conjure#on_stderr(jobid, lines, event) dict
  echohl ErrorMsg
  for line in a:lines
    if len(line) > 0
      echomsg line
    endif
  endfor
  echo "Error from Conjure, see :messages for more"
  echohl None
endfunction

" Reset the jobid, notify that you can restart easily.
function! conjure#on_exit(jobid, msg, event) dict
  if a:msg != 0
    echohl ErrorMsg
    echo "Conjure exited (" . a:msg . "), consider conjure#start()"
    echohl None

    let s:jobid = v:null
    let g:conjure_ready = v:false
  endif
endfunction

" Start up the Clojure process if we haven't already.
function! conjure#start()
  if s:jobid == v:null
    let s:jobid = jobstart("clojure " . s:job_opts . " -m conjure.main " . getcwd(0), {
    \  "rpc": v:true,
    \  "cwd": s:cwd,
    \  "on_stderr": "conjure#on_stderr",
    \  "on_exit": "conjure#on_exit"
    \})
  endif
endfunction

" Stop the Clojure process if it's running.
function! conjure#stop()
  if s:jobid != v:null
    call conjure#notify("stop")
  endif
endfunction

" Trigger quick doc on CursorMoved(I) with a debounce.
" It displays the doc for the head of the current form using virtual text.
let s:quick_doc_timer = v:null

function! conjure#quick_doc_cancel()
  if s:quick_doc_timer != v:null
    call timer_stop(s:quick_doc_timer)
    let s:quick_doc_timer = v:null
  endif
endfunction

function! conjure#quick_doc()
  if g:conjure_ready
    call conjure#quick_doc_cancel()
    let s:quick_doc_timer = timer_start(g:conjure_quick_doc_time, {-> conjure#notify("quick_doc")})
  endif
endfunction

" Cancel existing quick doc timers and notify/request Conjure over RPC.
function! conjure#notify(method, ...)
  if s:jobid != v:null
    call conjure#quick_doc_cancel()
    return rpcnotify(s:jobid, a:method, get(a:, 1, 0))
  endif
endfunction

function! conjure#request(method, ...)
  if s:jobid != v:null
    call conjure#quick_doc_cancel()
    return rpcrequest(s:jobid, a:method, get(a:, 1, 0))
  endif
endfunction

" Close the log if we're not currently using it.
function! conjure#close_unused_log()
  if expand("%:p") !~# "/tmp/conjure.cljc"
    ConjureCloseLog
  endif
endfunction

" Handle omnicomplete requests through complement if it's there.
function! conjure#omnicomplete(findstart, base)
  if a:findstart
    let l:line = getline('.')[0 : col('.')-2]
    return col('.') - strlen(matchstr(l:line, '\k\+$')) - 1
  else
    return conjure#completions(a:base)
  endif
endfunction

function! conjure#completions(base)
  return conjure#request("completions", a:base)
endfunction

function! conjure#get_rpc_port()
  return conjure#request("get_rpc_port")
endfunction

" Is the cursor inside code or is it in a comment / string.
function! conjure#cursor_in_code()
  " Get the name of the syntax at the bottom of the stack.
  let l:stack = synstack(line("."), col("."))

  if len(l:stack) == 0
    return v:true
  else
    let l:name = synIDattr(l:stack[-1], "name")

    " If it's comment or string we're not in code.
    return !(l:name ==# "clojureComment" || l:name ==# "clojureString")
  endif
endfunction

" Is Conjure ready and are we typing in some code.
" Then the autocompletion plugins should kick in.
function! conjure#should_autocomplete()
  return g:conjure_ready && conjure#cursor_in_code()
endfunction

" Initialise if not done already.
function! conjure#init()
  if g:conjure_initialised == v:false
    if s:dev ||
          \(filereadable(s:cwd . "/classes/conjure/main$_main.class") &&
          \ filereadable(s:cwd . "/target/mranderson/load-order.edn"))
      let g:conjure_initialised = v:true
      call conjure#start()
      ConjureUp
    else
      echomsg "Conjure not compiled, please run bin/compile then conjure#init() or restart"
    endif
  endif
endfunction
