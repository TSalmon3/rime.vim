
let s:last = {}
let s:mark_id = -1
let s:mark_timer = -1

let s:plugin_root = fnamemodify(resolve(expand('<sfile>:p')), ':h:h:h')

let s:file_loaded = 0

function! s:ensure() abort"{{{
  if s:file_loaded
    return 1
  endif
  let s:file_loaded = 0
  let path = s:plugin_root . '/data/pinyin_table.vim'
  if !filereadable(path)
    return 0
  endif
  try
    execute 'source ' . fnameescape(path)
  catch
    return 0
  endtry
  if type(get(g:, 'im_base_table', {})) != v:t_dict
        \ || empty(g:im_base_table)
    return 0
  endif
  let s:file_loaded = 1
  return 1
endfunction"}}}

function! im#motion#reload() abort"{{{
  let s:file_loaded = 0
  return s:ensure()
endfunction"}}}

function! s:class(key) abort"{{{
  if !s:ensure()
    return ''
  endif
  if strchars(a:key) != 1
    return ''
  endif
  let k = a:key

  let mode = get(g:, 'im_motion_mode', 'quanpin')
  if mode ==# 'flypy'
    let refs = g:im_flypy_map
  else
    let refs = g:im_quanpin_map
  endif
  let base = g:im_base_table

  if has_key(refs, k) && type(refs[k]) == v:t_string && !empty(refs[k])
    return '[' . escape(k . refs[k], ']\^-\\') . ']'
  endif

  if has_key(refs, k) && type(refs[k]) == v:t_list && !empty(refs[k])
    let ext = ''
    for b in refs[k]
      if type(b) != v:t_string || !has_key(base, b)
            \ || type(base[b]) != v:t_string
        return ''
      endif
      let ext .= base[b]
    endfor
    return '[' . escape(k . ext, ']\^-\\') . ']'
  endif
  return '[' . escape(k, ']\^-\\') . ']'
endfunction"}}}

function! s:read_key() abort"{{{
  let mid = -1
  let win = -1
  try
    if get(g:, 'im_motion_shade', 1)
      if !hlexists('ImMotionShade')
        highlight default link ImMotionShade Grey
      endif
      let win = win_getid()
      let mid = matchadd('ImMotionShade', '\%' . line('.') . 'l.*', 50)
    endif
    redraw
    while 1
      try
        let c = getchar()
      catch /^Vim:Interrupt$/
        return ''
      endtry
      if type(c) == v:t_string && c ==# "\x80\xfd`"
        continue
      endif
      let k = type(c) == v:t_number ? nr2char(c) : c
      let n = char2nr(k)
      if n < 32 || n > 126
        return ''
      endif
      return k
    endwhile
  finally
    if mid >= 0 && win_id2win(win) > 0
      call win_execute(win, 'silent! call matchdelete(' . mid . ')')
    endif
  endtry
endfunction"}}}

function! s:mode() abort"{{{
  let m = mode(1)
  if m =~# '^no'
    return 'o'
  endif
  let c = m[0]
  if c ==# 'v' || c ==# 'V' || c ==# 's' || c ==# 'S' || char2nr(c) == 22
    return 'v'
  endif
  return 'n'
endfunction"}}}

function! s:cancelled(keys) abort"{{{
  return a:keys ==# '' || a:keys ==# "\<Esc>" || a:keys ==# "\<C-c>"
endfunction"}}}

function! s:expired(last) abort"{{{
  let ms = get(g:, 'im_motion_timeout_ms', 0)
  if ms <= 0
    return 0
  endif
  return (reltimefloat(reltime()) - get(a:last, 'stamp', 0)) * 1000.0 > ms
endfunction"}}}

function! s:recall(dir, inclusive, cnt) abort"{{{
  let m = s:mode()
  let last = get(s:last, m, {})
  if empty(last) || s:expired(last)
    return -1
  endif
  let cur = [bufnr('%'), line('.'), col('.')]
  if cur != last.pos
    call remove(s:last, m)
    return -1
  endif
  if (a:dir > 0) == (last.dir > 0)
    return s:jump(last.dir, last.inclusive, last.keys, a:cnt, 1, 1)
  endif
  return s:jump(-last.dir, last.inclusive, last.keys, a:cnt, 1)
endfunction"}}}

function! s:do(dir, inclusive) abort"{{{
  let cnt = v:count1 < 1 ? 1 : v:count1
  let r = s:recall(a:dir, a:inclusive, cnt)
  if r >= 0
    return r
  endif
  return s:jump(a:dir, a:inclusive, s:read_key(), cnt, 1)
endfunction"}}}

function! im#motion#f() abort"{{{
  return s:do(1, 1)
endfunction"}}}

function! im#motion#F() abort"{{{
  return s:do(-1, 1)
endfunction"}}}

function! im#motion#t() abort"{{{
  return s:do(1, 0)
endfunction"}}}

function! im#motion#T() abort"{{{
  return s:do(-1, 0)
endfunction"}}}

function! s:build(keys) abort"{{{
  let frag = s:class(a:keys)
  if frag ==# ''
    return ''
  endif
  return '\C' . frag
endfunction"}}}

function! s:open_fold() abort"{{{
  if &foldopen =~# '\<\%(all\|hor\)\>'
    while foldclosed(line('.')) >= 0
      foldopen
    endwhile
  endif
endfunction"}}}

function! s:target_pat(keys, lnum) abort"{{{
  let frag = s:class(a:keys)
  if frag ==# ''
    return ''
  endif
  return '\%' . a:lnum . 'l\C' . frag
endfunction"}}}

function! im#motion#mark_clear(...) abort"{{{
  if s:mark_id >= 0
    silent! call matchdelete(s:mark_id)
    let s:mark_id = -1
  endif
  if s:mark_timer >= 0
    silent! call timer_stop(s:mark_timer)
    let s:mark_timer = -1
  endif
  silent! autocmd! ImMotionTargetGrp
endfunction"}}}

function! im#motion#mark_maybe_clear() abort"{{{
  let last = get(s:last, s:mode(), {})
  if !empty(last) && get(last, 'pos', []) == [bufnr('%'), line('.'), col('.')]
    return
  endif
  call im#motion#mark_clear()
endfunction"}}}

function! s:mark(pat) abort"{{{
  call im#motion#mark_clear()
  if !get(g:, 'im_motion_mark', 1)
    return
  endif
  if !hlexists('ImMotionTarget')
    highlight default link ImMotionTarget Search
  endif
  let s:mark_id = matchadd('ImMotionTarget', a:pat, 100)
  augroup ImMotionTargetGrp
    autocmd!
    autocmd CursorMoved * call im#motion#mark_maybe_clear()
    autocmd InsertEnter,TextChanged * call im#motion#mark_clear()
  augroup END
  let ms = get(g:, 'im_motion_mark_ms', 0)
  if ms > 0
    let s:mark_timer = timer_start(ms, function('im#motion#mark_clear'))
  endif
endfunction"}}}

function! s:shift(dir) abort"{{{
  if a:dir > 0
    if col('.') < col('$')
      normal! l
    endif
  elseif col('.') > 1
    normal! h
  endif
endfunction"}}}

function! s:jump(dir, inclusive, keys, cnt, update_last, ...) abort"{{{
  if s:cancelled(a:keys)
    return 0
  endif
  let cnt = max([a:cnt, 1])
  let pat = s:build(a:keys)
  if pat ==# ''
    return 0
  endif

  let reuse = get(a:000, 0, 0) && !a:inclusive
  call s:open_fold()
  let lnum = line('.')
  let save = getpos('.')
  if reuse
    call s:shift(a:dir)
  endif
  for i in range(cnt)
    if searchpos(pat, a:dir > 0 ? 'W' : 'bW', lnum) == [0, 0]
      call setpos('.', save)
      return 0
    endif
    if reuse
      call s:shift(-a:dir)
    endif
  endfor
  if !reuse && !a:inclusive
    call s:shift(-a:dir)
  endif
  if s:mode() !=# 'o'
    let tp = s:target_pat(a:keys, lnum)
    if tp !=# ''
      call s:mark(tp)
    endif
  endif
  let cur = getpos('.')
  if !a:update_last
    let s:last[s:mode()]['pos'] = [bufnr('%'), cur[1], cur[2]]
    let s:last[s:mode()]['stamp'] = reltimefloat(reltime())
    return 1
  endif
  let s:last[s:mode()] = {'keys': a:keys, 'dir': a:dir, 'inclusive': a:inclusive,
        \ 'pos': [bufnr('%'), cur[1], cur[2]],
        \ 'stamp': reltimefloat(reltime())}
  return 1
endfunction"}}}

function! im#motion#reset() abort"{{{
  if has_key(s:last, s:mode())
    call remove(s:last, s:mode())
  endif
  call im#motion#mark_clear()
  return 1
endfunction"}}}

function! im#motion#repeat(...) abort"{{{
  let cnt = get(a:000, 0, v:count1)
  let m = s:mode()
  let last = get(s:last, m, {})
  if empty(last) || s:expired(last)
    return 0
  endif
  if [bufnr('%'), line('.'), col('.')] != last.pos
    call remove(s:last, m)
    return 0
  endif
  return s:jump(last.dir, last.inclusive, last.keys, cnt, 0, 1)
endfunction"}}}

function! im#motion#repeat_back(...) abort"{{{
  let cnt = get(a:000, 0, v:count1)
  let m = s:mode()
  let last = get(s:last, m, {})
  if empty(last) || s:expired(last)
    return 0
  endif
  if [bufnr('%'), line('.'), col('.')] != last.pos
    call remove(s:last, m)
    return 0
  endif
  return s:jump(-last.dir, last.inclusive, last.keys, cnt, 0)
endfunction"}}}
