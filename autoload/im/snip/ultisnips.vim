function! im#snip#ultisnips#query(keyword) abort"{{{
  if !exists('*UltiSnips#SnippetsInCurrentScope')
    return []
  endif
  try
    let dict = UltiSnips#SnippetsInCurrentScope(1)
  catch /^Vim(let):\|^Vim\%((\a\+)\)\=:E\d\+:/
    return []
  endtry
  if type(dict) != v:t_dict
    return []
  endif
  let items = []
  let n = strlen(a:keyword)
  for [trigger, desc] in items(dict)
    if n > 0 && strpart(trigger, 0, n) !=# a:keyword
      continue
    endif
    call add(items, {'word': trigger, 'menu': type(desc) == v:t_string ? desc : ''})
  endfor
  return items
endfunction"}}}

function! im#snip#ultisnips#expand() abort"{{{
  if !exists('*UltiSnips#ExpandSnippet')
    return
  endif
  silent! call UltiSnips#ExpandSnippet()
endfunction"}}}
