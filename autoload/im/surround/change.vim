function! s:parse_tag_at_cursor() abort"{{{
  let line = getline('.')
  let cidx = max([charidx(line, col('.') - 1), 0])

  let lstart = -1
  for i in range(cidx, 0, -1)
    if strcharpart(line, i, 1) ==# '<'
      let lstart = i
      break
    endif
  endfor
  if lstart < 0
    return []
  endif

  let rend = -1
  for i in range(lstart + 1, strchars(line) - 1)
    if strcharpart(line, i, 1) ==# '>'
      let rend = i
      break
    endif
  endfor
  if rend < 0
    return []
  endif

  let tag_content = strcharpart(line, lstart + 1, rend - lstart - 1)
  let old_tag = matchstr(tag_content, '^\a\w*')
  let old_attrs = matchstr(tag_content, '^\a\w*\zs\s\+.\+')
  return [old_tag, old_attrs]
endfunction"}}}

function! im#surround#change#tag() abort"{{{
  let parsed = s:parse_tag_at_cursor()
  if empty(parsed)
    return []
  endif
  let [old_tag, old_attrs] = parsed

  let new_tag = input('Tag: ', old_tag)
  if empty(new_tag)
    return []
  endif

  let new_open = empty(old_attrs) ? new_tag : new_tag . old_attrs
  return ['<' . new_open . '>', '</' . new_tag . '>']
endfunction"}}}

function! im#surround#change#tag_full() abort"{{{
  let parsed = s:parse_tag_at_cursor()
  if empty(parsed)
    return []
  endif
  let old_tag = parsed[0]

  let new_tag = input('Tag: ', old_tag)
  if empty(new_tag)
    return []
  endif

  return ['<' . new_tag . '>', '</' . new_tag . '>']
endfunction"}}}

function! im#surround#change#func() abort"{{{
  let name = input('Function name: ')
  if empty(name)
    return []
  endif
  return [name . '(', ')']
endfunction"}}}
