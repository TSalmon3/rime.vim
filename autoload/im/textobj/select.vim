function! s:pos_lt(p1, p2) abort"{{{
  return a:p1[0] < a:p2[0] || (a:p1[0] == a:p2[0] && a:p1[1] < a:p2[1])
endfunction"}}}

function! s:pos_skip(pos, len) abort"{{{
  if empty(a:pos)
    return []
  endif
  let [l, c] = a:pos
  let line = getline(l)
  let idx = c - 1 + a:len
  if idx < strlen(line)
    return [l, idx + 1]
  endif
  if l < line('$')
    return [l + 1, 1]
  endif
  return []
endfunction"}}}

function! s:pos_prev(pos) abort"{{{
  if empty(a:pos)
    return []
  endif
  let [l, c] = a:pos
  if c > 1
    let line = getline(l)
    let before = strpart(line, 0, c - 1)
    let ch = matchstr(before, '.$')
    if !empty(ch)
      return [l, c - strlen(ch)]
    endif
  endif
  if l > 1
    let last = getline(l - 1)
    let n = strchars(last)
    if n <= 0
      return [l - 1, 1]
    endif
    return [l - 1, byteidx(last, n - 1) + 1]
  endif
  return []
endfunction"}}}

function! s:trim_inner(target) abort"{{{
  let start = a:target.inner_start
  let end = a:target.inner_end
  if empty(start) || empty(end) || s:pos_lt(end, start)
    return {}
  endif
  let view = winsaveview()
  try
    call cursor(start)
    let ns = searchpos('\S', 'cW')
    if ns == [0, 0] || s:pos_lt(end, ns)
      return {}
    endif
    call cursor(end)
    let ne = searchpos('\S', 'bcW')
    if ne == [0, 0] || s:pos_lt(ne, start)
      return {}
    endif
    let target = copy(a:target)
    let target.inner_start = ns
    let target.inner_end = ne
    return target
  finally
    call winrestview(view)
  endtry
endfunction"}}}

function! s:expand_around(target) abort"{{{
  let target = copy(a:target)
  let start = target.around_start
  let end = target.around_end

  let after = s:pos_skip(end, target.close_len)
  if !empty(after) && after[0] == end[0]
    let line = getline(after[0])
    let rest = strpart(line, after[1] - 1)
    let ws = matchstr(rest, '^\s*')
    if !empty(ws)
      let n = strchars(ws)
      let target.around_end = [after[0], after[1] + byteidx(ws, n - 1)]
      return target
    endif
  endif

  let before = s:pos_prev(start)
  if !empty(before) && before[0] == start[0]
    let line = getline(start[0])
    let prefix = strpart(line, 0, start[1] - 1)
    let ws = matchstr(prefix, '\s*$')
    if !empty(ws)
      let target.around_start = [start[0], start[1] - strlen(ws)]
    endif
  endif
  return target
endfunction"}}}

function! s:expand_separator_around(target) abort"{{{
  let target = copy(a:target)
  let start = target.open_pos
  let end = target.close_pos
  let target.around_end = end

  let after = s:pos_skip(end, target.close_len)
  if empty(after) || after[0] != end[0]
    return target
  endif
  let rest = strpart(getline(after[0]), after[1] - 1)
  let ws = matchstr(rest, '^\s*')
  if empty(ws)
    return target
  endif

  let before = s:pos_prev(start)
  if empty(before) || before[0] != start[0]
    return target
  endif
  let prefix = strpart(getline(start[0]), 0, start[1] - 1)
  if prefix !~# '\S\s\+$'
    return target
  endif

  let target.around_end = [after[0], after[1] + byteidx(ws, strchars(ws) - 1)]
  return target
endfunction"}}}

function! im#textobj#select#range(target, modifier) abort"{{{
  if empty(a:target)
    return {}
  endif
  if a:modifier ==# 'I'
    let target = s:trim_inner(a:target)
    if empty(target)
      return {}
    endif
    let start = target.inner_start
    let end = target.inner_end
  elseif a:modifier ==# 'A'
    if a:target.kind ==# 'separator'
      let target = s:expand_separator_around(a:target)
    else
      let target = s:expand_around(a:target)
    endif
    let start = target.around_start
    let end = target.around_end
  elseif a:modifier ==# 'a'
    let start = a:target.around_start
    let end = a:target.around_end
  else
    let start = a:target.inner_start
    let end = a:target.inner_end
  endif
  if empty(start) || empty(end) || s:pos_lt(end, start)
    return {}
  endif
  return {'start': start, 'end': end}
endfunction"}}}

function! im#textobj#select#apply(range, mode) abort"{{{
  if empty(a:range)
    return 0
  endif
  if a:mode ==# 'x'
    silent! execute "normal! \<Esc>"
  endif
  let selection = &selection
  let whichwrap = &whichwrap
  try
    set selection=inclusive
    set whichwrap=b,s
    call cursor(a:range.start)
    silent! execute 'normal! v'
    call cursor(a:range.end)
    if selection ==# 'exclusive'
      silent! execute 'normal! l'
    endif
  finally
    let &selection = selection
    let &whichwrap = whichwrap
  endtry
  return 1
endfunction"}}}
