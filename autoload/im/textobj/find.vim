function! s:char_at(pos) abort"{{{
  if empty(a:pos) || a:pos[0] < 1 || a:pos[0] > line('$')
    return ''
  endif
  let line = getline(a:pos[0])
  let idx = a:pos[1] - 1
  if idx < 0 || idx >= strlen(line)
    return ''
  endif
  return matchstr(strpart(line, idx), '^.')
endfunction"}}}

function! s:pos_lt(p1, p2) abort"{{{
  return a:p1[0] < a:p2[0] || (a:p1[0] == a:p2[0] && a:p1[1] < a:p2[1])
endfunction"}}}

function! s:pos_le(p1, p2) abort"{{{
  return a:p1[0] < a:p2[0] || (a:p1[0] == a:p2[0] && a:p1[1] <= a:p2[1])
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

function! s:pair_target(spec, open_pos, close_pos) abort"{{{
  let open_len = strlen(a:spec.open)
  let close_len = strlen(a:spec.close)
  return {
        \ 'kind': 'pair',
        \ 'open_len': open_len,
        \ 'close_len': close_len,
        \ 'open_pos': a:open_pos,
        \ 'close_pos': a:close_pos,
        \ 'around_start': a:open_pos,
        \ 'around_end': a:close_pos,
        \ 'inner_start': s:pos_skip(a:open_pos, open_len),
        \ 'inner_end': s:pos_prev(a:close_pos),
        \ }
endfunction"}}}

function! s:quote_target(spec, open_pos, close_pos) abort"{{{
  let len = strlen(a:spec.quote)
  return {
        \ 'kind': 'quote',
        \ 'open_len': len,
        \ 'close_len': len,
        \ 'open_pos': a:open_pos,
        \ 'close_pos': a:close_pos,
        \ 'around_start': a:open_pos,
        \ 'around_end': a:close_pos,
        \ 'inner_start': s:pos_skip(a:open_pos, len),
        \ 'inner_end': s:pos_prev(a:close_pos),
        \ }
endfunction"}}}

function! s:separator_target(spec, open_pos, close_pos) abort"{{{
  let sep_len = strlen(a:spec.sep)
  let inner_end = s:pos_prev(a:close_pos)
  return {
        \ 'kind': 'separator',
        \ 'open_len': sep_len,
        \ 'close_len': sep_len,
        \ 'open_pos': a:open_pos,
        \ 'close_pos': a:close_pos,
        \ 'around_start': a:open_pos,
        \ 'around_end': inner_end,
        \ 'inner_start': s:pos_skip(a:open_pos, sep_len),
        \ 'inner_end': inner_end,
        \ }
endfunction"}}}

function! s:pair_enclosing_open(cursor, open, close) abort"{{{
  let ch = s:char_at(a:cursor)
  if ch ==# a:open
    return a:cursor
  endif
  let open_pat = '\V' . escape(a:open, '\')
  let close_pat = '\V' . escape(a:close, '\')
  call cursor(a:cursor)
  let p = searchpairpos(open_pat, '', close_pat, 'bW')
  return p == [0, 0] ? [] : p
endfunction"}}}

function! s:pair_matching_close(open_pos, open, close) abort"{{{
  let open_pat = '\V' . escape(a:open, '\')
  let close_pat = '\V' . escape(a:close, '\')
  call cursor(a:open_pos)
  let p = searchpairpos(open_pat, '', close_pat, 'W')
  if p == [0, 0] || s:pos_lt(p, a:open_pos)
    return []
  endif
  return p
endfunction"}}}

function! s:pair_outer_open(spec, open, count) abort"{{{
  let open = a:open
  for _ in range(max([a:count - 1, 0]))
    let before = s:pos_prev(open)
    if empty(before)
      return []
    endif
    let prev = s:pair_enclosing_open(before, a:spec.open, a:spec.close)
    if empty(prev) || !s:pos_lt(prev, open)
      return []
    endif
    let open = prev
  endfor
  return open
endfunction"}}}

function! s:pair_current(spec, count) abort"{{{
  let cursor = getpos('.')[1:2]
  let open = s:pair_enclosing_open(cursor, a:spec.open, a:spec.close)
  if empty(open)
    return {}
  endif
  let open = s:pair_outer_open(a:spec, open, a:count)
  if empty(open)
    return {}
  endif
  let close = s:pair_matching_close(open, a:spec.open, a:spec.close)
  if empty(close)
    return {}
  endif
  let target = s:pair_target(a:spec, open, close)
  if !s:pos_le(target.around_start, cursor)
        \ || !s:pos_le(cursor, target.around_end)
    return {}
  endif
  return target
endfunction"}}}

function! s:pair_next(spec) abort"{{{
  let open_pat = '\V' . escape(a:spec.open, '\')
  let open = searchpos(open_pat, 'cW')
  if open == [0, 0]
    return {}
  endif
  let close = s:pair_matching_close(open, a:spec.open, a:spec.close)
  if empty(close)
    return {}
  endif
  return s:pair_target(a:spec, open, close)
endfunction"}}}

function! s:escaped_at(line, idx) abort"{{{
  if empty(&quoteescape)
    return 0
  endif
  let n = 0
  let i = a:idx - 1
  while i >= 0
    let ch = strpart(a:line, i, 1)
    if stridx(&quoteescape, ch) < 0
      break
    endif
    let n += 1
    let i -= 1
  endwhile
  return n % 2
endfunction"}}}

function! s:search_window() abort"{{{
  let n = get(g:, 'im_textobj_search_lines', 50)
  if type(n) != v:t_number
    let n = 50
  endif
  if n < 0
    return [1, line('$')]
  endif
  let lnum = line('.')
  return [max([1, lnum - n]), min([line('$'), lnum + n])]
endfunction"}}}

function! s:quote_line_positions(quote) abort"{{{
  let line = getline('.')
  let pat = '\V' . escape(a:quote, '\')
  let out = []
  let pos = 0
  while 1
    let m = matchstrpos(line, pat, pos)
    if m[0] ==# ''
      break
    endif
    if !s:escaped_at(line, m[1])
      call add(out, m[1] + 1)
    endif
    let pos = max([m[2], m[1] + 1])
  endwhile
  return out
endfunction"}}}

function! s:quote_line_pairs(quote) abort"{{{
  let lnum = line('.')
  let positions = s:quote_line_positions(a:quote)
  let pairs = []
  let i = 0
  while i + 1 < len(positions)
    call add(pairs, [[lnum, positions[i]], [lnum, positions[i + 1]]])
    let i += 2
  endwhile
  return pairs
endfunction"}}}

function! s:search_unescaped(char, flags, stopline) abort"{{{
  let pat = '\V' . escape(a:char, '\')
  while 1
    let pos = searchpos(pat, a:flags, a:stopline)
    if pos == [0, 0]
      return []
    endif
    if !s:escaped_at(getline(pos[0]), pos[1] - 1)
      return pos
    endif
  endwhile
endfunction"}}}

function! s:quote_find_left(quote, pos, lo) abort"{{{
  call cursor(a:pos)
  return s:search_unescaped(a:quote, 'bW', a:lo)
endfunction"}}}

function! s:quote_find_right(quote, pos, hi) abort"{{{
  call cursor(a:pos)
  return s:search_unescaped(a:quote, 'W', a:hi)
endfunction"}}}

function! s:quote_pick(spec, candidates, cursor) abort"{{{
  let best = {}
  let best_size = 0
  for pair in a:candidates
    if !s:pos_le(pair[0], a:cursor) || !s:pos_le(a:cursor, pair[1])
      continue
    endif
    let target = s:quote_target(a:spec, pair[0], pair[1])
    let size = s:range_size(target)
    if empty(best) || size < best_size
      let best = target
      let best_size = size
    endif
  endfor
  return best
endfunction"}}}

function! s:quote_current(spec, lo, hi) abort"{{{
  let cursor = getpos('.')[1:2]
  for pair in s:quote_line_pairs(a:spec.quote)
    if s:pos_le(pair[0], cursor) && s:pos_le(cursor, pair[1])
      return s:quote_target(a:spec, pair[0], pair[1])
    endif
  endfor

  let positions = s:quote_line_positions(a:spec.quote)
  let candidates = []
  if empty(positions)
    let left = s:quote_find_left(a:spec.quote, cursor, a:lo)
    let right = s:quote_find_right(a:spec.quote, cursor, a:hi)
    if !empty(left) && !empty(right)
      call add(candidates, [left, right])
    endif
  elseif len(positions) == 1
    let lone = [line('.'), positions[0]]
    let left = s:quote_find_left(a:spec.quote, lone, a:lo)
    let right = s:quote_find_right(a:spec.quote, lone, a:hi)
    if !empty(left)
      call add(candidates, [left, lone])
    endif
    if !empty(right)
      call add(candidates, [lone, right])
    endif
  endif
  return s:quote_pick(a:spec, candidates, cursor)
endfunction"}}}

function! s:quote_next(spec, lo, hi) abort"{{{
  let cursor = getpos('.')[1:2]
  for pair in s:quote_line_pairs(a:spec.quote)
    if s:pos_lt(cursor, pair[0])
      return s:quote_target(a:spec, pair[0], pair[1])
    endif
  endfor

  let open = s:quote_find_right(a:spec.quote, cursor, a:hi)
  if empty(open)
    return {}
  endif
  let close = s:quote_find_right(a:spec.quote, open, a:hi)
  if empty(close)
    return {}
  endif
  return s:quote_target(a:spec, open, close)
endfunction"}}}

function! s:quote_last(spec, lo, hi) abort"{{{
  let cursor = getpos('.')[1:2]
  let local = {}
  for pair in s:quote_line_pairs(a:spec.quote)
    if s:pos_lt(pair[1], cursor)
      let local = pair
    endif
  endfor
  if !empty(local)
    return s:quote_target(a:spec, local[0], local[1])
  endif

  let close = s:quote_find_left(a:spec.quote, cursor, a:lo)
  if empty(close)
    return {}
  endif
  let open = s:quote_find_left(a:spec.quote, close, a:lo)
  if empty(open)
    return {}
  endif
  return s:quote_target(a:spec, open, close)
endfunction"}}}

function! s:separator_left(sep, cursor, lo) abort"{{{
  if s:char_at(a:cursor) ==# a:sep
    return a:cursor
  endif
  call cursor(a:cursor)
  let pat = '\V' . escape(a:sep, '\')
  let pos = searchpos(pat, 'bcW', a:lo)
  return pos == [0, 0] ? [] : pos
endfunction"}}}

function! s:separator_right(sep, hi) abort"{{{
  let pat = '\V' . escape(a:sep, '\')
  let pos = searchpos(pat, 'W', a:hi)
  return pos == [0, 0] ? [] : pos
endfunction"}}}

function! s:separator_current(spec, count, lo, hi) abort"{{{
  let cursor = getpos('.')[1:2]
  let left = s:separator_left(a:spec.sep, cursor, a:lo)
  if empty(left)
    return {}
  endif
  call cursor(cursor)
  let right = s:separator_right(a:spec.sep, a:hi)
  if empty(right)
    return {}
  endif
  for _ in range(max([a:count - 1, 0]))
    let next = s:separator_right(a:spec.sep, a:hi)
    if empty(next)
      return {}
    endif
    let right = next
  endfor
  return s:separator_target(a:spec, left, right)
endfunction"}}}

function! s:separator_next(spec, lo, hi) abort"{{{
  let pat = '\V' . escape(a:spec.sep, '\')
  let base = searchpos(pat, 'cW', a:hi)
  if base == [0, 0]
    return {}
  endif
  let close = searchpos(pat, 'W', a:hi)
  if close == [0, 0]
    return {}
  endif
  return s:separator_target(a:spec, base, close)
endfunction"}}}

function! s:separator_last(spec, lo, hi) abort"{{{
  let pat = '\V' . escape(a:spec.sep, '\')
  let right = searchpos(pat, 'bcW', a:lo)
  if right == [0, 0]
    return {}
  endif
  let left = searchpos(pat, 'bW', a:lo)
  if left == [0, 0]
    return {}
  endif
  return s:separator_target(a:spec, left, right)
endfunction"}}}

function! s:find_by_kind(spec, which, count) abort"{{{
  let view = winsaveview()
  try
    if a:spec.kind ==# 'pair'
      if a:which ==# 'n'
        return s:pair_next(a:spec)
      endif
      return s:pair_current(a:spec, a:count)
    elseif a:spec.kind ==# 'quote'
      let [lo, hi] = s:search_window()
      if a:which ==# 'n'
        return s:quote_next(a:spec, lo, hi)
      elseif a:which ==# 'l'
        return s:quote_last(a:spec, lo, hi)
      endif
      return s:quote_current(a:spec, lo, hi)
    elseif a:spec.kind ==# 'separator'
      let [lo, hi] = s:search_window()
      if a:which ==# 'n'
        return s:separator_next(a:spec, lo, hi)
      elseif a:which ==# 'l'
        return s:separator_last(a:spec, lo, hi)
      endif
      return s:separator_current(a:spec, a:count, lo, hi)
    endif
    return {}
  finally
    call winrestview(view)
  endtry
endfunction"}}}

function! s:contains(target, pos) abort"{{{
  return s:pos_le(a:target.open_pos, a:pos)
        \ && s:pos_le(a:pos, a:target.close_pos)
endfunction"}}}

function! s:range_size(target) abort"{{{
  let start = a:target.open_pos
  let end = a:target.close_pos
  return (end[0] - start[0]) * 100000 + (end[1] - start[1])
endfunction"}}}

function! s:distance(target, pos) abort"{{{
  let start = a:target.open_pos
  let end = a:target.close_pos
  if s:contains(a:target, a:pos)
    return 0
  endif
  let p = s:pos_lt(a:pos, start) ? start : end
  return abs(p[0] - a:pos[0]) * 100000 + abs(p[1] - a:pos[1])
endfunction"}}}

function! s:innermost(targets, pos) abort"{{{
  let best = {}
  let best_size = 0
  for target in a:targets
    if !s:contains(target, a:pos)
      continue
    endif
    let size = s:range_size(target)
    if empty(best) || size < best_size
      let best = target
      let best_size = size
    endif
  endfor
  return best
endfunction"}}}

function! s:nearest(targets, pos) abort"{{{
  let best = {}
  let best_dist = 0
  for target in a:targets
    let dist = s:distance(target, a:pos)
    if empty(best) || dist < best_dist
      let best = target
      let best_dist = dist
    endif
  endfor
  return best
endfunction"}}}

function! im#textobj#find#find_target(specs, count) abort"{{{
  if empty(a:specs)
    return {}
  endif
  let cursor = getpos('.')[1:2]
  let found = []
  for spec in a:specs
    let t = s:find_by_kind(spec, 'c', a:count)
    if !empty(t)
      call add(found, t)
    endif
  endfor

  let best = s:innermost(found, cursor)
  if !empty(best)
    return best
  endif

  let nearby = []
  for spec in a:specs
    if spec.kind ==# 'pair'
      if a:count > 1
        continue
      endif
      let t = s:find_by_kind(spec, 'n', 1)
      if !empty(t)
        call add(nearby, t)
      endif
    else
      for which in ['n', 'l']
        let t = s:find_by_kind(spec, which, 1)
        if !empty(t)
          call add(nearby, t)
        endif
      endfor
    endif
  endfor
  return s:nearest(nearby, cursor)
endfunction"}}}
