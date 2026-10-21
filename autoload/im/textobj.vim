let s:enabled = 0
let s:setup = 0
let s:pending_op = {}
let s:last_op = {}

function! s:read_key() abort"{{{
  try
    let key = exists('*getcharstr') ? getcharstr() : getchar()
  catch /^Vim:Interrupt$/
    return ''
  endtry
  if type(key) == v:t_string
    return key
  endif
  return type(key) == v:t_number ? nr2char(key) : ''
endfunction"}}}

function! s:cancelled(key) abort"{{{
  return a:key ==# "\<Esc>" || a:key ==# "\<C-c>"
endfunction"}}}

function! s:translate_key(key) abort"{{{
  if type(a:key) != v:t_string
        \ || strchars(a:key) != 1
        \ || a:key !~# '[[:punct:]]'
    return a:key
  endif
  let ctx = im#rime#key(char2nr(a:key), 0)
  call im#rime#reset()
  if type(ctx) == v:t_dict && get(ctx, 'accepted', 0)
    let committed = get(ctx, 'committed', '')
    if type(committed) == v:t_string && strchars(committed) == 1
      return committed
    endif
  endif
  return a:key
endfunction"}}}

function! s:read_input() abort"{{{
  let typed = s:read_key()
  if empty(typed) || s:cancelled(typed)
    return {}
  endif
  return {'typed': typed, 'translated': s:translate_key(typed)}
endfunction"}}}

function! s:fallback(mode, modifier, typed, cnt) abort"{{{
  if a:modifier !=# 'i' && a:modifier !=# 'a'
    return s:cancel()
  endif
  let keys = "\<Esc>"
  if a:mode ==# 'x'
    let keys .= mode() ==# 'V' ? 'V' : 'v'
    if a:cnt > 1
      let keys .= a:cnt
    endif
    let keys .= a:modifier . a:typed
    call feedkeys(keys, 'n')
    return ''
  endif

  let op = v:operator
  if empty(op)
    return a:modifier . a:typed
  endif
  let reg = v:register
  if !empty(reg) && reg !=# '"'
    let keys .= '"' . reg
  endif
  if a:cnt > 1
    let keys .= a:cnt
  endif
  let keys .= op . a:modifier . a:typed
  call feedkeys(keys, 'n')
  return ''
endfunction"}}}

function! s:cancel() abort"{{{
  call feedkeys("\<Esc>", 'n')
  return ''
endfunction"}}}

function! im#textobj#trigger(mode, modifier) abort"{{{
  let cnt = v:count1
  let input = s:read_input()
  if empty(input)
    return s:cancel()
  endif
  let specs = im#textobj#config#specifications(input.typed, input.translated)
  if empty(specs)
    let candidates = im#textobj#config#candidates(input.translated)
    if input.translated !=# input.typed || candidates != [input.translated]
      return s:cancel()
    endif
    return s:fallback(a:mode, a:modifier, input.typed, cnt)
  endif
  let s:pending_op = {
        \ 'specs': specs,
        \ 'modifier': a:modifier,
        \ 'count': cnt,
        \ 'mode': a:mode,
        \ }
  return "\<Cmd>call im#textobj#do()\<CR>"
endfunction"}}}

function! s:setup_plugs() abort"{{{
  for mode in ['o', 'x']
    for modifier in ['i', 'a', 'I', 'A']
      execute printf('%snoremap <silent> <expr> <Plug>(im-textobj-%s-%s) im#textobj#trigger(%s, %s)',
            \ mode, mode, modifier, string(mode), string(modifier))
    endfor
  endfor
endfunction"}}}

function! im#textobj#enable() abort"{{{
  if !get(g:, 'im_textobj_enable', 0) || s:enabled
    return
  endif
  if !s:setup
    call s:setup_plugs()
    let s:setup = 1
  endif
  let s:enabled = 1
  silent! doautocmd User RimeTextObjSetup
endfunction"}}}

function! im#textobj#disable() abort"{{{
  if !s:enabled
    return
  endif
  let s:pending_op = {}
  let s:last_op = {}
  let s:enabled = 0
  silent! doautocmd User RimeTextObjRestore
endfunction"}}}

function! im#textobj#do() abort"{{{
  let replay = empty(s:pending_op)
  let op = replay ? s:last_op : s:pending_op
  let s:pending_op = {}
  if empty(op)
    return
  endif
  let repeat_count = op.count
  if replay && v:count > 0
    let repeat_count = v:count1
  endif
  let target = im#textobj#find#find_target(op.specs, repeat_count)
  if empty(target)
    call s:cancel()
    return
  endif
  let range = im#textobj#select#range(target, op.modifier)
  if empty(range)
    call s:cancel()
    return
  endif
  call im#textobj#select#apply(range, op.mode)
  if op.mode ==# 'o'
    let s:last_op = extend(deepcopy(op), {'count': repeat_count})
  endif
endfunction"}}}
