function! im#snip#luasnip#query(keyword) abort"{{{
  if !has('nvim')
    return []
  endif
  try
    let raw = luaeval("require('im.snip.luasnip').items(_A)", &filetype)
  catch /^Vim(let):\|^Vim\%((\a\+)\)\=:E\d\+:/
    return []
  endtry
  if type(raw) != v:t_list
    return []
  endif
  let n = strlen(a:keyword)
  if n == 0
    return raw
  endif
  return filter(raw, 'strpart(v:val.word, 0, n) ==# a:keyword')
endfunction"}}}

function! im#snip#luasnip#expand() abort"{{{
  if !has('nvim')
    return
  endif
  silent! call luaeval("require('luasnip').expand()")
endfunction"}}}
