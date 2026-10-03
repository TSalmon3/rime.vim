highlight Preedit gui=underline cterm=underline

let s:cache = {
      \ 'last_candidates' : [],
      \ 'last_preedit'    : '',
      \ 'last_hl'         : 0,
      \ }

let s:hl = {
      \ 'match_id' : 0,
      \ }

function! im#view#reset_cache() abort"{{{
  let s:cache.last_candidates = []
  let s:cache.last_preedit = ''
  let s:cache.last_hl = 0
endfunction"}}}

function! s:put(text) abort"{{{
  let state = im#state#get()
  let lnum = line('.')
  let line = getline(lnum)
  let r = state.boundary - 1 - state.vpad
  let before = strpart(line, 0, r)
  let after = strpart(line, r + state.vpad + state.preedit_len)
  call setline(lnum, before . repeat(' ', state.vpad) . a:text . after)
  return lnum
endfunction"}}}

function! s:show_candidates(ctx) abort"{{{
  let state = im#state#get()
  let words = map(copy(a:ctx.candidates), 'v:val.word')
  let norm_preedit = substitute(a:ctx.preedit, '\s', '', 'g')
  let changed = (words !=# s:cache.last_candidates)
        \ || (norm_preedit !=# s:cache.last_preedit)
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
    if changed
      call complete(state.boundary, result)
      let idx = a:ctx.highlighted_candidate_index
      if idx > 0
        call feedkeys(repeat("\<down>", idx), 'ni')
      endif
    else
      let delta = a:ctx.highlighted_candidate_index - s:cache.last_hl
      if delta > 0
        call feedkeys(repeat("\<down>", delta), 'ni')
      elseif delta < 0
        call feedkeys(repeat("\<up>", -delta), 'ni')
      endif
    endif
  else
    call complete(state.boundary, [])
  endif
  let s:cache.last_candidates = words
  let s:cache.last_preedit = norm_preedit
  let s:cache.last_hl = a:ctx.highlighted_candidate_index
endfunction"}}}

function! im#view#render(ctx) abort"{{{
  let state = im#state#get()
  call s:put(a:ctx.preedit)
  let state.preedit = a:ctx.preedit
  let state.preedit_len = strlen(a:ctx.preedit)
  let state.cursor_pos = a:ctx.cursor_pos
  let state.sel_start = a:ctx.sel_start
  let state.sel_end = a:ctx.sel_end
  let state.candidate_count = len(a:ctx.candidates)
  let state.has_more = get(a:ctx, 'has_more', v:false)
  call cursor(line('.'), state.boundary + state.cursor_pos)
  call s:show_candidates(a:ctx)
  call s:render_hl()
endfunction"}}}

function! im#view#commit_text(committed) abort"{{{
  let state = im#state#get()
  if im#replace#active()
    call im#replace#commit(a:committed)
  elseif state.boundary >= 0
    call s:put(a:committed)
    call cursor(line('.'), state.boundary + strlen(a:committed))
  endif
  if mode() =~# '^[iR]'
    call complete(col('.'), [])
  endif
  let state.last_commit = a:committed
endfunction"}}}

" keymap#r 单字符替换（非组合路径），charidx 语义与组合路径不同，单列于此。
function! im#view#replace_char(out) abort"{{{
  let lnum = line('.')
  let line = getline(lnum)
  let cidx = charidx(line, col('.') - 1)
  let before = strcharpart(line, 0, cidx)
  let after = strcharpart(line, cidx + 1)
  call setline(lnum, before . a:out . after)
  call cursor(lnum, byteidx(before, strchars(before)) + 1)
endfunction"}}}

function! im#view#clear() abort"{{{
  call s:clean_hl()
endfunction"}}}

function! s:render_hl() abort"{{{
  if exists('g:im_underline_disable') && g:im_underline_disable
    return
  endif
  let state = im#state#get()
  if s:hl.match_id != 0
    silent! call matchdelete(s:hl.match_id)
    let s:hl.match_id = 0
  endif
  if state.boundary < 0 || state.preedit_len <= 0
    return
  endif
  let lnum = line('.')
  let s:hl.match_id = matchaddpos('Preedit',
        \ [[lnum, state.boundary, state.preedit_len]])
endfunction"}}}

function! s:clean_hl() abort"{{{
  if exists('g:im_underline_disable') && g:im_underline_disable
    return
  endif
  if s:hl.match_id != 0
    silent! call matchdelete(s:hl.match_id)
    let s:hl.match_id = 0
  endif
endfunction"}}}
