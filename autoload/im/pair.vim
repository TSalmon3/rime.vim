let s:default_rules = [
      \ {'open': '(',  'close': ')',  'kind': 'matchpair'},
      \ {'open': '[',  'close': ']',  'kind': 'matchpair'},
      \ {'open': '{',  'close': '}',  'kind': 'matchpair'},
      \ {'open': '（', 'close': '）', 'kind': 'matchpair', 'with_cr': im#pair#cond#never()},
      \ {'open': '【', 'close': '】', 'kind': 'matchpair', 'with_cr': im#pair#cond#never()},
      \ {'open': '「', 'close': '」', 'kind': 'matchpair', 'with_cr': im#pair#cond#never()},
      \ {'open': '『', 'close': '』', 'kind': 'matchpair', 'with_cr': im#pair#cond#never()},
      \ {'open': '《', 'close': '》', 'kind': 'matchpair', 'with_cr': im#pair#cond#never()},
      \ {'open': "‘",  'close': "’",  'kind': 'matchpair', 'with_cr': im#pair#cond#never()},
      \ {'open': "“",  'close': "”",  'kind': 'matchpair', 'with_cr': im#pair#cond#never()},
      \ {'open': '"',  'close': '"',  'kind': 'quote', 'with_cr': im#pair#cond#never()},
      \ {'open': "'",  'close': "'",  'kind': 'quote', 'with_cr': im#pair#cond#never()},
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

function! im#pair#normalize_rule(raw) abort"{{{
  if type(a:raw) != v:t_dict
    return {}
  endif
  let open = get(a:raw, 'open', '')
  let close = get(a:raw, 'close', '')
  if type(open) != v:t_string || type(close) != v:t_string
    return {}
  endif
  if empty(open) || empty(close)
    return {}
  endif
  let kind = get(a:raw, 'kind', '')
  if kind !=# 'quote' && kind !=# 'matchpair'
    let kind = open ==# close ? 'quote' : 'matchpair'
  endif
  let r = {'open': open, 'close': close, 'kind': kind}
  for k in ['with_pair', 'with_move', 'with_del', 'with_cr']
    let Val = get(a:raw, k, v:null)
    if type(Val) == v:t_func
      let r[k] = Val
    elseif type(Val) == v:t_list
      let fns = filter(copy(Val), 'type(v:val) == v:t_func')
      let r[k] = empty(fns) ? v:null : fns
    else
      let r[k] = v:null
    endif
  endfor
  return r
endfunction"}}}

function! s:rules() abort"{{{
  let raw = has_key(b:, 'im_pair_rules') ? b:im_pair_rules : s:opt_g('rules', s:default_rules)
  if type(raw) != v:t_list
    return []
  endif
  let ok = []
  for r in raw
    let n = im#pair#normalize_rule(r)
    if !empty(n)
      call add(ok, n)
    endif
  endfor
  call sort(ok, {a, b -> strchars(b.open) - strchars(a.open)})
  return ok
endfunction"}}}

function! im#pair#rule_list() abort"{{{
  return get(b:, 'im_pair_rule_list', [])
endfunction"}}}

function! s:single(raw) abort"{{{
  return type(a:raw) == v:t_string && strchars(a:raw) == 1 ? a:raw : ''
endfunction"}}}

function! im#pair#on_enter() abort"{{{
  let b:im_pair_rule_list = s:rules()
endfunction"}}}

function! im#pair#on_leave() abort"{{{
  unlet! b:im_pair_rule_list
endfunction"}}}

function! s:endswith(s, pat) abort"{{{
  let ns = strchars(a:s)
  let np = strchars(a:pat)
  if np == 0
    return 1
  endif
  if ns < np
    return 0
  endif
  return strcharpart(a:s, ns - np) ==# a:pat
endfunction"}}}

function! s:startswith(s, pat) abort"{{{
  let np = strchars(a:pat)
  if np == 0
    return 1
  endif
  return strcharpart(a:s, 0, np) ==# a:pat
endfunction"}}}

function! s:last_char(s) abort"{{{
  let n = strchars(a:s)
  if n == 0
    return ''
  endif
  return strcharpart(a:s, n - 1, 1)
endfunction"}}}

function! s:cursor_context() abort"{{{
  let line = getline('.')
  let cidx = charidx(line, col('.') - 1)
  if cidx < 0
    let cidx = strchars(line)
  endif
  let before = strcharpart(line, 0, cidx)
  let after = strcharpart(line, cidx)
  return {'before': before, 'after': after, 'line': line,
        \ 'col': col('.'), 'filetype': &filetype}
endfunction"}}}

function! s:gate(Fn, ctx) abort"{{{
  if type(a:Fn) == v:t_list
    for F in a:Fn
      if !s:gate(F, a:ctx)
        return 0
      endif
    endfor
    return 1
  endif
  if type(a:Fn) != v:t_func
    return 1
  endif
  try
    return a:Fn(a:ctx) ? 1 : 0
  catch
    return 0
  endtry
endfunction"}}}

function! s:find_move_rule(after, key, ctx) abort"{{{
  for r in im#pair#rule_list()
    if !s:startswith(a:after, r.close)
      continue
    endif
    if !empty(a:key) && !s:endswith(r.close, a:key)
      continue
    endif
    if !s:gate(r.with_move, a:ctx)
      continue
    endif
    return r
  endfor
  return {}
endfunction"}}}

function! s:find_pair_rule(before_plus, ctx) abort"{{{
  for r in im#pair#rule_list()
    if !s:endswith(a:before_plus, r.open)
      continue
    endif
    if !s:gate(r.with_pair, a:ctx)
      continue
    endif
    return r
  endfor
  return {}
endfunction"}}}

function! s:find_del_rule(before, after, ctx) abort"{{{
  for r in im#pair#rule_list()
    if !s:endswith(a:before, r.open)
      continue
    endif
    if !s:startswith(a:after, r.close)
      continue
    endif
    if !s:gate(r.with_del, a:ctx)
      continue
    endif
    return r
  endfor
  return {}
endfunction"}}}

function! s:find_cr_rule(before, after, ctx) abort"{{{
  for r in im#pair#rule_list()
    if !s:endswith(a:before, r.open)
      continue
    endif
    if !s:startswith(a:after, r.close)
      continue
    endif
    if !s:gate(r.with_cr, a:ctx)
      continue
    endif
    return r
  endfor
  return {}
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

function! s:ft_disabled() abort"{{{
  let entry = im#pair#entry()
  return entry.disabled
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

  if s:ft_disabled()
    return
  endif
  if empty(im#pair#rule_list())
    return
  endif

  let ctx = s:cursor_context()
  let m = s:find_move_rule(ctx.after, ch, ctx)
  if !empty(m)
    call feedkeys("\<BS>" . repeat("\<Right>", strchars(m.close)), 'ni')
    return
  endif
  if s:scope_blocked()
    return
  endif
  let p = s:find_pair_rule(ctx.before . ch, ctx)
  if !empty(p)
    call feedkeys(p.close . repeat("\<Left>", strchars(p.close)), 'ni')
    return
  endif
endfunction"}}}

function! im#pair#should_bs() abort"{{{
  if !s:opt_g('enabled', 0) || im#replace#active() || col('.') <= 1
    return 0
  endif
  if s:scope_blocked()
    return 0
  endif
  if empty(im#pair#rule_list())
    return 0
  endif
  let ctx = s:cursor_context()
  if empty(ctx.after)
    return 0
  endif
  return !empty(s:find_del_rule(ctx.before, ctx.after, ctx))
endfunction"}}}

function! im#pair#bs() abort"{{{
  if !empty(im#pair#rule_list()) && !s:scope_blocked()
    let ctx = s:cursor_context()
    let r = s:find_del_rule(ctx.before, ctx.after, ctx)
    if !empty(r)
      return repeat("\<BS>", strchars(r.open)) . repeat("\<Del>", strchars(r.close))
    endif
  endif
  return "\<BS>\<Del>"
endfunction"}}}

function! im#pair#should_jump() abort"{{{
  if !s:opt_g('enabled', 0) || im#replace#active() || im#state#composing()
    return 0
  endif
  if s:ft_disabled()
    return 0
  endif
  if empty(im#pair#rule_list())
    return 0
  endif
  let ctx = s:cursor_context()
  if empty(ctx.after)
    return 0
  endif
  return !empty(s:find_move_rule(ctx.after, '', ctx))
endfunction"}}}

function! im#pair#jump_any() abort"{{{
  if !s:opt_g('enabled', 0) || im#replace#active() || im#state#composing()
    return ''
  endif
  if s:ft_disabled()
    return ''
  endif
  if empty(im#pair#rule_list())
    return ''
  endif
  let ctx = s:cursor_context()
  let r = s:find_move_rule(ctx.after, '', ctx)
  return empty(r) ? '' : repeat("\<Right>", strchars(r.close))
endfunction"}}}

function! im#pair#jump_many() abort"{{{
  if !s:opt_g('enabled', 0) || im#replace#active() || im#state#composing()
    return ''
  endif
  if s:ft_disabled()
    return ''
  endif
  if empty(im#pair#rule_list())
    return ''
  endif
  let ctx = s:cursor_context()
  let rest = ctx.after
  let stepped = ctx.before
  let total = 0
  while !empty(rest)
    let sub = {'before': stepped, 'after': rest, 'line': ctx.line,
          \ 'col': ctx.col + total, 'filetype': ctx.filetype}
    let r = s:find_move_rule(rest, '', sub)
    if empty(r)
      break
    endif
    let n = strchars(r.close)
    let total += n
    let stepped .= strcharpart(rest, 0, n)
    let rest = strcharpart(rest, n)
  endwhile
  return total > 0 ? repeat("\<Right>", total) : ''
endfunction"}}}

function! im#pair#should_cr() abort"{{{
  if !s:opt_g('enabled', 0) || im#replace#active()
    return 0
  endif
  if s:scope_blocked()
    return 0
  endif
  if empty(im#pair#rule_list())
    return 0
  endif
  let ctx = s:cursor_context()
  if empty(ctx.before) || empty(ctx.after)
    return 0
  endif
  return !empty(s:find_cr_rule(ctx.before, ctx.after, ctx))
endfunction"}}}

function! im#pair#cr() abort"{{{
  return "\<CR>\<Up>\<End>\<CR>"
endfunction"}}}

function! im#pair#should_space() abort"{{{
  if !s:opt_g('enabled', 0) || im#replace#active() || im#state#composing()
    return 0
  endif
  if s:scope_blocked()
    return 0
  endif
  if empty(im#pair#rule_list())
    return 0
  endif
  let ctx = s:cursor_context()
  for r in im#pair#rule_list()
    if r.open !=# ' ' && r.close !=# ' '
      continue
    endif
    if !s:endswith(ctx.before . ' ', r.open)
      continue
    endif
    if !s:gate(r.with_pair, ctx)
      continue
    endif
    return 1
  endfor
  return 0
endfunction"}}}

function! im#pair#space() abort"{{{
  if !s:opt_g('enabled', 0) || im#replace#active() || im#state#composing()
    return "\<space>"
  endif
  if s:scope_blocked()
    return "\<space>"
  endif
  if empty(im#pair#rule_list())
    return "\<space>"
  endif
  let ctx = s:cursor_context()
  for r in im#pair#rule_list()
    if r.open !=# ' ' && r.close !=# ' '
      continue
    endif
    if !s:endswith(ctx.before . ' ', r.open)
      continue
    endif
    if !s:gate(r.with_pair, ctx)
      continue
    endif
    return r.open . r.close . repeat("\<Left>", strchars(r.close))
  endfor
  return "\<space>"
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
    for k in [s:last_char(r.open), s:last_char(r.close)]
      if empty(k) || has_key(seen, k)
        continue
      endif
      if strchars(k) != 1 || char2nr(k) < 0x20 || char2nr(k) > 0x7E
        continue
      endif
      let seen[k] = 1
      call add(keys, k)
    endfor
  endfor
  return keys
endfunction"}}}

function! im#pair#imap_is_active() abort"{{{
  return s:imap_session
endfunction"}}}

function! s:imap_lhs(key) abort"{{{
  return substitute(substitute(a:key, '|', '<bar>', 'g'), ' ', '<Space>', 'g')
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
  silent! doautocmd User RimePairImapSetup
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
  silent! doautocmd User RimePairImapRestore
endfunction"}}}

function! im#pair#imap_complete(key) abort"{{{
  if im#replace#active() || !s:imap_session || !s:opt_g('enabled', 0)
    return a:key
  endif
  if s:ft_disabled()
    return a:key
  endif
  if empty(im#pair#rule_list())
    return a:key
  endif
  let ctx = s:cursor_context()
  let m = s:find_move_rule(ctx.after, a:key, ctx)
  if !empty(m)
    return repeat("\<Right>", strchars(m.close))
  endif
  if s:scope_blocked()
    return a:key
  endif
  let p = s:find_pair_rule(ctx.before . a:key, ctx)
  if !empty(p)
    return a:key . p.close . repeat("\<Left>", strchars(p.close))
  endif
  return a:key
endfunction"}}}
