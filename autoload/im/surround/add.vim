function! im#surround#add#tag(ch) abort"{{{
  let input = input('Tag: ')
  if empty(input)
    return []
  endif
  let tag = matchstr(input, '^<\?\zs[^ \t>]*')
  let attrs = matchstr(input, '^<\?[^ \t>]*\s\+\zs.\{-}\ze>\?$')
  let open = empty(attrs) ? tag : tag . ' ' . attrs
  return ['<' . open . '>', '</' . tag . '>']
endfunction"}}}

function! im#surround#add#func(ch) abort"{{{
  let name = input('Function: ')
  if empty(name)
    return []
  endif
  return [name . '(', ')']
endfunction"}}}

function! im#surround#add#input(ch) abort"{{{
  let left = input('Left delimiter: ')
  if empty(left)
    return []
  endif
  let right = input('Right delimiter: ')
  if empty(right)
    return []
  endif
  return [left, right]
endfunction"}}}

function! im#surround#add#invalid(ch) abort"{{{
  if a:ch ==# '' || a:ch =~# '[\x00-\x1f]' || char2nr(a:ch) == 0x80
    return []
  endif
  return [a:ch, a:ch]
endfunction"}}}
