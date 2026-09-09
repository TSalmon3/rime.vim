let s:zone = 'chinese'

function! s:lookup_context_rule() abort"{{{
  let all = get(g:, 'im_context_config', {})
  if type(all) != v:t_dict
    return {}
  endif
  let ft = &filetype
  if !empty(ft) && has_key(all, ft)
    return all[ft]
  endif
  return get(all, '*', {})
endfunction"}}}

function! s:normalize_context_rule(rule) abort"{{{
  let dflt = {'mode': 'blacklist', 'ts': [], 'syntax': []}
  if type(a:rule) != v:t_dict
    return dflt
  endif
  let mode = get(a:rule, 'mode', 'blacklist')
  if mode !=# 'whitelist' && mode !=# 'blacklist'
    let mode = 'blacklist'
  endif
  let ts = get(a:rule, 'ts', [])
  let syntax = get(a:rule, 'syntax', [])
  if type(ts) != v:t_list
    let ts = []
  endif
  if type(syntax) != v:t_list
    let syntax = []
  endif
  return {'mode': mode, 'ts': ts, 'syntax': syntax}
endfunction"}}}

function! s:current_context_rule() abort"{{{
  return s:normalize_context_rule(s:lookup_context_rule())
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
  for id in synstack(lnum, scol)
    let name = synIDattr(id, 'name')
    if empty(name)
      continue
    endif
    let lname = tolower(name)
    for pat in a:pats
      if type(pat) != v:t_string || empty(pat)
        continue
      endif
      if stridx(lname, tolower(pat)) >= 0
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
  if !has('nvim') || !get(g:, 'im_context_ts_check', 0)
    return 0
  endif
  try
    return luaeval("require('im.context').hit(_A)", a:pats) ? 1 : 0
  catch
    return 0
  endtry
endfunction"}}}

function! s:current_zone() abort"{{{
  let rule = s:current_context_rule()
  if empty(rule.ts) && empty(rule.syntax)
    return rule.mode ==# 'whitelist' ? 'english' : 'chinese'
  endif
  let hit = s:ts_hit(rule.ts) || s:syntax_hit(rule.syntax)
  if rule.mode ==# 'whitelist'
    return hit ? 'chinese' : 'english'
  endif
  return hit ? 'english' : 'chinese'
endfunction"}}}

function! s:force(zone) abort"{{{
  let s:zone = a:zone
  let to_chinese = a:zone ==# 'chinese'
  if !!&iminsert == to_chinese
    return
  endif
  if mode(1) =~# '^[iR]'
    call feedkeys(nr2char(30), 'ni')
  else
    let &iminsert = to_chinese
  endif
  if to_chinese
    silent! doautocmd User RimeContextChinese
  else
    silent! doautocmd User RimeContextEnglish
  endif
  silent! doautocmd User RimeContextChanged
  redrawstatus
endfunction"}}}

function! im#context#update() abort"{{{
  if !get(g:, 'im_context_enabled', 0)
    return
  endif
  let state = im#state#get()
  if !state.started || !state.enabled
    return
  endif
  if im#state#composing()
    return
  endif
  let zone = s:current_zone()
  if zone ==# s:zone
    return
  endif
  call s:force(zone)
endfunction"}}}

function! im#context#on_enter() abort"{{{
  if !get(g:, 'im_context_enabled', 0)
    return
  endif
  let state = im#state#get()
  if !state.started || !state.enabled
    return
  endif
  call s:force(s:current_zone())
endfunction"}}}

function! im#context#on_leave() abort"{{{
  let s:zone = 'chinese'
endfunction"}}}

function! im#context#toggle() abort"{{{
  let state = im#state#get()
  if !state.started || !state.enabled
    return
  endif
  if im#state#composing()
    call im#cancel()
  endif
  let to_chinese = !&iminsert
  if mode(1) =~# '^[iR]'
    call feedkeys(nr2char(30), 'ni')
  else
    let &iminsert = to_chinese
  endif
  if to_chinese
    silent! doautocmd User RimeContextChinese
  else
    silent! doautocmd User RimeContextEnglish
  endif
  silent! doautocmd User RimeContextChanged
  redrawstatus
endfunction"}}}
