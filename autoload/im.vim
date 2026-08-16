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
  " let &keymap      = s:save_keymap
  " let &iminsert    = s:save_iminsert
  " let &imsearch    = s:save_imsearch
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
  augroup END
endfunction"}}}

function! s:clear_im_autocmd() abort"{{{
  augroup im_augroup
    autocmd!
  augroup END
endfunction"}}}

function! s:redraw(ctx) abort"{{{
  let state = im#state#get()

  let lnum = line('.')
  let line = getline(lnum)

  let before = strpart(line, 0, state.boundary - 1)
  let after  = strpart(line, state.boundary - 1 + state.preedit_len)
  call setline(lnum, before . a:ctx.preedit . after)

  let state.preedit_len = strlen(a:ctx.preedit)
  let state.cursor_pos  = a:ctx.cursor_pos
  let state.sel_start   = a:ctx.sel_start
  let state.sel_end     = a:ctx.sel_end

  call cursor(lnum, state.boundary + state.cursor_pos)

  let state.candidate_count = len(a:ctx.candidates)
  let words = map(copy(a:ctx.candidates), 'v:val.word')
  let norm_preedit = substitute(a:ctx.preedit, '\s', '', 'g')
  let candidates_changed = (words !=# get(state, 'last_candidates', []))
        \ || (norm_preedit !=# get(state, 'last_preedit', ''))
  if !empty(a:ctx.candidates)
    let result = []
    let i = 1
    for item in a:ctx.candidates
      let comment = empty(item.comment) ? '' : ' ' . item.comment
      call add(result, {
            \ 'word'  : item.word,
            \ 'abbr'  : i . ' ' . item.word . comment,
            \ 'menu'  : '[' . a:ctx.preedit . ']',
            \ 'dup'   : 1,
            \ 'empty' : 1,
            \ })
      let i += 1
    endfor
    if candidates_changed
      call complete(state.boundary, result)
      let idx = a:ctx.highlighted_candidate_index
      if idx > 0
        call feedkeys(repeat("\<down>", idx), 'ni')
      endif
    else
      let delta = a:ctx.highlighted_candidate_index - get(state, 'last_hl', 0)
      if delta > 0
        call feedkeys(repeat("\<down>", delta), 'ni')
      elseif delta < 0
        call feedkeys(repeat("\<up>", -delta), 'ni')
      endif
    endif
  else
    call complete(state.boundary, [])
  endif

  let state.last_candidates = words
  let state.last_preedit    = norm_preedit
  let state.last_hl         = a:ctx.highlighted_candidate_index

  call im#underline#render()
endfunction"}}}

function! s:commit_text(committed) abort"{{{
  let state = im#state#get()
  if im#replace#active()
    call im#replace#commit(a:committed)
  else
    let lnum = line('.')
    let line = getline(lnum)

    let before = strpart(line, 0, state.boundary - 1)
    let after = strpart(line, state.boundary - 1 + state.preedit_len)
    call setline(lnum, before . a:committed . after)

    call cursor(line('.'), state.boundary + strlen(a:committed))
  endif
  call complete(col('.'), [])
  call im#underline#clean()
  call im#state#reset_input()
  let state.last_commit = a:committed
endfunction"}}}

function! im#key(keycode, mask, ...) abort"{{{
  let state = im#state#get()
  let ctx = im#rime#key(a:keycode, a:mask)

  let fallback = a:0 ? a:1 : im#keymap#fallback(a:keycode, a:mask)

  call im#apply_option_changes(ctx)

  " librime reject 上屏
  if !ctx.accepted
    let committed = get(ctx, 'committed', '')
    if !empty(committed)
      call s:commit_text(committed)
      silent! doautocmd User RimeIMCommit
    else
      call im#underline#clean()
      call im#state#reset_input()
    endif
    call feedkeys(fallback, 'ni')
    silent! doautocmd User RimeIMFallBack
    return
  else
    " 组词结束上屏
    let committed = get(ctx, 'committed', '')
    if !empty(committed) || !ctx.composing
      call s:commit_text(committed)
      silent! doautocmd User RimeIMCommit
      return
    endif
    " composing waiting input
    call s:redraw(ctx)
  endif

endfunction"}}}

function! im#cancel() abort"{{{
  let state = im#state#get()
  if !im#state#composing()
    call im#state#reset_replace()
    return
  endif

  " if get(v:, 'insertmode', '') ==# 'r' || get(v:, 'insertmode', '') ==# 'v'
  "   call complete(col('.'), [])
  " endif

  call im#underline#clean()
  call im#rime#reset()
  call im#state#reset_input()
  call im#state#reset_replace()
endfunction"}}}

function! im#apply_option_changes(ctx) abort"{{{
  let state = im#state#get()
  let opt_changed = v:false
  let sch_changed = v:false

  let field_map = {
        \ 'ascii_mode'         : 'ascii_mode',
        \ 'ascii_punct'        : 'ascii_punct',
        \ 'traditionalization' : 'traditional',
        \ 'emoji'              : 'emoji',
        \ 'full_shape'         : 'full_shape',
        \ }
  for item in get(a:ctx, 'changed_options', [])
    let field = get(field_map, get(item, 'name', ''), '')
    if !empty(field) && get(state, field, -1) != (item.value ? 1 : 0)
      let state[field] = item.value ? 1 : 0
      let opt_changed = v:true
    endif
  endfor

  let schema_id = get(a:ctx, 'schema_id', '')
  let schema_dirty = v:false
  if !empty(schema_id) && schema_id !=# state.schema
    let state.schema = schema_id
    let schema_dirty = v:true
  endif
  if get(a:ctx, 'schema_changed', v:false)
    let sch_changed = v:true
  endif

  if opt_changed || schema_dirty
    redrawstatus
  endif
  if opt_changed
    silent! doautocmd User RimeOptionChanged
  endif
  if sch_changed
    silent! doautocmd User RimeSchemaChanged
  endif
endfunction"}}}

function! im#enable() abort"{{{
  let state = im#state#get()
  let &iminsert=1
  let &imsearch=0
  call im#keymap#setup()
  let state.boundary = -1
  let state.enabled = 1

  " Bug: lnoremap 没有生效
  function! s:Fix() abort
    let &iminsert = 1
  endfunction

  call timer_start(0, {-> s:Fix()})
endfunction"}}}

function! im#disable() abort"{{{
  let state = im#state#get()
  call im#cancel()
  " let &keymap = s:save_keymap
  " let &iminsert = s:save_iminsert
  " let &imsearch = s:save_imsearch
  call im#keymap#clear()
  let state.boundary = -1
  let state.enabled = 0
endfunction"}}}

function! im#start() abort"{{{
  let state = im#state#get()
  if state.started
    return
  endif
  let state.started = im#rime#start()
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
  elseif mode() =~# '^R'
    call im#enable()
    call im#replace#enter()
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
  call s:clear_im_autocmd()
  call im#disable()
  call s:vimrc_restore()
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

function! im#deploy() abort"{{{
  let state = im#state#get()
  if !state.started
    echohl WarningMsg
    echom '[IM] rime not started, run :IMStart first'
    echohl None
    return
  endif
  call im#cancel()
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
  redrawstatus
  return
endfunction"}}}

function! im#sync() abort"{{{
  let state = im#state#get()
  if !state.started
    echohl WarningMsg
    echom '[IM] rime not started, run :IMStart first'
    echohl None
    return
  endif
  call im#cancel()
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
  redrawstatus
  return
endfunction"}}}

function! im#on_insert_enter() abort"{{{
  let state = im#state#get()
  if state.started && !state.enabled
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
    call im#disable()
  endif
endfunction"}}}

function! im#status() abort"{{{
  let state = im#state#get()
  let icon = get(g:, 'im_status_text', 'ㄓ')
  let icon_half = get(g:, 'im_status_half_text', '半')
  let icon_full = get(g:, 'im_status_full_text', '全')
  let icon_simplified = get(g:, 'im_status_simplified_text', '简')
  let icon_traditional = get(g:, 'im_status_traditional_text', '繁')
  let icon_chinese = get(g:, 'im_status_chinese_text', '中')
  let icon_english = get(g:, 'im_status_english_text', '英')

  let icon_lock = get(g:, 'im_status_lock_text', '!')
  let mode = state.ascii_mode ? icon_english : icon_chinese
  let locked = state.locked ?  icon_lock : ""
  let punct = state.ascii_punct ? icon_half : icon_full
  let trad = state.traditional ? icon_traditional : icon_simplified
  return state.started ? locked . "[" . icon . "]" . mode . '|' . punct . '|' . trad  : ''
endfunction"}}}

function! im#schema() abort"{{{
  return im#state#get().schema
endfunction"}}}

