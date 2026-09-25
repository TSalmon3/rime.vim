function! s:pos_le(p1, p2) abort"{{{
  return a:p1[0] < a:p2[0] || (a:p1[0] == a:p2[0] && a:p1[1] <= a:p2[1])
endfunction"}}}

function! s:finish(first, last, open_len, close_len) abort"{{{
  let t = {'first_pos': a:first, 'last_pos': a:last, 'open_len': a:open_len, 'close_len': a:close_len}
  let pos = [line('.'), col('.')]
  return s:pos_le(a:first, pos) && s:pos_le(pos, a:last) ? t : {}
endfunction"}}}

function! s:inside(pos, t) abort"{{{
  return s:pos_le(a:t.first_pos, a:pos) && s:pos_le(a:pos, a:t.last_pos)
endfunction"}}}

function! s:mp_parse_pair(raw_add) abort"{{{
  if type(a:raw_add) != v:t_list || len(a:raw_add) != 2
    return []
  endif
  let open_char = substitute(a:raw_add[0], '\s\+$', '', '')
  let close_char = substitute(a:raw_add[1], '^\s\+', '', '')
  if strchars(open_char) != 1 || strchars(close_char) != 1 || open_char ==# close_char
    return []
  endif
  return [open_char, close_char]
endfunction"}}}

function! s:mp_find_closing(open_pos, open_char, close_char) abort"{{{
  let either_pat = '\V' . escape(a:open_char, '\') . '\|' . '\V' . escape(a:close_char, '\')
  let depth = 1
  let lnum = a:open_pos[0]
  let start = a:open_pos[1] - 1 + strlen(a:open_char)
  while lnum <= line('$')
    let scan_line = getline(lnum)
    while 1
      let m = matchstrpos(scan_line, either_pat, start)
      if m[0] ==# ''
        break
      endif
      if m[0] ==# a:open_char
        let depth += 1
      else
        let depth -= 1
        if depth == 0
          return [lnum, m[1]]
        endif
      endif
      let start = m[2]
    endwhile
    let lnum += 1
    let start = 0
  endwhile
  return []
endfunction"}}}

function! s:mp_spaced_lens(raw_add, open_char, close_char, open_pos, close_pos) abort"{{{
  let open_len = strlen(a:open_char)
  let close_len = strlen(a:close_char)
  if a:raw_add[0] =~# ' $'
    let oline = getline(a:open_pos[0])
    if strpart(oline, a:open_pos[1] - 1 + strlen(a:open_char), 1) ==# ' '
      let open_len += 1
    endif
  endif
  if a:raw_add[1] =~# '^ '
    let cline = getline(a:close_pos[0])
    if a:close_pos[1] > 0 && strpart(cline, a:close_pos[1] - 1, 1) ==# ' '
      let close_len += 1
    endif
  endif
  return [open_len, close_len]
endfunction"}}}

function! s:mp_step_before(open_pos) abort"{{{
  call cursor(a:open_pos[0], a:open_pos[1])
  let before = getpos('.')[1:2]
  silent! normal! h
  if getpos('.')[1:2] == before
    if a:open_pos[0] > 1
      call cursor(a:open_pos[0] - 1, col([a:open_pos[0] - 1, '$']))
      return 1
    endif
    return 0
  endif
  return 1
endfunction"}}}

function! im#surround#find#matchpair(ch) abort"{{{
  let cfg = im#surround#config#lookup(a:ch)
  let raw_add = empty(cfg) ? v:null : cfg.add
  let pair = s:mp_parse_pair(raw_add)
  if empty(pair)
    return {}
  endif
  let [open_char, close_char] = pair
  let open_pat = '\V' . escape(open_char, '\')
  let view = winsaveview()
  try
    let save = getpos('.')
    let open_pos = searchpos(open_pat, 'bcW')
    while open_pos != [0, 0]
      let close_hit = s:mp_find_closing(open_pos, open_char, close_char)
      if empty(close_hit)
        return {}
      endif
      let [close_lnum, close_idx] = close_hit
      call setpos('.', save)
      let [open_len, close_len] = s:mp_spaced_lens(raw_add, open_char, close_char, open_pos, close_hit)
      let close_end = [close_lnum, close_idx + strlen(close_char)]
      let hit = s:finish(open_pos, close_end, open_len, close_len)
      if !empty(hit)
        return hit
      endif
      if !s:mp_step_before(open_pos)
        return {}
      endif
      let open_pos = searchpos(open_pat, 'bcW')
    endwhile
    return {}
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

function! s:tag_selection() abort"{{{
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

function! s:tag_open_end(first) abort"{{{
  let oline = getline(a:first[0])
  let oi = a:first[1] - 1
  let n = strlen(oline)
  while oi < n
    let cell = strpart(oline, oi, 1)
    if cell ==# '"' || cell ==# "'"
      let oi = stridx(oline, cell, oi + 1)
      if oi < 0
        return -1
      endif
      let oi += 1
    elseif cell ==# '>'
      return oi
    else
      let oi += 1
    endif
  endwhile
  return -1
endfunction"}}}

function! s:tag_close_start(last) abort"{{{
  let cline = getline(a:last[0])
  let cs = strridx(cline, '<', a:last[1] - 1)
  if cs < 0 || strpart(cline, cs, 2) !=# '</'
    return -1
  endif
  return cs
endfunction"}}}

function! im#surround#find#tag(ch) abort"{{{
  let view = winsaveview()
  let vish = getpos("'<")
  let vist = getpos("'>")
  try
    let save = getpos('.')
    let sel = s:tag_selection()
    if empty(sel)
      call searchpos('>', 'bcW')
      let sel = s:tag_selection()
    endif
    if empty(sel)
      call setpos('.', save)
      return {}
    endif
    let [first, last] = sel
    let eidx = s:tag_open_end(first)
    if eidx < 0
      call setpos('.', save)
      return {}
    endif
    let cs = s:tag_close_start(last)
    if cs < 0
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
  let line_only = get(a:opt, 'scope', 'line') ==# 'line'
  let view = winsaveview()
  try
    let save = getpos('.')
    let lnum = line('.')
    if line_only
      let open_pos = searchpos(open_pat, 'bcW', lnum)
    else
      let open_pos = searchpos(open_pat, 'bcW')
    endif
    if open_pos == [0, 0]
      return {}
    endif
    let oline = getline(open_pos[0])
    let om = matchstrpos(oline, open_pat, open_pos[1] - 1)
    let open_len = om[0] !=# '' && om[1] == open_pos[1] - 1 ? strlen(om[0]) : 0
    if open_len <= 0
      return {}
    endif
    call cursor(open_pos[0], open_pos[1] + open_len)
    if line_only
      let close_pos = searchpos(close_pat, 'W', lnum)
    else
      let close_pos = searchpos(close_pat, 'W')
    endif
    if close_pos == [0, 0]
      return {}
    endif
    let cline = getline(close_pos[0])
    let cm = matchstrpos(cline, close_pat, close_pos[1] - 1)
    let close_len = cm[0] !=# '' && cm[1] == close_pos[1] - 1 ? strlen(cm[0]) : 0
    if close_len <= 0
      return {}
    endif
    call setpos('.', save)
    return s:finish(open_pos, [close_pos[0], close_pos[1] + close_len - 1], open_len, close_len)
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

function! im#surround#find#auto(ch) abort"{{{
  let self_mark = string(function('im#surround#find#auto'))
  let all = im#surround#config#surrounds()
  if type(all) != v:t_list
    return {}
  endif
  let view = winsaveview()
  try
    let cur = getpos('.')[1:2]
    let best = {}
    for entry in all
      call cursor(cur[0], cur[1])
      if type(entry) != v:t_dict
        continue
      endif
      let k = get(entry, 'key', '')
      if type(k) != v:t_string || k ==# '' || k ==# 'invalid_key_behavior'
        continue
      endif
      let cfg = im#surround#config#lookup(k)
      if empty(cfg) || type(get(cfg, 'find', v:null)) != v:t_func
        continue
      endif
      if string(cfg.find) ==# self_mark
        continue
      endif
      try
        let r = call(cfg.find, [k])
      catch
        continue
      endtry
      if type(r) != v:t_dict || !has_key(r, 'first_pos') || !has_key(r, 'last_pos')
        continue
      endif
      if empty(best)
        let best = r
      elseif s:inside(cur, best)
        if s:inside(cur, r)
              \ && s:pos_le(best.first_pos, r.first_pos)
              \ && s:pos_le(r.last_pos, best.last_pos)
          let best = r
        endif
      elseif s:pos_le(cur, best.first_pos)
        if s:inside(cur, r)
              \ || (s:pos_le(cur, r.first_pos) && s:pos_le(r.first_pos, best.first_pos))
          let best = r
        endif
      else
        if s:inside(cur, r) || s:pos_le(best.last_pos, r.last_pos)
          let best = r
        endif
      endif
    endfor
    if !empty(best) && !s:inside(cur, best)
      return {}
    endif
    return best
  finally
    call winrestview(view)
  endtry
endfunction"}}}
