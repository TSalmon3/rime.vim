function! im#replace#frontier() abort"{{{
  " repl_text 之后的光标字节列（1-based），即下一个待覆盖字符。
  let state = im#state#get()
  let before = strcharpart(state.base_line, 0, state.base_cidx)
  return byteidx(before . state.repl_text, strchars(before . state.repl_text)) + 1
endfunction"}}}

function! im#replace#model_line() abort"{{{
  " 当前模型对应的整行文本（不含 preedit）。
  let state = im#state#get()
  let before = strcharpart(state.base_line, 0, state.base_cidx)
  let after  = strcharpart(state.base_line, state.base_cidx + state.repl_len)
  return before . state.repl_text . after
endfunction"}}}

function! im#replace#active() abort"{{{
  return get(im#state#get(), 'repl_active', 0) > 0
endfunction"}}}

function! im#replace#restorable() abort"{{{
  return !empty(im#state#get().repl_text)
endfunction"}}}

function! im#replace#at_frontier() abort"{{{
  return col('.') == im#replace#frontier()
endfunction"}}}

function! s:recompose() abort"{{{
  let state = im#state#get()
  let model = im#replace#model_line()
  if getline('.') !=# model
    silent! undojoin
    call setline(line('.'), model)
  endif
endfunction"}}}

function! im#replace#sync() abort"{{{
  " 把当前位置重新对齐成新的基础快照。用于缓冲区和模型不一致（原生空格、
  " 移动光标到非 frontier 位置等）后的自愈：放弃对更早区域的还原能力。
  let state = im#state#get()
  let line = getline('.')
  let state.base_line = line
  let state.base_cidx = charidx(line, col('.') - 1)
  let state.repl_text = ''
  let state.repl_len  = 0
endfunction"}}}

function! im#replace#dirty() abort"{{{
  return !im#replace#at_frontier() || getline('.') !=# im#replace#model_line()
endfunction"}}}

function! im#replace#commit(committed) abort"{{{
  let state = im#state#get()
  let state.repl_text .= a:committed
  let state.repl_len += strchars(a:committed)
  call s:recompose()
  call cursor(line('.'), im#replace#frontier())
endfunction"}}}

function! im#replace#can_restore() abort"{{{
  return im#replace#active()
        \ && im#replace#at_frontier()
        \ && im#replace#restorable()
endfunction"}}}

function! im#replace#bs() abort"{{{
  " 上屏后 BS：弹掉 repl_text 末尾一个字符，并还原该字符吃掉的
  " 基础字符（R/gR 均按字符数）。
  let state = im#state#get()
  if empty(state.repl_text)
    return
  endif
  let state.repl_text = strcharpart(state.repl_text, 0, strchars(state.repl_text) - 1)
  let state.repl_len = strchars(state.repl_text)
  call s:recompose()
  call cursor(line('.'), im#replace#frontier())
endfunction"}}}

function! im#replace#ctrl_w() abort"{{{
  " 上屏后 CTRL-W：删掉 repl_text 末尾一个空白分隔的 WORD（含其后空白），
  " 还原该词覆盖掉的基础字符。
  let state = im#state#get()
  if empty(state.repl_text)
    return
  endif
  let word = matchstr(state.repl_text, '\S\+\s*$')
  if empty(word)
    return
  endif
  let state.repl_text = strpart(state.repl_text, 0, len(state.repl_text) - len(word))
  let state.repl_len = strchars(state.repl_text)
  call s:recompose()
  call cursor(line('.'), im#replace#frontier())
endfunction"}}}

function! im#replace#ctrl_u() abort"{{{
  " 上屏后 CTRL-U：还原本会话内覆盖的全部基础字符。
  let state = im#state#get()
  if empty(state.repl_text)
    return
  endif
  let state.repl_text = ''
  let state.repl_len  = 0
  call s:recompose()
  call cursor(line('.'), im#replace#frontier())
endfunction"}}}

function! im#replace#on_cursor_moved() abort"{{{
  " 光标离开 frontier 后放弃该会话的复原能力（对齐原生 R 模式）。
  " 组词期间插件会主动移动光标，跳过。
  let state = im#state#get()
  if !state.repl_active || im#state#composing()
    return
  endif
  if im#replace#restorable() && im#replace#dirty()
    call im#replace#sync()
  endif
endfunction"}}}

function! im#replace#enter() abort"{{{
  if !get(g:, 'im_replace_mode', 0)
    return
  endif

  let state = im#state#get()

  let state.repl_active = 1
  let line = getline('.')
  let state.base_line = line
  let state.base_cidx = charidx(line, col('.') - 1)
  let state.repl_text = ''
  let state.repl_len  = 0
endfunction"}}}

function! im#replace#leave() abort"{{{
  " 离开替换模式：把已上屏文本落定后清除会话状态，放弃复原能力。
  if !im#replace#active()
    return
  endif
  call s:recompose()
  call im#state#reset_replace()
endfunction"}}}
