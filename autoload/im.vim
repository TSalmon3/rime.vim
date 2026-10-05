function! s:vimrc_save() abort"{{{
  let s:save_completeopt = &completeopt
  let s:save_pumheight   = &pumheight
  let s:save_iminsert    = &iminsert
  let s:save_imsearch    = &imsearch
  let s:save_keymap      = &keymap
endfunction"}}}

function! s:vimrc_setup() abort"{{{
  set completeopt=menuone,noinsert
  let &pumheight = get(g:, 'im_pumheight', 9)
  " set keymap=
  " set iminsert=1
  " set imsearch=0
endfunction"}}}

function! s:vimrc_restore() abort"{{{
  let &completeopt = s:save_completeopt
  let &pumheight   = s:save_pumheight
  let &keymap = s:save_keymap
  let &iminsert = s:save_iminsert
  let &imsearch = s:save_imsearch
endfunction"}}}

function! s:setup_im_autocmd() abort"{{{
  augroup im_augroup
    autocmd!
    autocmd InsertEnter * call im#on_insert_enter()
    autocmd InsertChange * call im#on_insert_change()
    autocmd InsertLeave * call im#on_insert_leave()
    autocmd CursorMovedI * call im#replace#on_cursor_moved()

    autocmd InsertEnter * call im#context#on_enter()
    autocmd CursorMovedI * call im#context#update()
    autocmd InsertLeave * call im#context#on_leave()
    autocmd InsertEnter * call im#pair#on_enter()
    autocmd InsertLeave * call im#pair#on_leave()
    autocmd InsertEnter * call im#pair#imap_enter()
    autocmd InsertLeave * call im#pair#imap_leave()
  augroup END
endfunction"}}}

function! s:clear_im_autocmd() abort"{{{
  augroup im_augroup
    autocmd!
  augroup END
endfunction"}}}

function! im#enable() abort"{{{
  call im#state#reset_frontend()
  let state = im#state#get()
  let state.enabled = 1
  call im#keymap#setup()
  set iminsert=1
  set imsearch=0
endfunction"}}}

function! im#disable() abort"{{{
  call im#engine#reset()
  call im#keymap#clear()
  let state = im#state#get()
  let state.enabled = 0
  set iminsert=0
  set imsearch=0
  call im#state#reset_frontend()
endfunction"}}}

function! im#start() abort"{{{
  let state = im#state#get()
  if state.started && state.ready
    return
  endif
  let state.started = 1
  call im#rime#start()
  return
endfunction"}}}

function! im#on_ready() abort"{{{
  let state = im#state#get()
  if !state.started
    return
  endif

  silent! doautocmd User RimeIMEnable
  call im#state#init()
  call s:setup_im_autocmd()
  call s:vimrc_save()
  call s:vimrc_setup()

  if mode() == "i"
    call im#enable()
    call im#context#on_enter()
    call im#pair#on_enter()
  elseif mode() =~# '^R'
    call im#enable()
    call im#replace#enter()
    call im#context#on_enter()
    call im#pair#on_enter()
  endif

  echo '[IM] on'
  redrawstatus
  return
endfunction"}}}

function! im#stop() abort"{{{
  let state = im#state#get()
  if !state.started
    return
  endif
  if state.ready
    call s:clear_im_autocmd()
    call im#disable()
    call im#pair#on_leave()
  endif
  let state.started = 0
  silent! doautocmd User RimeIMDisable
  echo '[IM] off'
  redrawstatus
  return
endfunction"}}}

function! im#toggle() abort"{{{
  let state = im#state#get()
  if state.started
    call im#stop()
  else
    call im#start()
  endif
  return
endfunction"}}}

function! im#toggle_insert() abort"{{{
  let state = im#state#get()
  if !state.started
    call im#toggle()
    return state.started ? nr2char(30) : ''
  endif
  call timer_start(0, {-> im#toggle()})
  return nr2char(30)
endfunction"}}}

function! im#deploy() abort"{{{
  let state = im#state#get()
  if !state.started || !state.ready
    echohl WarningMsg
    echom '[IM] rime not started or still connecting, run :IMStart first'
    echohl None
    return
  endif
  let status = im#rime#deploy()
  if status ==# 'success'
    echo '[IM] deploy success'
  elseif status ==# 'failure'
    echohl ErrorMsg
    echom '[IM] deploy failed, check rime log'
    echohl None
  else
    echohl WarningMsg
    echom '[IM] deploy timed out or backend not responding'
    echohl None
  endif
  call im#state#init()
  if status ==# 'success'
    call im#rime#warmup()
  endif
  redrawstatus
endfunction"}}}

function! im#sync() abort"{{{
  let state = im#state#get()
  if !state.started || !state.ready
    echohl WarningMsg
    echom '[IM] rime not started or still connecting, run :IMStart first'
    echohl None
    return
  endif
  let status = im#rime#sync()
  if status ==# 'success'
    echo '[IM] sync + deploy success'
  elseif status ==# 'failure'
    echohl ErrorMsg
    echom '[IM] sync or deploy failed, check rime log'
    echohl None
  else
    echohl WarningMsg
    echom '[IM] sync timed out or backend not responding'
    echohl None
  endif
  call im#state#init()
  if status ==# 'success'
    call im#rime#warmup()
  endif
  redrawstatus
endfunction"}}}

function! im#on_insert_enter() abort"{{{
  let state = im#state#get()
  if state.started && state.ready && !state.enabled
    call im#enable()
  endif

  if get(v:, 'insertmode', '') ==# 'r' || get(v:, 'insertmode', '') ==# 'v'
    call im#replace#enter()
  endif
endfunction"}}}

function! im#on_insert_change() abort"{{{
  if get(v:, 'insertmode', '') ==# 'r' || get(v:, 'insertmode', '') ==# 'v'
    call im#replace#enter()
  else
    call im#replace#leave()
  endif
endfunction"}}}

function! im#on_insert_leave() abort"{{{
  let state = im#state#get()
  if state.started && state.enabled
    call timer_start(0, {-> im#disable()})
  endif
endfunction"}}}

function! im#status() abort"{{{
  let state = im#state#get()
  let icon = get(g:, 'im_status_text', 'ㄓ')
  let icon_half = get(g:, 'im_status_half_text', '半')
  let icon_full = get(g:, 'im_status_full_text', '全')
  let icon_chinese = get(g:, 'im_status_chinese_text', '中')
  let icon_english = get(g:, 'im_status_english_text', '英')
  let icon_lmap = get(g:, 'im_status_lmap_text', 'L')
  let icon_imap = get(g:, 'im_status_imap_text', 'I')
  let icon_disconnect = get(g:, 'im_status_disconnect', '断')
  " let icon_lock = get(g:, 'im_status_lock_text', '锁')

  " let locked = state.locked ?  icon_lock : ""
  let mode = get(state.switches, 'ascii_mode', 0) ? icon_english : icon_chinese
  let punct = get(state.switches, 'ascii_punct', 0) ? icon_half : icon_full
  let lang = &iminsert ? icon_lmap : icon_imap
  let connect = state.ready ? "" : icon_disconnect
  return state.started ? connect . "[" . icon . "]" . mode . '|' . punct . '|' . lang : ''
endfunction"}}}
