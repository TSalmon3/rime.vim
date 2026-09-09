function! im#context#toggle() abort"{{{
  let state = im#state#get()
  if !state.started || !state.enabled
    return 0
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
  return to_chinese
endfunction"}}}
