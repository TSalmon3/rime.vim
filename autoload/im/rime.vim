let s:job        = v:null
let s:resp_buf   = ''
let s:resp_ready = 0
let s:next_id    = 0

" 当前正在等待答复的请求 id；只有回包里的 id 跟它一致才算数，
" 迟到的旧请求答复（比如上一次超时了，但后端过一会儿还是回了）
" 会被直接丢弃，避免污染下一次请求的状态。
let s:pending_id = -1

function! s:on_line(line) abort"{{{
  if empty(a:line)
    return
  endif
  try
    let decoded = json_decode(a:line)
  catch
    " 解析失败也当成一次有效答复交给调用方去报错，保持原有行为。
    let s:resp_buf   = a:line
    let s:resp_ready = 1
    return
  endtry
  if get(decoded, 'id', -1) != s:pending_id
    " 迟到的旧回包，直接丢弃，继续等真正对应这次请求的答复。
    return
  endif
  let s:resp_buf   = a:line
  let s:resp_ready = 1
endfunction"}}}

" --- Neovim implementation -------------------------------------------

function! s:on_stdout_nvim(job_id, data, event) abort"{{{
  for line in a:data
    call s:on_line(line)
  endfor
endfunction"}}}

function! s:on_exit_nvim(job_id, code, event) abort"{{{
  " call LIB#log#info("[job exit] code: " . a:code . " event: " . a:event)
  let s:job = v:null
endfunction"}}}

function! s:on_error_nvim(job_id, data, event) abort"{{{
  " call LIB#log#info("[job error] data: " . join(a:data, "\n") . "event: " . a:event)
endfunction"}}}

function! s:job_start_nvim(cmd) abort"{{{
  let job = jobstart(a:cmd, {
        \ 'on_stdout': function('s:on_stdout_nvim'),
        \ 'on_exit'  : function('s:on_exit_nvim'),
        \ 'on_stderr'  : function('s:on_error_nvim'),
        \ })
  return job > 0 ? job : v:null
endfunction"}}}

function! s:job_send_nvim(job, text) abort"{{{
  call chansend(a:job, a:text)
endfunction"}}}

function! s:job_stop_nvim(job) abort"{{{
  call jobstop(a:job)
endfunction"}}}

" --- Vim implementation ------------------------------------------------

function! s:out_cb_vim(channel, msg) abort"{{{
  call s:on_line(a:msg)
endfunction"}}}

function! s:exit_cb_vim(job, status) abort"{{{
  " call LIB#log#info("[job exit]")
  let s:job = v:null
endfunction"}}}

function! s:error_cb_vim(job, status) abort"{{{
  " call LIB#log#info("[job exit]")
endfunction"}}}

function! s:job_start_vim(cmd) abort"{{{
  let job = job_start(a:cmd, {
        \ 'out_cb'  : function('s:out_cb_vim'),
        \ 'exit_cb' : function('s:exit_cb_vim'),
        \ 'err_cb' : function('s:error_cb_vim'),
        \ })
  return job_status(job) ==# 'run' ? job : v:null
endfunction"}}}

function! s:job_send_vim(job, text) abort"{{{
  call ch_sendraw(job_getchannel(a:job), a:text)
endfunction"}}}

function! s:job_stop_vim(job) abort"{{{
  call job_stop(a:job)
endfunction"}}}

" --- Dispatchers ------------------------------------------------------

function! s:job_start(cmd) abort"{{{
  return has('nvim') ? s:job_start_nvim(a:cmd) : s:job_start_vim(a:cmd)
endfunction"}}}

function! s:job_send(job, text) abort"{{{
  if has('nvim')
    call s:job_send_nvim(a:job, a:text)
  else
    call s:job_send_vim(a:job, a:text)
  endif
endfunction"}}}

function! s:job_stop(job) abort"{{{
  if has('nvim')
    call s:job_stop_nvim(a:job)
  else
    call s:job_stop_vim(a:job)
  endif
endfunction"}}}

" --- Lifecycle ------------------------------------------------------

function! im#rime#init() abort"{{{
  let g:im_rime_bin = get(g:, 'im_rime_bin', 'rime-query')
  let $RIME_LOG = expand(get(g:, 'im_log_file', '~/.local/state/log/vim/rime.log'))

  if has('mac')
    let $RIME_USER_DATA_DIR   = expand(get(g:, 'im_user_data_dir', '~/dotfiles/rime/rime-ice-vim'))
    let $RIME_SHARED_DATA_DIR = get(g:, 'im_shared_data_dir', '/Library/Input Methods/Squirrel.app/Contents/SharedSupport')
  elseif !empty($WSL_DISTRO_NAME) || has('linux')
    let $RIME_USER_DATA_DIR   = expand(get(g:, 'im_user_data_dir', '~/.local/share/rime-ice'))
    let $RIME_SHARED_DATA_DIR = get(g:, 'im_shared_data_dir', '/usr/share/rime-data')
  elseif has('win32') || has('win64')
    let $RIME_USER_DATA_DIR   = expand(get(g:, 'im_user_data_dir', '~/AppData/Roaming/Rime'))
    let $RIME_SHARED_DATA_DIR = get(g:, 'im_shared_data_dir', 'D:/Application/weasel-0.17.4/data')
  endif
endfunction"}}}

function! im#rime#start() abort"{{{
  if s:job isnot v:null
    return 1
  endif

  if !executable('rime-query')
    echohl WarningMsg
    echomsg "[IM]: rime-query not found in PATH, please check your installation"
    echohl None
    return 0
  endif

  let other = []
  if has('win32') || has('win64')
    let bin = fnamemodify(g:im_rime_bin, ':t')
    let bin = bin =~? '\.exe$' ? bin : bin . '.exe'
    let other = filter(systemlist('tasklist /FI "IMAGENAME eq ' . bin . '" /FO CSV /NH'),
          \ {_, l -> l =~ '^"'})
  elseif has('unix')
    let other = filter(systemlist('pgrep -x ' . shellescape(fnamemodify(g:im_rime_bin, ':t'))),
          \ {_, v -> v =~ '^\d\+$'})
  endif

  " if len(other) > 0
  "   echohl WarningMsg
  "   echom '[IM] another rime-query backend is holding the user dictionary; its word frequency may silently reset'
  "   echohl None
  " endif

  let state = im#state#get()
  let state.locked = len(other) > 0 ? 1 : 0

  let s:job = s:job_start([g:im_rime_bin])
  if s:job is v:null
    echohl WarningMsg
    echom '[IM] failed to start rime backend: ' . g:im_rime_bin
    echohl None
    return 0
  endif

  call im#rime#apply_initial_options()
  return 1
endfunction"}}}

function! im#rime#stop() abort"{{{
  if s:job isnot v:null
    try
      call s:job_send(s:job, "{\"type\":\"quit\",\"id\":-99}\n")
    catch
    endtry
    call s:job_stop(s:job)
    let s:job = v:null
  endif
endfunction"}}}

function! im#rime#call(request, timeout_ms) abort"{{{
  if s:job is v:null
    return v:null
  endif

  let s:next_id += 1
  let s:pending_id = s:next_id
  let request = extend(copy(a:request), {'id': s:pending_id})

  let s:resp_ready = 0
  let s:resp_buf   = ''
  call s:job_send(s:job, json_encode(request) . "\n")

  let remaining = a:timeout_ms
  while !s:resp_ready && remaining > 0
    sleep 1m
    let remaining -= 1
  endwhile

  if !s:resp_ready
    return v:null
  endif

  try
    let resp = json_decode(s:resp_buf)
    if get(resp, 'ok', 0)
      return resp
    endif
  catch
    echom '[im] malformed response: ' . string(s:resp_buf)
    throw v:exception
  endtry
  return v:null
endfunction"}}}

function! s:parse_context(resp) abort"{{{
  let state = im#state#get()
  let state.preedit = get(a:resp, 'preedit', '')
  let state.has_more     = get(a:resp, 'has_more', v:false)

  let candidates = get(a:resp, 'candidates', [])
  let comments   = get(a:resp, 'comments', [])
  let items = []
  for i in range(len(candidates))
    call add(items, {'word': candidates[i], 'comment': get(comments, i, '')})
  endfor

  return {
        \ 'preedit'    : get(a:resp, 'preedit', ''),
        \ 'input'      : get(a:resp, 'input', ''),
        \ 'cursor_pos' : get(a:resp, 'cursor_pos', 0),
        \ 'sel_start'  : get(a:resp, 'sel_start', 0),
        \ 'sel_end'    : get(a:resp, 'sel_end', 0),
        \ 'page_no'    : get(a:resp, 'page_no', 0),
        \ 'highlighted_candidate_index' : get(a:resp, 'highlighted_candidate_index', 0),
        \ 'composing'  : get(a:resp, 'composing', v:false),
        \ 'accepted'   : get(a:resp, 'accepted', v:true),
        \ 'candidates' : items,
        \ 'committed'  : get(a:resp, 'committed', ''),
        \ 'changed_options' : get(a:resp, 'changed_options', []),
        \ 'schema_changed'  : get(a:resp, 'schema_changed', v:false),
        \ 'schema_id'       : get(a:resp, 'schema_id', ''),
        \ 'schema_name'     : get(a:resp, 'schema_name', ''),
        \ }
endfunction"}}}

function! s:empty_context() abort"{{{
  return {
        \ 'preedit'    : '',
        \ 'input'      : '',
        \ 'cursor_pos' : 0,
        \ 'sel_start'  : 0,
        \ 'sel_end'    : 0,
        \ 'page_no'    : 0,
        \ 'highlighted_candidate_index' : 0,
        \ 'composing'  : v:false,
        \ 'accepted'   : v:false,
        \ 'candidates' : [],
        \ 'committed'  : '',
        \ 'changed_options' : [],
        \ 'schema_changed'  : v:false,
        \ 'schema_id'       : '',
        \ 'schema_name'     : '',
        \ }
endfunction"}}}

function! im#rime#key(keycode, mask) abort"{{{
  let resp = im#rime#call({'type': 'key', 'keycode': a:keycode, 'mask': a:mask}, 800)
  if resp is v:null
    return s:empty_context()
  endif
  return s:parse_context(resp)
endfunction"}}}

function! im#rime#select(index) abort"{{{
  let resp = im#rime#call({'type': 'select', 'index': a:index}, 800)
  if resp is v:null
    return s:empty_context()
  endif
  return s:parse_context(resp)
endfunction"}}}

function! im#rime#get_input() abort"{{{
  let resp = im#rime#call({'type': 'get_input'}, 800)
  if resp is v:null
    return s:empty_context()
  endif
  return s:parse_context(resp)
endfunction"}}}

function! im#rime#commit_composition() abort"{{{
  let resp = im#rime#call({'type': 'commit_composition'}, 800)
  if resp is v:null
    return s:empty_context()
  endif
  return s:parse_context(resp)
endfunction"}}}

function! im#rime#reset() abort"{{{
  let resp = im#rime#call({'type': 'reset'}, 100)
  if resp is v:null
    return s:empty_context()
  endif
  return s:parse_context(resp)
endfunction"}}}

function! im#rime#switch_ascii_mode(style) abort"{{{
  let resp = im#rime#call({'type': 'switch_ascii_mode', 'style': a:style}, 800)
  if resp is v:null
    return s:empty_context()
  endif
  return s:parse_context(resp)
endfunction"}}}

function! im#rime#toggle_option(name) abort"{{{
  let resp = im#rime#call({'type': 'toggle_option', 'option': a:name}, 300)
  if resp is v:null
    return v:null
  endif
  return get(resp, 'value', v:null)
endfunction"}}}

function! im#rime#set_option(name, value) abort"{{{
  let resp = im#rime#call({
        \ 'type': 'set_option',
        \ 'option': a:name,
        \ 'value': a:value ? v:true : v:false,
        \ }, 800)
  if resp is v:null
    return v:null
  endif
  return get(resp, 'value', v:null)
endfunction"}}}

function! im#rime#get_option(name) abort"{{{
  let resp = im#rime#call({'type': 'get_option', 'option': a:name}, 800)
  if resp is v:null
    return v:null
  endif
  return get(resp, 'value', v:null)
endfunction"}}}

function! im#rime#deploy() abort"{{{
  " 触发 librime 完整重新部署；同步阻塞，部署期间后端不响应其他请求。
  " 返回 'success' / 'failure'；后端未响应返回 v:null。
  let resp = im#rime#call({'type': 'deploy'}, get(g:, 'im_deploy_timeout', 60000))
  if resp is v:null
    return v:null
  endif
  return get(resp, 'deploy_status', '')
endfunction"}}}

function! im#rime#sync() abort"{{{
  " 先同步用户词库（sync/<installation_id>/ 下的备份），再重新部署。
  " 返回 deploy_status；后端未响应返回 v:null。
  let resp = im#rime#call({'type': 'sync'}, get(g:, 'im_deploy_timeout', 60000))
  if resp is v:null
    return v:null
  endif
  return im#rime#deploy()
endfunction"}}}

function! im#rime#warmup() abort"{{{
  " 强制完成首键懒加载，避免第一次打字卡顿。
  call im#rime#call({'type': 'warmup'}, 800)
endfunction"}}}

function! im#rime#apply_initial_options() abort"{{{
  let state = im#state#get()
  if exists('g:im_option_ascii_mode')
    let value = im#rime#set_option('ascii_mode', get(g:, 'im_option_ascii_mode', 0))
  endif

  if exists('g:im_option_ascii_punct')
    let value = im#rime#set_option('ascii_punct', get(g:, 'im_option_ascii_punct', 0))
  endif

  if exists('g:im_option_traditional')
    let value = im#rime#set_option('traditionalization', get(g:, 'im_option_traditional', 0))
  endif

  call im#rime#warmup()
endfunction"}}}

function! im#rime#toggle_traditional() abort"{{{
  let state = im#state#get()
  if !state.started
    return
  endif
  let value = im#rime#toggle_option('traditionalization')
  if value is v:null
    echohl WarningMsg
    echom '[IM] failed to toggle traditionalization (backend not responding?)'
    echohl None
    return
  endif
  let state.traditional = value ? 1 : 0
  redrawstatus
endfunction"}}}


function! im#rime#toggle_ascii_mode() abort"{{{
  let state = im#state#get()
  if !state.started
    return
  endif
  let value = im#rime#toggle_option('ascii_mode')
  if value is v:null
    echohl WarningMsg
    echom '[IM] failed to toggle ascii_mode (backend not responding?)'
    echohl None
    return
  endif
  let state.ascii_mode = value ? 1 : 0
  redrawstatus
endfunction"}}}

function! im#rime#toggle_ascii_punct() abort"{{{
  let state = im#state#get()
  if !state.started
    return
  endif
  let value = im#rime#toggle_option('ascii_punct')
  if value is v:null
    echohl WarningMsg
    echom '[IM] failed to toggle ascii_punct (backend not responding?)'
    echohl None
    return
  endif
  let state.ascii_punct = value ? 1 : 0
  redrawstatus
endfunction"}}}

function! im#rime#toggle_emoji() abort"{{{
  let state = im#state#get()
  if !state.started
    return
  endif
  let value = im#rime#toggle_option('emoji')
  if value is v:null
    echohl WarningMsg
    echom '[IM] failed to toggle emoji (backend not responding?)'
    echohl None
    return
  endif
  let state.emoji = value ? 1 : 0
  redrawstatus
endfunction"}}}

function! im#rime#toggle_full_shape() abort"{{{
  let state = im#state#get()
  if !state.started
    return
  endif
  let value = im#rime#toggle_option('full_shape')
  if value is v:null
    echohl WarningMsg
    echom '[IM] failed to toggle full_shape (backend not responding?)'
    echohl None
    return
  endif
  let state.full_shape = value ? 1 : 0
  redrawstatus
endfunction"}}}

