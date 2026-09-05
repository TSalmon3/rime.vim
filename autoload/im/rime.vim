let s:chan       = v:null
let s:resp_buf   = ''
let s:resp_ready = 0
let s:next_id    = 0

let s:connect_timer   = -1
let s:heartbeat_timer = -1

let s:plugin_root = fnamemodify(resolve(expand('<sfile>:p')), ':h:h:h')

let s:pending_id = -1

function! s:on_line(line) abort"{{{
  if empty(a:line)
    return
  endif
  try
    let decoded = json_decode(a:line)
  catch
    " 解析失败
    let s:resp_buf   = a:line
    let s:resp_ready = 1
    return
  endtry

  " daemon shutdown 广播（其他实例 :IMShutdown 时触发）
  if get(decoded, 'type', '') ==# 'shutdown'
    call timer_start(0, {-> s:daemon_died()})
    return
  endif

  if get(decoded, 'id', -1) != s:pending_id
    " 迟到的旧回包（含 daemon 的 ready 广播 id=0），直接丢弃。
    return
  endif
  let s:resp_buf   = a:line
  let s:resp_ready = 1
endfunction"}}}

" --- Neovim implementation -------------------------------------------

function! s:on_stdout_nvim(chan_id, data, event) abort"{{{
  if a:data == ['']
    call s:daemon_died()
    return
  endif
  for line in a:data
    call s:on_line(line)
  endfor
endfunction"}}}

function! s:on_chan_exit_nvim(chan_id, data, event) abort"{{{
  let s:chan = v:null
endfunction"}}}

function! s:conn_open_nvim(addr, transport) abort"{{{
  let mode = a:transport ==# 'tcp' ? 'tcp' : 'pipe'
  let chan = v:null
  try
    let chan = sockconnect(mode, a:addr, {
          \ 'on_data': function('s:on_stdout_nvim'),
          \ 'on_exit': function('s:on_chan_exit_nvim'),
          \ })
  catch
    return 0
  endtry
  if type(chan) == v:t_number && chan > 0
    let s:chan = chan
    return 1
  endif
  return 0
endfunction"}}}

function! s:conn_send_nvim(text) abort"{{{
  try
    return chansend(s:chan, a:text) >= 0
  catch
    return 0
  endtry
endfunction"}}}

function! s:conn_alive_nvim() abort"{{{
  return s:chan != v:null
endfunction"}}}

function! s:conn_close_nvim() abort"{{{
  try
    call chanclose(s:chan)
  catch
  endtry
  let s:chan = v:null
endfunction"}}}

" --- Vim implementation ------------------------------------------------

function! s:out_cb_vim(channel, msg) abort"{{{
  call s:on_line(a:msg)
endfunction"}}}

function! s:exit_cb_vim(channel, msg) abort"{{{
  let s:chan = v:null
endfunction"}}}

function! s:conn_open_vim(addr, transport) abort"{{{
  let target = a:transport ==# 'unix' ? 'unix:' . a:addr : a:addr
  let chan = v:null
  try
    let chan = ch_open(target, {
          \ 'mode':     'nl',
          \ 'callback': function('s:out_cb_vim'),
          \ })
  catch
    return 0
  endtry
  if type(chan) == v:t_channel && ch_status(chan) ==# 'open'
    let s:chan = chan
    return 1
  endif
  return 0
endfunction"}}}

function! s:conn_send_vim(text) abort"{{{
  try
    call ch_sendraw(s:chan, a:text)
    return 1
  catch
    return 0
  endtry
endfunction"}}}

function! s:conn_alive_vim() abort"{{{
  try
    return ch_status(s:chan) ==# 'open'
  catch
    return 0
  endtry
endfunction"}}}

function! s:conn_close_vim() abort"{{{
  try
    call ch_close(s:chan)
  catch
  endtry
  let s:chan = v:null
endfunction"}}}

" --- Dispatchers ------------------------------------------------------

function! s:conn_open(addr, transport) abort"{{{
  return has('nvim')
        \ ? s:conn_open_nvim(a:addr, a:transport)
        \ : s:conn_open_vim(a:addr, a:transport)
endfunction"}}}

function! s:conn_send(text) abort"{{{
  if has('nvim')
    return s:conn_send_nvim(a:text)
  else
    return s:conn_send_vim(a:text)
  endif
endfunction"}}}

function! s:conn_alive() abort"{{{
  if s:chan is v:null
    return 0
  endif
  return has('nvim') ? s:conn_alive_nvim() : s:conn_alive_vim()
endfunction"}}}

function! s:conn_close() abort"{{{
  if s:chan is v:null
    return
  endif
  if has('nvim')
    call s:conn_close_nvim()
  else
    call s:conn_close_vim()
  endif
endfunction"}}}

" --- Endpoint & lifecycle ----------------------------------------------

function! s:tcp_addr() abort"{{{
  if !empty(get(g:, 'im_tcp_addr', ''))
    return g:im_tcp_addr
  endif
  if !empty($RIME_QUERY_TCP)
    return $RIME_QUERY_TCP
  endif
  return '127.0.0.1:18666'
endfunction"}}}

function! s:unix_socket_path() abort"{{{
  let v = get(g:, 'im_unix_socket', '')
  return empty(v) ? '' : expand(v)
endfunction"}}}

function! s:endpoint_unix() abort"{{{
  let path = s:unix_socket_path()
  if !empty(path)
    return ['unix', path]
  endif
  if !empty($XDG_RUNTIME_DIR)
    return ['unix', $XDG_RUNTIME_DIR . '/rime-query.sock']
  endif
  return ['unix', expand('~/.cache/rime-query.sock')]
endfunction"}}}

function! s:endpoint_windows() abort"{{{
  return ['tcp', s:tcp_addr()]
endfunction"}}}

function! s:endpoint() abort"{{{
  if has('win32') || has('win64')
    return s:endpoint_windows()
  endif
  return s:endpoint_unix()
endfunction"}}}

function! s:find_rime_bin() abort"{{{
  if exists('g:im_rime_bin')
    if executable(g:im_rime_bin)
      return g:im_rime_bin
    endif
    " echohl WarningMsg
    " echomsg '[IM]: g:im_rime_bin=' . g:im_rime_bin . ' not found, trying fallback'
    " echohl None
  endif
  let name = has('win32') || has('win64') ? 'rime-query.exe' : 'rime-query'
  if executable(name)
    return name
  endif
  let bin = s:plugin_root . '/cpp/build/' . name
  if executable(bin)
    return bin
  endif
  return name
endfunction"}}}

function! im#rime#init() abort"{{{
  let g:im_rime_bin = s:find_rime_bin()
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

function! s:spawn_daemon(addr) abort"{{{
  let args = [g:im_rime_bin, '--serve']
  if has('win32') || has('win64')
    call extend(args, ['--tcp', s:tcp_addr()])
  else
    call extend(args, ['--socket', a:addr])
  endif
  call extend(args, ['--idle-exit-ms', string(get(g:, 'im_idle_exit_ms', 60000))])
  if has('nvim')
    call jobstart(args, {'detach': v:true})
  else
    call job_start(args, {'stoponexit': ''})
  endif
endfunction"}}}

function! s:handshake_and_setup(sock) abort"{{{
  let resp = s:roundtrip({
        \ 'type': 'ping',
        \ 'app':  has('nvim') ? 'nvim' : 'vim',
        \ }, get(g:, 'im_handshake_timeout_ms', 800))
  if resp is v:null
    echohl WarningMsg
    echom '[IM] rime backend did not become ready in time: ' . a:sock
    echohl None
    call s:conn_close()
    return 0
  endif
  call s:start_heartbeat()
  call im#rime#apply_initial_options()
  return 1
endfunction"}}}

function! s:ensure_backend() abort"{{{
  let state = im#state#get()
  if s:conn_alive()
    if s:handshake_and_setup(s:endpoint()[1])
      let state.ready = 1
      silent! doautocmd User RimeIMReady
      return 1
    endif
    let state.ready = 0
    call s:conn_close()
  endif

  let [transport, addr] = s:endpoint()

  if s:conn_open(addr, transport)
    if s:handshake_and_setup(addr)
      let state.ready = 1
      silent! doautocmd User RimeIMReady
      return 1
    endif
    let state.ready = 0
    call s:conn_close()
  endif

  if !executable(g:im_rime_bin)
    echohl WarningMsg
    echomsg "[IM]: rime-query not found in PATH, please check your installation"
    echohl None
    return 0
  endif

  " 确保 socket 父目录存在（默认路径落在 ~/.cache 时首次需要创建）。
  if transport ==# 'unix'
    silent! call mkdir(fnamemodify(addr, ':h'), 'p')
  endif

  call s:spawn_daemon(addr)
  call s:start_connect_poll(addr, transport)
  return 0
endfunction"}}}

function! s:start_connect_poll(addr, transport) abort"{{{
  if s:connect_timer != -1
    call timer_stop(s:connect_timer)
  endif
  let s:connect_start = reltimefloat(reltime())
  let s:connect_addr = a:addr
  let s:connect_transport = a:transport
  let s:connect_timer = timer_start(50, function('s:connect_poll_tick'))
endfunction"}}}

function! s:connect_poll_tick(timer_id) abort"{{{
  let timeout_s = get(g:, 'im_connect_timeout_ms', 30000) / 1000.0
  let elapsed = reltimefloat(reltime()) - s:connect_start

  if elapsed >= timeout_s
    let s:connect_timer = -1
    echohl WarningMsg
    echom '[IM] failed to start rime backend: ' . g:im_rime_bin
    echohl None
    return
  endif

  if s:conn_open(s:connect_addr, s:connect_transport)
    let state = im#state#get()
    let s:connect_timer = -1
    if s:handshake_and_setup(s:connect_addr)
      let state.ready = 1
      silent! doautocmd User RimeIMReady
    else
      let state.ready = 0
    endif
    return
  endif

  " 继续轮询
  let s:connect_timer = timer_start(50, function('s:connect_poll_tick'))
endfunction"}}}

function! im#rime#start() abort"{{{
  let state = im#state#get()
  let state.ready = 0
  return s:ensure_backend()
endfunction"}}}

function! im#rime#stop() abort"{{{
  let state = im#state#get()
  let state.ready = 0
  call s:stop_heartbeat()
  if s:connect_timer != -1
    call timer_stop(s:connect_timer)
    let s:connect_timer = -1
  endif
  call s:conn_close()
endfunction"}}}

function! im#rime#shutdown() abort"{{{
  let state = im#state#get()
  let state.ready = 0
  call s:stop_heartbeat()
  if s:connect_timer != -1
    call timer_stop(s:connect_timer)
    let s:connect_timer = -1
  endif
  if s:chan isnot v:null && state.started
    try
      call s:roundtrip({'type': 'quit'}, 800)
    endtry
  endif
  call s:conn_close()
endfunction"}}}

function! s:roundtrip(request, timeout_ms) abort"{{{
  let s:next_id += 1
  let s:pending_id = s:next_id
  let request = extend(copy(a:request), {'id': s:pending_id})

  let s:resp_ready = 0
  let s:resp_buf   = ''
  call s:conn_send(json_encode(request) . "\n")

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

function! im#rime#call(request, timeout_ms) abort"{{{
  let state = im#state#get()
  if s:chan is v:null || !state.started || !state.ready
    return v:null
  endif

  let resp = s:roundtrip(a:request, a:timeout_ms)
  if resp isnot v:null
    return resp
  endif

  " 超时无答复, 断开重连（异步），本次请求丢弃
  call s:conn_close()
  let state.ready = 0
  call s:ensure_backend()
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

" --- Heartbeat -----------------------------------------------------------

function! s:daemon_died() abort"{{{
  call s:stop_heartbeat()
  let state = im#state#get()
  let state.ready = 0
  call s:conn_close()
  echomsg '[IM] rime backend lost ...'
  redrawstatus
endfunction"}}}

function! s:start_heartbeat() abort"{{{
  if has("nvim")
    return
  endif
  call s:stop_heartbeat()
  let s:heartbeat_timer = timer_start(
        \ get(g:, 'im_heartbeat_ms', 5000),
        \ function('s:heartbeat_tick'))
endfunction"}}}

function! s:stop_heartbeat() abort"{{{
  if has("nvim")
    return
  endif
  if s:heartbeat_timer != -1
    call timer_stop(s:heartbeat_timer)
    let s:heartbeat_timer = -1
  endif
endfunction"}}}

function! s:heartbeat_tick(timer_id) abort"{{{
  if !s:conn_alive()
    let s:heartbeat_timer = -1
    call s:daemon_died()
    return
  endif
  " 继续下一次心跳
  let s:heartbeat_timer = timer_start(
        \ get(g:, 'im_heartbeat_ms', 5000),
        \ function('s:heartbeat_tick'))
endfunction"}}}
