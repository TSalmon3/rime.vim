function! im#pair#cond#never() abort
  return {-> 0}
endfunction

function! im#pair#cond#always() abort
  return {-> 1}
endfunction

function! im#pair#cond#done() abort
  return {-> 1}
endfunction

function! im#pair#cond#none() abort
  return {-> 0}
endfunction

function! s:ctx_get(c, key) abort
  if type(a:c) != v:t_dict
    return ''
  endif
  return get(a:c, a:key, '')
endfunction

function! s:endswith(s, pat) abort
  let ns = strchars(a:s)
  let np = strchars(a:pat)
  if np == 0
    return 1
  endif
  if ns < np
    return 0
  endif
  return strcharpart(a:s, ns - np) ==# a:pat
endfunction

function! s:startswith(s, pat) abort
  let np = strchars(a:pat)
  if np == 0
    return 1
  endif
  return strcharpart(a:s, 0, np) ==# a:pat
endfunction

function! s:match_before(before, pat) abort
  let eff = a:pat =~# '\$$' ? a:pat : a:pat . '$'
  try
    return match(a:before, eff) >= 0
  catch
    return s:endswith(a:before, a:pat)
  endtry
endfunction

function! s:match_after(after, pat) abort
  let eff = a:pat =~# '^\^' ? a:pat : '^' . a:pat
  try
    return match(a:after, eff) >= 0
  catch
    return s:startswith(a:after, a:pat)
  endtry
endfunction

function! im#pair#cond#before_text(text) abort
  let pat = a:text
  return {c -> s:match_before(s:ctx_get(c, 'before'), pat)}
endfunction

function! im#pair#cond#after_text(text) abort
  let pat = a:text
  return {c -> s:match_after(s:ctx_get(c, 'after'), pat)}
endfunction

function! im#pair#cond#not_before_text(text) abort
  let Fn = im#pair#cond#before_text(a:text)
  return {c -> !Fn(c)}
endfunction

function! im#pair#cond#not_after_text(text) abort
  let Fn = im#pair#cond#after_text(a:text)
  return {c -> !Fn(c)}
endfunction

function! im#pair#cond#before_regex(pat) abort
  let pat = a:pat
  return {c -> s:match_before(s:ctx_get(c, 'before'), pat)}
endfunction

function! im#pair#cond#after_regex(pat) abort
  let pat = a:pat
  return {c -> s:match_after(s:ctx_get(c, 'after'), pat)}
endfunction

function! im#pair#cond#not_before_regex(pat) abort
  let Fn = im#pair#cond#before_regex(a:pat)
  return {c -> !Fn(c)}
endfunction

function! im#pair#cond#not_after_regex(pat) abort
  let Fn = im#pair#cond#after_regex(a:pat)
  return {c -> !Fn(c)}
endfunction

function! s:inside_quote(before) abort
  let s = a:before
  let dq = 0
  let sq = 0
  let i = 0
  let n = strchars(s)
  while i < n
    let ch = strcharpart(s, i, 1)
    let prev = i > 0 ? strcharpart(s, i - 1, 1) : ''
    if prev !=# '\'
      if ch ==# '"'
        let dq = !dq
      elseif ch ==# "'"
        let sq = !sq
      endif
    endif
    let i += 1
  endwhile
  return dq || sq
endfunction

function! im#pair#cond#not_inside_quote() abort
  return {c -> !s:inside_quote(s:ctx_get(c, 'before'))}
endfunction

function! im#pair#cond#is_inside_quote() abort
  return {c -> s:inside_quote(s:ctx_get(c, 'before'))}
endfunction

function! s:is_vim_comment(c) abort
  if type(a:c) != v:t_dict
    return 0
  endif
  if index(split(get(a:c, 'filetype', ''), '\.'), 'vim') < 0
    return 0
  endif
  return s:ctx_get(a:c, 'before') =~# '^\s*$'
endfunction

function! im#pair#cond#is_vim_comment() abort
  return {c -> s:is_vim_comment(c)}
endfunction

function! im#pair#cond#not_vim_comment() abort
  return {c -> !s:is_vim_comment(c)}
endfunction
