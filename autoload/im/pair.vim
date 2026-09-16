let s:default_rules = [
      \ {'open': '(',  'close': ')',  'kind': 'matchpair'},
      \ {'open': '[',  'close': ']',  'kind': 'matchpair'},
      \ {'open': '{',  'close': '}',  'kind': 'matchpair'},
      \ {'open': '（', 'close': '）', 'kind': 'matchpair'},
      \ {'open': '【', 'close': '】', 'kind': 'matchpair'},
      \ {'open': '「', 'close': '」', 'kind': 'matchpair'},
      \ {'open': '『', 'close': '』', 'kind': 'matchpair'},
      \ {'open': '《', 'close': '》', 'kind': 'matchpair'},
      \ {'open': "‘",  'close': "’",  'kind': 'matchpair'},
      \ {'open': "“",  'close': "”",  'kind': 'matchpair'},
      \ {'open': '"',  'close': '"',  'kind': 'quote'},
      \ {'open': "'",  'close': "'",  'kind': 'quote'},
      \ ]

let s:default_config = {
      \ '*': {'syntax': [], 'ts': []},
      \ }

function! s:opt_g(name, default) abort"{{{
  let gname = 'im_pair_' . a:name
  if has_key(g:, gname)
    return g:[gname]
  endif
  return a:default
endfunction"}}}

function! s:single(raw) abort"{{{
  return type(a:raw) == v:t_string && strchars(a:raw) == 1 ? a:raw : ''
endfunction"}}}

function! s:rules() abort"{{{
  let raw = has_key(b:, 'im_pair_rules') ? b:im_pair_rules
        \ : s:opt_g('rules', s:default_rules)
  if type(raw) != v:t_list
    return []
  endif
  let ok = []
  for r in raw
    if type(r) != v:t_dict
      continue
    endif
    let open = s:single(get(r, 'open', ''))
    let close = s:single(get(r, 'close', ''))
    if empty(open) || empty(close)
      continue
    endif
    call add(ok, {'open': open, 'close': close, 'kind': get(r, 'kind', '')})
  endfor
  return ok
endfunction"}}}

function! im#pair#on_enter() abort"{{{
  let open_map  = {}
  let close_map = {}
  let quote_map = {}
  for r in s:rules()
    if type(r) != v:t_dict || !has_key(r, 'open') || !has_key(r, 'close')
      continue
    endif
    if get(r, 'kind', '') ==# 'quote'
      let quote_map[r.open] = 1
    else
      let open_map[r.open] = r.close
      let close_map[r.close] = 1
    endif
  endfor
  let b:im_pair_open_map  = open_map
  let b:im_pair_close_map = close_map
  let b:im_pair_quote_map = quote_map
endfunction"}}}

function! im#pair#on_leave() abort"{{{
  unlet! b:im_pair_open_map b:im_pair_close_map b:im_pair_quote_map
endfunction"}}}

function! s:classify(ch) abort"{{{
  let open_map = get(b:, 'im_pair_open_map', {})
  if has_key(open_map, a:ch)
    return {'kind': 'open', 'ch': a:ch, 'close': open_map[a:ch]}
  elseif has_key(get(b:, 'im_pair_close_map', {}), a:ch)
    return {'kind': 'close', 'ch': a:ch}
  elseif has_key(get(b:, 'im_pair_quote_map', {}), a:ch)
    return {'kind': 'quote', 'ch': a:ch}
  endif
  return {}
endfunction"}}}

function! s:char_at_cursor() abort"{{{
  let line = getline('.')
  return strcharpart(line, charidx(line, col('.') - 1), 1)
endfunction"}}}

function! s:normalize_entry(raw) abort"{{{
  let dflt = {'disabled': 0, 'ts': [], 'syntax': []}
  if type(a:raw) != v:t_dict
    return dflt
  endif
  let ts = get(a:raw, 'ts', [])
  let syntax = get(a:raw, 'syntax', [])
  if type(ts) != v:t_list
    let ts = []
  endif
  if type(syntax) != v:t_list
    let syntax = []
  endif
  return {'disabled': !!get(a:raw, 'disabled', 0), 'ts': ts, 'syntax': syntax}
endfunction"}}}

function! im#pair#entry() abort"{{{
  let all = s:opt_g('config', s:default_config)
  if type(all) != v:t_dict
    return s:normalize_entry({})
  endif
  let ft = &filetype
  if !empty(ft) && has_key(all, ft)
    return s:normalize_entry(all[ft])
  endif
  return s:normalize_entry(get(all, '*', {}))
endfunction"}}}

function! s:syntax_hit(pats) abort"{{{
  if empty(a:pats) || empty(&syntax)
    return 0
  endif
  let lnum = line('.')
  let scol = col('.')
  let llen = len(getline(lnum))
  if scol > llen && llen > 0
    let scol = llen
  endif
  let ids = synstack(lnum, scol)
  for id in ids
    let name = synIDattr(synIDtrans(id), 'name')
    if empty(name)
      continue
    endif
    for pat in a:pats
      if type(pat) != v:t_string || empty(pat)
        continue
      endif
      if match(name, '\c' . pat) >= 0
        return 1
      endif
    endfor
  endfor
  return 0
endfunction"}}}

function! s:ts_hit(pats) abort"{{{
  if empty(a:pats)
    return 0
  endif
  if !has('nvim')
    return 0
  endif
  try
    return luaeval("require('im.pair').ts_blocked(_A)", a:pats) ? 1 : 0
  catch
    return 0
  endtry
endfunction"}}}

function! s:scope_blocked() abort"{{{
  let entry = im#pair#entry()
  if entry.disabled
    return 1
  endif
  return s:ts_hit(entry.ts) || s:syntax_hit(entry.syntax)
endfunction"}}}

function! s:vim_comment_line(ch) abort"{{{
  return a:ch ==# '"' && index(split(&filetype, '\.'), 'vim') >= 0
        \ && match(getline('.'), '^\s*$') >= 0
endfunction"}}}

function! s:blocked(...) abort"{{{
  let ch = a:0 ? a:1 : ''
  return s:scope_blocked() || s:vim_comment_line(ch)
endfunction"}}}

function! im#pair#complete() abort"{{{
  let state = im#state#get()
  if !s:opt_g('enabled', 0) || im#replace#active()
    return
  endif
  let text = state.last_commit
  let state.last_commit = ''
  let fb = state.last_fallback
  let state.last_fallback = ''
  if strchars(fb) == 1
    let ch = fb
  elseif !empty(text)
    let ch = strcharpart(text, strchars(text) - 1, 1)
  else
    return
  endif

  let role = s:classify(ch)
  if empty(role) || s:blocked(ch)
    return
  endif
  if role.kind ==# 'close'
    let keys = s:char_at_cursor() ==# ch ? "\<BS>\<Right>" : ''
  elseif role.kind ==# 'open'
    let keys = role.close . "\<Left>"
  else
    let keys = s:char_at_cursor() ==# ch ? "\<BS>\<Right>" : ch . "\<Left>"
  endif
  if !empty(keys)
    call feedkeys(keys, 'ni')
  endif
endfunction"}}}

function! im#pair#should_bs_pair() abort"{{{
  if !s:opt_g('enabled', 0) || im#replace#active() || col('.') <= 1
    return 0
  endif
  if s:blocked()
    return 0
  endif
  let line   = getline('.')
  let cidx   = charidx(line, col('.') - 1)
  let before = strcharpart(line, cidx - 1, 1)
  let cur    = strcharpart(line, cidx, 1)
  if empty(cur)
    return 0
  endif
  let role = s:classify(before)
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
  if !s:opt_g('enabled', 0) || im#replace#active() || im#state#composing()
    return 0
  endif
  if s:blocked()
    return 0
  endif
  let next = s:char_at_cursor()
  if empty(next)
    return 0
  endif
  let nrole = s:classify(next)
  return !empty(nrole) && nrole.kind !=# 'open'
endfunction"}}}

function! im#pair#jump_any() abort"{{{
  return im#pair#should_jump() ? "\<Right>" : ''
endfunction"}}}

function! im#pair#jump_many() abort"{{{
  if !s:opt_g('enabled', 0) || im#replace#active() || im#state#composing()
    return ''
  endif
  if s:blocked()
    return ''
  endif
  let line = getline('.')
  let cidx = charidx(line, col('.') - 1)
  let clen = strchars(line)
  let n = 0
  while cidx + n < clen
    let r = s:classify(strcharpart(line, cidx + n, 1))
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
  echom '[IM] auto-pair ' . (s:opt_g('enabled', 0) ? 'on' : 'off')
endfunction"}}}

function! im#pair#default_rules() abort"{{{
  return deepcopy(s:default_rules)
endfunction"}}}

let s:imap_session = 0
let s:imap_saved = {}

function! im#pair#imap_keys() abort"{{{
  let seen = {}
  let keys = []
  for r in s:rules()
    if type(r) != v:t_dict
      continue
    endif
    for k in [get(r, 'open', ''), get(r, 'close', '')]
      if !empty(k) && !has_key(seen, k)
        if strchars(k) != 1 || char2nr(k) < 0x20 || char2nr(k) > 0x7E
          continue
        endif
        let seen[k] = 1
        call add(keys, k)
      endif
    endfor
  endfor
  return keys
endfunction"}}}

function! im#pair#imap_is_active() abort"{{{
  return s:imap_session
endfunction"}}}

function! s:imap_lhs(key) abort"{{{
  return substitute(a:key, '|', '<bar>', 'g')
endfunction"}}}

function! s:imap_rhs(key) abort"{{{
  return 'im#pair#imap_complete(' . string(a:key) . ')'
endfunction"}}}

function! s:imap_restore(key, mdict) abort"{{{
  if exists('*mapset')
    call mapset('i', 0, a:mdict)
    return
  endif
  if !has_key(a:mdict, 'rhs') || type(a:mdict.rhs) != v:t_string
    echohl WarningMsg
    echom '[IM] imap restore skipped, unrestorable mapping: ' . a:key
    echohl None
    return
  endif
  let cmd = 'i'
  if get(a:mdict, 'noremap', 1)
    let cmd .= 'noremap'
  else
    let cmd .= 'map'
  endif
  if get(a:mdict, 'buffer', 0) | let cmd .= ' <buffer>' | endif
  if get(a:mdict, 'nowait', 0) | let cmd .= ' <nowait>' | endif
  if get(a:mdict, 'silent', 0) | let cmd .= ' <silent>' | endif
  if get(a:mdict, 'expr', 0)   | let cmd .= ' <expr>'   | endif
  let rhs = substitute(a:mdict.rhs, "\n", '\\<NL>', 'g')
  execute 'silent! ' . cmd . ' ' . s:imap_lhs(a:key) . ' ' . rhs
endfunction"}}}

function! s:imap_prune() abort"{{{
  for b in keys(s:imap_saved)
    if !bufexists(str2nr(b))
      call remove(s:imap_saved, b)
    endif
  endfor
endfunction"}}}

function! im#pair#imap_enable() abort"{{{
  if !s:opt_g('enabled', 0)
    return
  endif
  if !s:opt_g('imap_enabled', 1)
    return
  endif
  let s:imap_session = 1
  if mode(1) =~# '^[iR]'
    call im#pair#imap_enter()
  endif
endfunction"}}}

function! im#pair#imap_disable() abort"{{{
  let s:imap_session = 0
  call im#pair#imap_leave()
endfunction"}}}

function! im#pair#imap_refresh() abort"{{{
  call im#pair#imap_enter()
endfunction"}}}

function! im#pair#imap_enter() abort"{{{
  if !s:imap_session
    return
  endif
  if !s:opt_g('enabled', 0)
    return
  endif
  if !s:opt_g('imap_enabled', 1)
    return
  endif
  call s:imap_prune()
  let buf = bufnr('%')
  if !has_key(s:imap_saved, buf)
    let s:imap_saved[buf] = {}
  endif
  for key in im#pair#imap_keys()
    if empty(key)
      continue
    endif
    if maparg(key, 'i') ==# s:imap_rhs(key)
      if !has_key(s:imap_saved[buf], key)
        let s:imap_saved[buf][key] = {'map': {}, 'rhs': ''}
      endif
      continue
    endif
    let eff = maparg(key, 'i', 0, 1)
    let s:imap_saved[buf][key] = {
          \ 'map': type(eff) == v:t_dict ? eff : {},
          \ 'rhs': maparg(key, 'i'),
          \ }
    silent! execute 'inoremap <buffer> <expr> <silent> ' . s:imap_lhs(key)
          \ . ' ' . s:imap_rhs(key)
  endfor
endfunction"}}}

function! im#pair#imap_leave() abort"{{{
  let buf = bufnr('%')
  if !has_key(s:imap_saved, buf)
    return
  endif
  for key in keys(s:imap_saved[buf])
    let snap = s:imap_saved[buf][key]
    let eff = maparg(key, 'i', 0, 1)
    if maparg(key, 'i') ==# s:imap_rhs(key)
          \ && type(eff) == v:t_dict && get(eff, 'buffer', 0)
      silent! execute 'iunmap <buffer> ' . s:imap_lhs(key)
      if !empty(snap.map)
        call s:imap_restore(key, snap.map)
      endif
    endif
  endfor
  call remove(s:imap_saved, buf)
endfunction"}}}

function! im#pair#imap_complete(key) abort"{{{
  if im#replace#active() || !s:imap_session || !s:opt_g('enabled', 0)
    return a:key
  endif
  if s:blocked(a:key)
    return a:key
  endif
  let role = s:classify(a:key)
  if empty(role)
    return a:key
  endif
  if role.kind ==# 'close'
    return s:char_at_cursor() ==# role.ch ? "\<Right>" : a:key
  elseif role.kind ==# 'open'
    return a:key . role.close . "\<Left>"
  else
    return s:char_at_cursor() ==# role.ch ? "\<Right>" : a:key . a:key . "\<Left>"
  endif
endfunction"}}}
