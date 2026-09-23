let s:default_config = {
      \ 'markdown': {
      \   'ts': ['fenced_code_block', 'indented_code_block', 'code_span',
      \     'link_destination', 'link_title', 'uri_autolink', 'email_autolink',
      \     'html_block'],
      \   'syntax': [],
      \   'rules': im#typeset#rule#default_rules()},
      \ }

function! im#typeset#config() abort"{{{
  let all = get(g:, 'im_typeset_config', s:default_config)
  if type(all) != v:t_dict
    return {}
  endif
  let ft = &filetype
  if empty(ft) || !has_key(all, ft)
    return {}
  endif
  let raw = all[ft]
  if type(raw) != v:t_dict
    return {}
  endif
  let rules = get(raw, 'rules', [])
  if type(rules) != v:t_list || empty(rules)
    return {}
  endif
  let ts = []
  for pat in get(raw, 'ts', [])
    if type(pat) == v:t_string && !empty(pat)
      call add(ts, tolower(pat))
    endif
  endfor
  let syntax = []
  for pat in get(raw, 'syntax', [])
    if type(pat) == v:t_string && !empty(pat)
      call add(syntax, tolower(pat))
    endif
  endfor
  return {'ts': ts, 'syntax': syntax, 'rules': rules}
endfunction"}}}

function! im#typeset#is_enabled() abort"{{{
  let all = get(g:, 'im_typeset_config', s:default_config)
  if type(all) != v:t_dict
    return 0
  endif
  let ft = &filetype
  if empty(ft) || !has_key(all, ft)
    return 0
  endif
  let raw = all[ft]
  if type(raw) != v:t_dict
    return 0
  endif
  let rules = get(raw, 'rules', [])
  return type(rules) == v:t_list && !empty(rules)
endfunction"}}}

function! s:ts_map(bufnr, l1, l2, pats) abort"{{{
  if empty(a:pats) || !has('nvim')
    return {}
  endif
  try
    let m = luaeval("require('im.typeset').protected_map(_A[1], _A[2], _A[3], _A[4])",
          \ [a:bufnr, a:l1, a:l2, a:pats])
    return type(m) == v:t_dict ? m : {}
  catch
    return {}
  endtry
endfunction"}}}

function! s:syntax_hit(lnum, col, pats) abort"{{{
  for id in synstack(a:lnum, a:col)
    let lname = tolower(synIDattr(id, 'name'))
    if empty(lname)
      continue
    endif
    for pat in a:pats
      if stridx(lname, pat) >= 0
        return 1
      endif
    endfor
  endfor
  return 0
endfunction"}}}

function! s:syntax_intervals(lnum, line, pats) abort"{{{
  if empty(a:pats) || empty(&syntax)
    return []
  endif
  let out = []
  let len = strlen(a:line)
  let c = 1
  while c <= len
    if !s:syntax_hit(a:lnum, c, a:pats)
      let c += 1
      continue
    endif
    let s0 = c - 1
    while c <= len && s:syntax_hit(a:lnum, c, a:pats)
      let c += 1
    endwhile
    call add(out, [s0, c - 1])
  endwhile
  return out
endfunction"}}}

function! s:merge(intervals) abort"{{{
  if empty(a:intervals)
    return []
  endif
  let sorted = sort(copy(a:intervals), {a, b -> a[0] == b[0] ? a[1] - b[1] : a[0] - b[0]})
  let out = [copy(sorted[0])]
  for iv in sorted[1:]
    if iv[0] <= out[-1][1]
      let out[-1][1] = max([out[-1][1], iv[1]])
    else
      call add(out, copy(iv))
    endif
  endfor
  return out
endfunction"}}}

function! s:invert(len, merged) abort"{{{
  let out = []
  let pos = 0
  for iv in a:merged
    if iv[0] > pos
      call add(out, [pos, iv[0]])
    endif
    let pos = max([pos, iv[1]])
  endfor
  if pos < a:len
    call add(out, [pos, a:len])
  endif
  return out
endfunction"}}}

function! im#typeset#apply_chain(text, ctx, entry) abort"{{{
  if empty(a:entry)
    return a:text
  endif
  let s = a:text
  for F in a:entry.rules
    if type(F) != v:t_func
      continue
    endif
    try
      let s = F(a:ctx, s)
    catch
    endtry
    if type(s) != v:t_string
      let s = a:text
      break
    endif
  endfor
  return s
endfunction"}}}

function! im#typeset#text(text) abort"{{{
  let entry = im#typeset#config()
  let ctx = {'filetype': &filetype,
        \ 'bufnr': bufnr('%'), 'bufname': bufname('%'), 'lnum': -1,
        \ 'left_char': '', 'right_char': ''}
  return im#typeset#apply_chain(a:text, ctx, entry)
endfunction"}}}

function! s:base_ctx(lnum) abort"{{{
  return {'filetype': &filetype,
        \ 'bufnr': bufnr('%'), 'bufname': bufname('%'), 'lnum': a:lnum,
        \ 'left_char': '', 'right_char': ''}
endfunction"}}}

function! s:line_gaps(lnum, line, tsmap, syntax) abort"{{{
  let prot = []
  if has_key(a:tsmap, a:lnum)
    call extend(prot, deepcopy(a:tsmap[a:lnum]))
  endif
  call extend(prot, s:syntax_intervals(a:lnum, a:line, a:syntax))
  return s:invert(strlen(a:line), s:merge(prot))
endfunction"}}}

function! s:first_char(s) abort"{{{
  return a:s ==# '' ? '' : strcharpart(a:s, 0, 1)
endfunction"}}}

function! s:last_char(s) abort"{{{
  let n = strchars(a:s)
  return n == 0 ? '' : strcharpart(a:s, n - 1, 1)
endfunction"}}}

function! s:rebuild(line, gaps, parts) abort"{{{
  let new = ''
  let pos = 0
  let i = 0
  for gap in a:gaps
    if gap[0] > pos
      let new .= strpart(a:line, pos, gap[0] - pos)
    endif
    let new .= a:parts[i]
    let pos = gap[1]
    let i += 1
  endfor
  if pos < strlen(a:line)
    let new .= strpart(a:line, pos)
  endif
  return new
endfunction"}}}

function! s:format_line(lnum, tsmap, entry) abort"{{{
  if empty(a:entry)
    return 0
  endif
  let line = getline(a:lnum)
  if line ==# ''
    return 0
  endif
  let gaps = s:line_gaps(a:lnum, line, a:tsmap, a:entry.syntax)
  if empty(gaps)
    return 0
  endif
  let parts = []
  let len = strlen(line)
  for gap in gaps
    let seg = strpart(line, gap[0], gap[1] - gap[0])
    let ctx = s:base_ctx(a:lnum)
    let ctx.left_char = gap[0] == 0 ? '' : s:last_char(strpart(line, 0, gap[0]))
    let ctx.right_char = gap[1] >= len ? '' : s:first_char(strpart(line, gap[1]))
    call add(parts, im#typeset#apply_chain(seg, ctx, a:entry))
  endfor
  let new = s:rebuild(line, gaps, parts)
  if new ==# line
    return 0
  endif
  call setline(a:lnum, new)
  return 1
endfunction"}}}

function! s:format_line_force(lnum, entry) abort"{{{
  if empty(a:entry)
    return 0
  endif
  let line = getline(a:lnum)
  if line ==# ''
    return 0
  endif
  let ctx = s:base_ctx(a:lnum)
  let new = im#typeset#apply_chain(line, ctx, a:entry)
  if new ==# line
    return 0
  endif
  call setline(a:lnum, new)
  return 1
endfunction"}}}

function! s:snapshot_cursor(line) abort"{{{
  let at_eol = col('.') > strlen(a:line)
  let cidx = charidx(a:line, col('.') - 1)
  if cidx < 0
    let cidx = strchars(a:line)
  endif
  return [at_eol, cidx]
endfunction"}}}

function! s:restore_cursor(lnum, at_eol, cidx) abort"{{{
  let new = getline(a:lnum)
  if a:at_eol
    call cursor(a:lnum, strlen(new) + 1)
    return
  endif
  let keep = min([a:cidx, strchars(new)])
  let nb = keep <= 0 ? 0 : byteidx(new, keep)
  if nb < 0
    let nb = strlen(new)
  endif
  call cursor(a:lnum, nb + 1)
endfunction"}}}

function! im#typeset#line() abort"{{{
  let entry = im#typeset#config()
  if empty(entry)
    return 0
  endif
  let lnum = line('.')
  let line = getline(lnum)
  let [at_eol, cidx] = s:snapshot_cursor(line)
  let tsmap = s:ts_map(bufnr('%'), lnum, lnum, entry.ts)
  let changed = s:format_line(lnum, tsmap, entry)
  if changed
    call s:restore_cursor(lnum, at_eol, cidx)
  endif
  return changed
endfunction"}}}

function! im#typeset#line_force() abort"{{{
  let entry = im#typeset#config()
  if empty(entry)
    return 0
  endif
  let lnum = line('.')
  let line = getline(lnum)
  let [at_eol, cidx] = s:snapshot_cursor(line)
  let changed = s:format_line_force(lnum, entry)
  if changed
    call s:restore_cursor(lnum, at_eol, cidx)
  endif
  return changed
endfunction"}}}

function! im#typeset#range(l1, l2) abort"{{{
  let entry = im#typeset#config()
  if empty(entry)
    return 0
  endif
  let l1 = max([1, a:l1])
  let l2 = min([line('$'), a:l2])
  if l1 > l2
    let [l1, l2] = [l2, l1]
  endif
  let save_re = &regexpengine
  let save_gd = &gdefault
  let save_pos = getpos('.')
  let &regexpengine = 2
  set nogdefault
  try
    let tsmap = s:ts_map(bufnr('%'), l1, l2, entry.ts)
    let n = 0
    let lnum = l1
    while lnum <= l2
      let n += s:format_line(lnum, tsmap, entry)
      let lnum += 1
    endwhile
  finally
    let &regexpengine = save_re
    if save_gd
      set gdefault
    endif
    call setpos('.', save_pos)
    if col('.') > strlen(getline('.')) + 1
      call cursor(line('.'), strlen(getline('.')) + 1)
    endif
  endtry
  return n
endfunction"}}}

function! im#typeset#range_force(l1, l2) abort"{{{
  let entry = im#typeset#config()
  if empty(entry)
    return 0
  endif
  let l1 = max([1, a:l1])
  let l2 = min([line('$'), a:l2])
  if l1 > l2
    let [l1, l2] = [l2, l1]
  endif
  let save_re = &regexpengine
  let save_gd = &gdefault
  let save_pos = getpos('.')
  let &regexpengine = 2
  set nogdefault
  try
    let n = 0
    let lnum = l1
    while lnum <= l2
      let n += s:format_line_force(lnum, entry)
      let lnum += 1
    endwhile
  finally
    let &regexpengine = save_re
    if save_gd
      set gdefault
    endif
    call setpos('.', save_pos)
    if col('.') > strlen(getline('.')) + 1
      call cursor(line('.'), strlen(getline('.')) + 1)
    endif
  endtry
  return n
endfunction"}}}

function! im#typeset#buffer() abort"{{{
  return im#typeset#range(1, line('$'))
endfunction"}}}

function! im#typeset#on_insert_leave() abort"{{{
  if !get(g:, 'im_typeset_insert_leave', 0)
    return 0
  endif
  if !im#typeset#is_enabled() || mode(1) =~# '^[iR]'
    return 0
  endif
  if exists('*im#state#composing') && im#state#composing()
    return 0
  endif
  return im#typeset#line()
endfunction"}}}

function! im#typeset#on_save() abort"{{{
  if !im#typeset#is_enabled()
    return 0
  endif
  return im#typeset#buffer()
endfunction"}}}
