let s:session = {
      \ 'active'    : 0,
      \ 'base_line' : '',
      \ 'base_cidx' : 0,
      \ 'text'      : '',
      \ 'len'       : 0,
      \ }

let s:symbols = ['`','-','+','=','!','$','@','#','%','&','^','*','_','(',')','[',']','{','}','<','>','\','/','~',';',':',',','.','?',"'",'"']

function! im#replace#frontier() abort"{{{
  " text 之后的光标字节列（1-based），即下一个待覆盖字符。
  let before = strcharpart(s:session.base_line, 0, s:session.base_cidx)
  return byteidx(before . s:session.text, strchars(before . s:session.text)) + 1
endfunction"}}}

function! im#replace#model_line() abort"{{{
  " 当前模型对应的整行文本（不含 preedit）。
  let before = strcharpart(s:session.base_line, 0, s:session.base_cidx)
  let after  = strcharpart(s:session.base_line, s:session.base_cidx + s:session.len)
  return before . s:session.text . after
endfunction"}}}

function! im#replace#active() abort"{{{
  return s:session.active > 0
endfunction"}}}

function! im#replace#restorable() abort"{{{
  return !empty(s:session.text)
endfunction"}}}

function! im#replace#at_frontier() abort"{{{
  return col('.') == im#replace#frontier()
endfunction"}}}

function! s:recompose() abort"{{{
  let model = im#replace#model_line()
  if getline('.') !=# model
    silent! undojoin
    call setline(line('.'), model)
  endif
endfunction"}}}

function! im#replace#sync() abort"{{{
  " 把当前位置重新对齐成新的基础快照。用于缓冲区和模型不一致（原生空格、
  " 移动光标到非 frontier 位置等）后的自愈：放弃对更早区域的还原能力。
  let line = getline('.')
  let s:session.base_line = line
  let s:session.base_cidx = charidx(line, col('.') - 1)
  let s:session.text = ''
  let s:session.len  = 0
endfunction"}}}

" virtcol 补空格时同步加宽基础快照（原 state#start_composition 内联逻辑）。
function! im#replace#pad(vpad) abort"{{{
  if a:vpad <= 0 || !im#replace#active()
    return
  endif
  let s:session.base_line = s:session.base_line . repeat(' ', a:vpad)
  let s:session.base_cidx = s:session.base_cidx + a:vpad
endfunction"}}}

function! im#replace#dirty() abort"{{{
  return !im#replace#at_frontier() || getline('.') !=# im#replace#model_line()
endfunction"}}}

function! im#replace#commit(committed) abort"{{{
  let s:session.text .= a:committed
  let s:session.len += strchars(a:committed)
  call s:recompose()
  call cursor(line('.'), im#replace#frontier())
endfunction"}}}

function! im#replace#can_restore() abort"{{{
  return im#replace#active()
        \ && im#replace#at_frontier()
        \ && im#replace#restorable()
endfunction"}}}

function! im#replace#bs() abort"{{{
  " 上屏后 BS：弹掉 text 末尾一个字符，并还原该字符吃掉的
  " 基础字符（R/gR 均按字符数）。
  if empty(s:session.text)
    return
  endif
  let s:session.text = strcharpart(s:session.text, 0, strchars(s:session.text) - 1)
  let s:session.len = strchars(s:session.text)
  call s:recompose()
  call cursor(line('.'), im#replace#frontier())
endfunction"}}}

function! im#replace#ctrl_w() abort"{{{
  " 上屏后 CTRL-W：删掉 text 末尾一个空白分隔的 WORD（含其后空白），
  " 还原该词覆盖掉的基础字符。
  if empty(s:session.text)
    return
  endif
  let word = matchstr(s:session.text, '\S\+\s*$')
  if empty(word)
    return
  endif
  let s:session.text = strpart(s:session.text, 0, len(s:session.text) - len(word))
  let s:session.len = strchars(s:session.text)
  call s:recompose()
  call cursor(line('.'), im#replace#frontier())
endfunction"}}}

function! im#replace#ctrl_u() abort"{{{
  " 上屏后 CTRL-U：还原本会话内覆盖的全部基础字符。
  if empty(s:session.text)
    return
  endif
  let s:session.text = ''
  let s:session.len  = 0
  call s:recompose()
  call cursor(line('.'), im#replace#frontier())
endfunction"}}}

function! im#replace#discard() abort"{{{
  " 丢弃当前 preedit：按模型重建整行，还原被 preedit 覆盖的基础字符，
  " 光标回到 frontier；已上屏的 text 保持不变。供 Esc（engine#reset）
  " 在替换模式下调用——与插入模式不同，这里不上屏原始编码。
  call s:recompose()
  call cursor(line('.'), im#replace#frontier())
endfunction"}}}

function! im#replace#on_cursor_moved() abort"{{{
  " 光标离开 frontier 后放弃该会话的复原能力（对齐原生 R 模式）。
  " 组词期间插件会主动移动光标，跳过。
  if !s:session.active || im#state#composing()
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

  let line = getline('.')
  let s:session.active = 1
  let s:session.base_line = line
  let s:session.base_cidx = charidx(line, col('.') - 1)
  let s:session.text = ''
  let s:session.len  = 0
endfunction"}}}

function! im#replace#leave() abort"{{{
  " 离开替换模式：把已上屏文本落定后清除会话状态，放弃复原能力。
  if !im#replace#active()
    return
  endif
  call s:recompose()
  call im#replace#reset()
endfunction"}}}

function! im#replace#reset() abort"{{{
  let s:session.active = 0
  let s:session.base_line = ''
  let s:session.base_cidx = 0
  let s:session.text = ''
  let s:session.len  = 0
endfunction"}}}

function! im#replace#r() abort"{{{
  " normal 模式 r 单字符替换：符号走 Rime 换算，其余回放原生 r。
  let state = im#state#get()
  if !state.started
    call feedkeys('r', 'ni')
    return
  endif

  let c = getchar()
  if c == 27 || c == 3 " <Esc> / <C-c>：取消
    return
  endif

  let char = type(c) == v:t_number ? nr2char(c) : c

  if index(s:symbols, char) < 0
    call feedkeys('r' . char, 'ni')
    return
  endif

  let ctx = im#rime#key(char2nr(char), 0)
  let out = (ctx.accepted && !empty(get(ctx, 'committed', ''))) ? ctx.committed : char
  call im#state#emit(im#state#sync_notifications(ctx))
  call im#state#emit(im#state#reset_backend())

  " 单字符替换（非组合路径）：charidx 语义与组合路径不同。
  let lnum = line('.')
  let line = getline(lnum)
  let cidx = charidx(line, col('.') - 1)
  let before = strcharpart(line, 0, cidx)
  let after = strcharpart(line, cidx + 1)
  call setline(lnum, before . out . after)
  call cursor(lnum, byteidx(before, strchars(before)) + 1)
endfunction"}}}
