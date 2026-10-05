function! im#engine#key(keycode, mask, ...) abort"{{{
  let state = im#state#get()
  let ctx = im#rime#key(a:keycode, a:mask)
  let fallback = a:0 ? a:1 : im#keymap#fallback(a:keycode, a:mask)

  call im#state#emit(im#state#sync_notifications(ctx))

  " librime reject 上屏
  if !ctx.accepted
    call im#view#commit_text(get(ctx, 'committed', ''))
    call im#view#clear()
    call im#state#reset_frontend()
    call im#state#emit(im#state#reset_backend())
    let state.last_fallback = fallback
    silent! doautocmd User RimeIMCommit
    call feedkeys(fallback, 'ni')
    return
  endif
  " 组词结束上屏
  let committed = get(ctx, 'committed', '')
  if !empty(committed) || !ctx.composing
    call im#view#commit_text(committed)
    call im#view#clear()
    call im#state#reset_frontend()
    if ctx.composing
      call im#state#emit(im#state#reset_backend())
    endif
    silent! doautocmd User RimeIMCommit
    return
  endif
  " composing waiting input
  call im#view#render(ctx)
endfunction"}}}

function! im#engine#reset() abort"{{{
  if !im#state#composing()
    call im#replace#reset()
    return
  endif

  if im#replace#active()
    " R/gR：丢弃 preedit 并还原被覆盖的原文（覆盖渲染，上屏会吃掉原文）
    call im#view#clear()
    call im#replace#discard()
    call im#state#reset_frontend()
    call im#state#emit(im#state#reset_backend())
  else
    let ctx = im#rime#cancel()
    call im#state#emit(im#state#sync_notifications(ctx))
    call im#view#commit_text(get(ctx, 'input', ''))
    call im#view#clear()
    call im#state#reset_frontend()
  endif
  call im#replace#reset()
endfunction"}}}

function! im#engine#ascii_switch(style) abort"{{{
  let ctx = im#rime#switch_ascii_mode(a:style)
  call im#state#emit(im#state#sync_notifications(ctx))
  if !ctx.composing
    call im#view#commit_text(get(ctx, 'committed', ''))
    call im#view#clear()
    call im#state#reset_frontend()
  else
    call im#view#render(ctx)
  endif
  redrawstatus
endfunction"}}}

function! im#engine#toggle_ascii_mode() abort"{{{
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
  let state.switches['ascii_mode'] = value ? 1 : 0
  redrawstatus
endfunction"}}}

function! im#engine#toggle_ascii_punct() abort"{{{
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
  let state.switches['ascii_punct'] = value ? 1 : 0
  redrawstatus
endfunction"}}}
