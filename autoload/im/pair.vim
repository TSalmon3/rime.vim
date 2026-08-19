let s:default_rules = [
      \ {'open': '(',  'close': ')',  'kind': 'delim'},
      \ {'open': '[',  'close': ']',  'kind': 'delim'},
      \ {'open': '{',  'close': '}',  'kind': 'delim'},
      \ {'open': '<',  'close': '>',  'kind': 'delim'},
      \ {'open': '（', 'close': '）', 'kind': 'delim'},
      \ {'open': '【', 'close': '】', 'kind': 'delim'},
      \ {'open': '「', 'close': '」', 'kind': 'delim'},
      \ {'open': '『', 'close': '』', 'kind': 'delim'},
      \ {'open': '《', 'close': '》', 'kind': 'delim'},
      \ {'open': "‘",  'close': "’",  'kind': 'delim'},
      \ {'open': "“",  'close': "”",  'kind': 'delim'},
      \ {'open': '"',  'close': '"',  'kind': 'quote'},
      \ {'open': "'",  'close': "'",  'kind': 'quote'},
      \ ]

let s:enabled = 0
let s:cached_bufnr = -1
let s:open_map  = {}
let s:close_map = {}
let s:quote_map = {}

augroup im_pair_cache
  autocmd!
  autocmd BufEnter,BufWinEnter,BufNewFile,BufRead,FileType * let s:cached_bufnr = -1
augroup END


function! s:role(ch) abort"{{{
  if has_key(s:open_map, a:ch)
    return {'kind': 'open', 'ch': a:ch, 'close': s:open_map[a:ch]}
  elseif has_key(s:close_map, a:ch)
    return {'kind': 'close', 'ch': a:ch}
  elseif has_key(s:quote_map, a:ch)
    return {'kind': 'quote', 'ch': a:ch}
  endif
  return {}
endfunction"}}}

function! s:char_at_cursor() abort"{{{
  let line = getline('.')
  return strcharpart(line, charidx(line, col('.') - 1), 1)
endfunction"}}}

function! s:opt(name, default) abort"{{{
  let bname = 'im_pair_' . a:name
  if has_key(b:, bname)
    return b:[bname]
  endif
  let gname = 'im_pair_' . a:name
  if has_key(g:, gname)
    return g:[gname]
  endif
  return a:default
endfunction"}}}

function! s:resolve() abort"{{{
  let s:enabled = s:opt('enabled', 0)
  let rules = s:opt('rules', s:default_rules)
  let s:open_map  = {}
  let s:close_map = {}
  let s:quote_map = {}
  for r in rules
    if type(r) != v:t_dict || !has_key(r, 'open') || !has_key(r, 'close')
      continue
    endif
    if get(r, 'kind', '') ==# 'quote'
      let s:quote_map[r.open] = 1
    else
      let s:open_map[r.open] = r.close
      let s:close_map[r.close] = 1
    endif
  endfor
endfunction"}}}

function! s:sync() abort"{{{
  if s:cached_bufnr != bufnr()
    call s:resolve()
    let s:cached_bufnr = bufnr()
  endif
endfunction"}}}

function! im#pair#refresh() abort"{{{
  let s:cached_bufnr = -1
endfunction"}}}

function! im#pair#jump(ch) abort"{{{
  call s:sync()
  if !s:enabled || im#replace#active()
    return 0
  endif
  let role = s:role(a:ch)
  if empty(role) || role.kind ==# 'open'
    return 0
  endif
  let next = s:char_at_cursor()
  if empty(next)
    return 0
  endif
  let nrole = s:role(next)
  return !empty(nrole) && nrole.kind !=# 'open' && next ==# a:ch
endfunction"}}}

function! im#pair#extra(text) abort"{{{
  call s:sync()
  if !s:enabled || im#replace#active()
    return ''
  endif
  if empty(a:text)
    return ''
  endif
  let ch = strcharpart(a:text, strchars(a:text) - 1, 1)
  let role = s:role(ch)
  if empty(role)
    return ''
  endif
  let next = s:char_at_cursor()
  if role.kind ==# 'open'
    return role.close . "\<Left>"
  elseif role.kind ==# 'quote'
    return next ==# ch ? "\<BS>" : ch . "\<Left>"
  else
    return ""
  endif
endfunction"}}}

function! im#pair#should_bs_pair() abort"{{{
  call s:sync()
  if !s:enabled || im#replace#active() || col('.') <= 1
    return 0
  endif
  let line   = getline('.')
  let cidx   = charidx(line, col('.') - 1)
  let before = strcharpart(line, cidx - 1, 1)
  let cur    = strcharpart(line, cidx, 1)
  if empty(cur)
    return 0
  endif
  let role = s:role(before)
  if empty(role)
    return 0
  endif
  if role.kind ==# 'open' && cur ==# role.close
    return 1
  elseif role.kind ==# 'quote' && cur ==# role.ch
    return 1
  endif
  return 0
endfunction"}}}

function! im#pair#bs() abort"{{{
  return "\<BS>\<Del>"
endfunction"}}}

function! im#pair#should_jump() abort"{{{
  call s:sync()
  if !s:enabled || im#replace#active() || im#state#composing()
    return 0
  endif
  let next = s:char_at_cursor()
  if empty(next)
    return 0
  endif
  let nrole = s:role(next)
  return !empty(nrole) && nrole.kind !=# 'open'
endfunction"}}}

function! im#pair#jump_any() abort"{{{
  return im#pair#should_jump() ? "\<Right>" : ''
endfunction"}}}

function! im#pair#jump_many() abort"{{{
  call s:sync()
  if !s:enabled || im#replace#active() || im#state#composing()
    return ''
  endif
  let line = getline('.')
  let cidx = charidx(line, col('.') - 1)
  let clen = strchars(line)
  let n = 0
  while cidx + n < clen
    let r = s:role(strcharpart(line, cidx + n, 1))
    if empty(r) || r.kind ==# 'open'
      break
    endif
    let n += 1
  endwhile
  return n > 0 ? repeat("\<Right>", n) : ''
endfunction"}}}

function! im#pair#toggle() abort"{{{
  let state = im#state#get()
  if !state.started
    return
  endif
  if !get(g:, 'im_pair_enabled', 0)
    let g:im_pair_enabled = 1
  else
    let g:im_pair_enabled = 0
  endif
  call im#pair#refresh()
  call s:sync()
  echom '[IM] auto-pair ' . (s:enabled ? 'on' : 'off')
endfunction"}}}
