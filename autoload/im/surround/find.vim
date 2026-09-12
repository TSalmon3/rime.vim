function! s:pos_le(p1, p2) abort"{{{
  return a:p1[0] < a:p2[0] || (a:p1[0] == a:p2[0] && a:p1[1] <= a:p2[1])
endfunction"}}}

function! s:finish(first, last, open_len, close_len) abort"{{{
  let t = {'first_pos': a:first, 'last_pos': a:last, 'open_len': a:open_len, 'close_len': a:close_len}
  let pos = [line('.'), col('.')]
  return s:pos_le(a:first, pos) && s:pos_le(pos, a:last) ? t : {}
endfunction"}}}

function! im#surround#find#matchpair(ch) abort"{{{
  let cfg = im#surround#config#lookup(a:ch)
  let Add = empty(cfg) ? v:null : cfg.add
  if type(Add) != v:t_list || len(Add) != 2
    return {}
  endif
  let best_open = substitute(Add[0], '\s\+$', '', '')
  let best_close = substitute(Add[1], '^\s\+', '', '')
  if strchars(best_open) != 1 || strchars(best_close) != 1 || best_open ==# best_close
    return {}
  endif
  let view = winsaveview()
  try
    let save = getpos('.')

    let opat = '\V' . escape(best_open, '\')
    let opos = searchpos(opat, 'bcW')
    if opos == [0, 0]
      return {}
    endif

    let cpat = '\V' . escape(best_close, '\')
    let bpat = opat . '\|' . cpat
    let depth = 1
    let lnum = opos[0]
    let start = opos[1] - 1 + strlen(best_open)
    let cidx = -1
    let clnum = -1
    while lnum <= line('$')
      let scan_line = getline(lnum)
      while 1
        let m = matchstrpos(scan_line, bpat, start)
        if m[0] ==# ''
          break
        endif
        if m[0] ==# best_open
          let depth += 1
        else
          let depth -= 1
          if depth == 0
            let cidx = m[1]
            let clnum = lnum
            break
          endif
        endif
        let start = m[2]
      endwhile
      if cidx >= 0
        break
      endif
      let lnum += 1
      let start = 0
    endwhile
    if cidx < 0
      return {}
    endif
    call setpos('.', save)
    let open_len = strlen(best_open)
    let close_len = strlen(best_close)
    if Add[0] =~# ' $'
      let oline = getline(opos[0])
      if strpart(oline, opos[1] - 1 + strlen(best_open), 1) ==# ' '
        let open_len += 1
      endif
    endif
    if Add[1] =~# '^ '
      let cline = getline(clnum)
      if cidx > 0 && strpart(cline, cidx - 1, 1) ==# ' '
        let close_len += 1
      endif
    endif
    return s:finish([opos[0], opos[1]], [clnum, cidx + strlen(best_close)], open_len, close_len)
  finally
    call winrestview(view)
  endtry
endfunction"}}}

function! im#surround#find#quote(ch) abort"{{{
  if strchars(a:ch) != 1
    return {}
  endif
  let view = winsaveview()
  try
    let save = getpos('.')
    let lnum = line('.')
    let pat = '\V' . escape(a:ch, '\')
    let opos = searchpos(pat, 'bW', lnum)
    if opos == [0, 0]
      let opos = searchpos(pat, 'cW', lnum)
      if opos == [0, 0]
        return {}
      endif
    endif
    call cursor(opos[0], opos[1] + strlen(a:ch))
    let cpos = searchpos(pat, 'W', lnum)
    if cpos == [0, 0]
      return {}
    endif
    call setpos('.', save)
    return s:finish(opos, [cpos[0], cpos[1] + strlen(a:ch) - 1], strlen(a:ch), strlen(a:ch))
  finally
    call winrestview(view)
  endtry
endfunction"}}}

function! s:try_at() abort"{{{
  let before = [getpos("'<"), getpos("'>")]
  silent! execute "normal! vat\<Esc>"
  let after = [getpos("'<"), getpos("'>")]
  if after == before
    return []
  endif
  let first = after[0][1:2]
  let last = after[1][1:2]
  return s:pos_le(first, last) ? [first, last] : []
endfunction"}}}

function! im#surround#find#tag(ch) abort"{{{
  let view = winsaveview()
  let vish = getpos("'<")
  let vist = getpos("'>")
  try
    let save = getpos('.')
    let sel = s:try_at()
    if empty(sel)
      call searchpos('>', 'bcW')
      let sel = s:try_at()
    endif
    if empty(sel)
      call setpos('.', save)
      return {}
    endif
    let [first, last] = sel
    let oline = getline(first[0])
    let oi = first[1] - 1
    let n = strlen(oline)
    let eidx = -1
    while oi < n
      let ch = strpart(oline, oi, 1)
      if ch ==# '"' || ch ==# "'"
        let oi = stridx(oline, ch, oi + 1)
        if oi < 0
          break
        endif
        let oi += 1
      elseif ch ==# '>'
        let eidx = oi
        break
      else
        let oi += 1
      endif
    endwhile
    if eidx < 0
      call setpos('.', save)
      return {}
    endif
    let cline = getline(last[0])
    let cs = strridx(cline, '<', last[1] - 1)
    if cs < 0 || strpart(cline, cs, 2) !=# '</'
      call setpos('.', save)
      return {}
    endif
    call setpos('.', save)
    return s:finish(first, last, eidx - first[1] + 2, last[1] - cs)
  finally
    call setpos("'<", vish)
    call setpos("'>", vist)
    call winrestview(view)
  endtry
endfunction"}}}

function! im#surround#find#func(ch) abort"{{{
  let open_pat = '[^= \t(){}]\+('
  let view = winsaveview()
  try
    let save = getpos('.')
    call setpos('.', save)
    let opos = searchpos(open_pat, 'bcW')
    while opos != [0, 0]
      let oline = getline(opos[0])
      let om = matchstrpos(oline, open_pat, opos[1] - 1)
      if om[0] !=# '' && om[1] == opos[1] - 1
        let open_len = strlen(om[0])
        call cursor(opos[0], opos[1] + open_len - 1)
        let ketpos = searchpairpos('(', '', ')', 'W')
        if ketpos != [0, 0]
          call setpos('.', save)
          let t = s:finish([opos[0], opos[1]], [ketpos[0], ketpos[1]], open_len, 1)
          if !empty(t)
            return t
          endif
        endif
      endif
      if opos[1] > 1
        call cursor(opos[0], opos[1] - 1)
      elseif opos[0] > 1
        call cursor(opos[0] - 1, col([opos[0] - 1, '$']))
      else
        break
      endif
      let opos = searchpos(open_pat, 'bW')
    endwhile
    call setpos('.', save)
    return {}
  finally
    call winrestview(view)
  endtry
endfunction"}}}

function! im#surround#find#invalid(ch) abort"{{{
  if strchars(a:ch) != 1 || a:ch =~# '[\x00-\x1f\x7f]'
    return {}
  endif
  let view = winsaveview()
  try
    let save = getpos('.')
    let pat = '\V' . escape(a:ch, '\')
    let opos = searchpos(pat, 'bcW')
    if opos == [0, 0]
      return {}
    endif
    call cursor(opos[0], opos[1] + strlen(a:ch))
    let cpos = searchpos(pat, 'W')
    if cpos == [0, 0]
      return {}
    endif
    call setpos('.', save)
    return s:finish(opos, [cpos[0], cpos[1] + strlen(a:ch) - 1], strlen(a:ch), strlen(a:ch))
  finally
    call winrestview(view)
  endtry
endfunction"}}}

function! im#surround#find#pattern(ch, opt) abort"{{{
  let open_pat = get(a:opt, 'open_pat', '')
  let close_pat = get(a:opt, 'close_pat', '')
  if type(open_pat) != v:t_string || empty(open_pat)
        \ || type(close_pat) != v:t_string || empty(close_pat)
    return {}
  endif
  let scope = get(a:opt, 'scope', 'line')
  let line_only = scope ==# 'line'
  let view = winsaveview()
  try
    let save = getpos('.')
    let lnum = line('.')

    if line_only
      let opos = searchpos(open_pat, 'bcW', lnum)
    else
      let opos = searchpos(open_pat, 'bcW')
    endif
    if opos == [0, 0]
      return {}
    endif
    let oline = getline(opos[0])
    let om = matchstrpos(oline, open_pat, opos[1] - 1)
    let open_len = om[0] !=# '' && om[1] == opos[1] - 1 ? strlen(om[0]) : 0
    if open_len <= 0
      return {}
    endif
    call cursor(opos[0], opos[1] + open_len)
    if line_only
      let cpos = searchpos(close_pat, 'W', lnum)
    else
      let cpos = searchpos(close_pat, 'W')
    endif
    if cpos == [0, 0]
      return {}
    endif
    let cline = getline(cpos[0])
    let cm = matchstrpos(cline, close_pat, cpos[1] - 1)
    let close_len = cm[0] !=# '' && cm[1] == cpos[1] - 1 ? strlen(cm[0]) : 0
    if close_len <= 0
      return {}
    endif
    call setpos('.', save)
    return s:finish(opos, [cpos[0], cpos[1] + close_len - 1], open_len, close_len)
  finally
    call winrestview(view)
  endtry
endfunction"}}}

function! im#surround#find#func_ts(ch) abort"{{{
  if !has('nvim')
    return {}
  endif
  try
    let r = luaeval("require('im.surround').func_range()")
  catch
    return {}
  endtry
  if type(r) != v:t_dict || !has_key(r, 'first_pos') || !has_key(r, 'last_pos')
        \ || !has_key(r, 'open_len') || !has_key(r, 'close_len')
    return {}
  endif
  return s:finish(r.first_pos, r.last_pos, r.open_len, r.close_len)
endfunction"}}}

function! im#surround#find#tag_ts(ch) abort"{{{
  if !has('nvim')
    return {}
  endif
  try
    let r = luaeval("require('im.surround').tag_range()")
  catch
    return {}
  endtry
  if type(r) != v:t_dict || !has_key(r, 'first_pos') || !has_key(r, 'last_pos')
        \ || !has_key(r, 'open_len') || !has_key(r, 'close_len')
    return {}
  endif
  return s:finish(r.first_pos, r.last_pos, r.open_len, r.close_len)
endfunction"}}}
