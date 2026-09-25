function! s:pos_le(p1, p2) abort"{{{
  return a:p1[0] < a:p2[0] || (a:p1[0] == a:p2[0] && a:p1[1] <= a:p2[1])
endfunction"}}}

function! im#surround#textobj#auto(is_inner) abort"{{{
  try
    let t = im#surround#find#auto('a')
  catch
    return
  endtry
  if type(t) != v:t_dict || !has_key(t, 'first_pos') || !has_key(t, 'last_pos')
    return
  endif
  let [fl, fc] = t.first_pos
  let [ll, lc] = t.last_pos
  if a:is_inner
    let open_len = get(t, 'open_len', 0)
    let close_len = get(t, 'close_len', 0)
    if type(open_len) != v:t_number || type(close_len) != v:t_number
      return
    endif
    let head = [fl, fc + open_len]
    let tail = [ll, lc - close_len]
    if head[0] < 1 || head[1] < 1 || tail[0] < 1 || tail[1] < 1
      return
    endif
    if !s:pos_le(head, tail)
      return
    endif
  else
    let head = [fl, fc]
    let tail = [ll, lc]
  endif
  execute 'normal! v'
  call cursor(head[0], head[1])
  normal! o
  call cursor(tail[0], tail[1])
  if &selection ==# 'exclusive'
    normal! l
  endif
endfunction"}}}
