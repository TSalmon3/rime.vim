function! s:redraw(ctx) abort"{{{
  let state = im#state#get()

  let lnum = line('.')
  let line = getline(lnum)

  " padding wtth space in virtcol mode
  let r = state.boundary - 1 - state.vpad
  let before = strpart(line, 0, r)
  let after  = strpart(line, r + state.vpad + state.preedit_len)
  call setline(lnum, before . repeat(' ', state.vpad) . a:ctx.preedit . after)

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

    " padding wtth space in virtcol mode
    let r = state.boundary - 1 - state.vpad
    let before = strpart(line, 0, r)
    let after = strpart(line, r + state.vpad + state.preedit_len)
    call setline(lnum, before . repeat(' ', state.vpad) . a:committed . after)

    call cursor(line('.'), state.boundary + strlen(a:committed))
  endif

  if mode() =~# '^[iR]'
    call complete(col('.'), [])
  endif

  let state.last_commit = a:committed
endfunction"}}}

function! im#engine#key(keycode, mask, ...) abort"{{{
  let state = im#state#get()
  let ctx = im#rime#key(a:keycode, a:mask)
  let fallback = a:0 ? a:1 : im#keymap#fallback(a:keycode, a:mask)

  call im#state#sync_notifications(ctx)

  " librime reject 上屏
  if !ctx.accepted
    let committed = get(ctx, 'committed', '')
    if !empty(committed)
      call s:commit_text(committed)
    endif
    call im#underline#clean()
    call im#state#reset_frontend()
    call im#state#reset_backend()
    let state.last_fallback = fallback
    silent! doautocmd User RimeIMCommit
    call feedkeys(fallback, 'ni')
    return
  else
    " 组词结束上屏
    let committed = get(ctx, 'committed', '')
    if !empty(committed) || !ctx.composing
      call s:commit_text(committed)
      call im#underline#clean()
      " 后端已干净（composing==false）时跳过 reset RTT；
      " 若仍在 composing（部分上屏不断句），仍需清后端以保持同步。
      call im#state#reset_frontend()
      if ctx.composing
        call im#state#reset_backend()
      endif
      silent! doautocmd User RimeIMCommit
      return
    endif
    " composing waiting input
    call s:redraw(ctx)
  endif

endfunction"}}}

function! im#engine#cancel() abort"{{{
  let state = im#state#get()
  if !im#state#composing()
    call im#state#reset_replace()
    return
  endif

  if im#replace#active()
    " R/gR：丢弃 preedit 并还原被覆盖的原文（覆盖渲染，上屏会吃掉原文）
    call im#underline#clean()
    call im#replace#discard()
    call im#state#reset_frontend()
    call im#state#reset_backend()
  else
    let ctx = im#rime#cancel()
    if !empty(get(ctx, 'input', ''))
      call s:commit_text(ctx.input)
    endif
    call im#underline#clean()
    call im#state#reset_frontend()
  endif
  call im#state#reset_replace()
endfunction"}}}

function! im#engine#ascii_switch(style) abort"{{{
  let state = im#state#get()
  let was_composing = im#state#composing()
  let ctx = im#rime#switch_ascii_mode(a:style)
  call im#state#sync_notifications(ctx)
  if !ctx.composing
    let committed = get(ctx, 'committed', '')
    if !empty(committed)
      call s:commit_text(committed)
    endif
    call im#underline#clean()
    call im#state#reset_frontend()
  else
    call s:redraw(ctx)
  endif
  redrawstatus
endfunction"}}}
