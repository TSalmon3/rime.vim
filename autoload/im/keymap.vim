let s:kShiftMask = 1
let s:kCtrlMask = 4

let s:keys = {
      \ 'bs'      : [0xff08, 0,            "\<bs>"],
      \ 's-bs'    : [0xff08, s:kShiftMask, "\<bs>"],
      \ 'left'    : [0xff51, 0,            "\<left>"],
      \ 'right'   : [0xff53, 0,            "\<right>"],
      \ 'up'      : [0xff52, 0,            "\<up>"],
      \ 'down'    : [0xff54, 0,            "\<down>"],
      \ 'home'    : [0xff50, 0,            "\<home>"],
      \ 'end'     : [0xff57, 0,            "\<end>"],
      \ 'tab'     : [0xff09, 0,            "\<tab>"],
      \ 's-tab'   : [0xff09, s:kShiftMask, "\<s-tab>"],
      \ 'pagedown': [0xff56, 0,            "\<pagedown>"],
      \ 'pageup'  : [0xff55, 0,            "\<pageup>"],
      \ 'return'  : [0xff0d, 0,            "\<cr>"],
      \ 'escape'  : [0xff1b, 0,            "\<esc>"],
      \ 'space'   : [0x0020, 0,            "\<space>"],
      \ 'c-u'     : [0x75,   s:kCtrlMask,  "\<c-u>"],
      \ 'c-d'     : [0xffff, s:kShiftMask, "\<c-d>"],
      \ 'c-f'     : [0x66,   s:kCtrlMask,  "\<c-f>"],
      \ 'c-b'     : [0x62,   s:kCtrlMask,  "\<c-b>"],
      \ 'c-`'     : [0x60,   s:kCtrlMask,  "\<c-`>"],
      \ 'f4'      : [0xffc1, 0,            "\<f4>"],
      \ }

" key -> 回放字符串 反查表，由 s:keys 生成，
" 键为 "code:mask"（如 "65293:0"、"65289:1"）。
let s:keysym = {}
for [key, entry] in items(s:keys)
  let s:keysym[entry[0] . ':' . entry[1]] = entry[2]
endfor

function! im#keymap#fallback(keycode, mask) abort"{{{
  let literal = get(s:keysym, a:keycode . ':' . a:mask, '')
  if literal !=# ''
    return literal
  endif
  if a:mask == s:kCtrlMask && nr2char(a:keycode) =~# '^[a-z]$'
    return '\<c-' . nr2char(a:keycode) . '>'
  endif
  return a:keycode >= 0x20 ? nr2char(a:keycode) : ''
endfunction"}}}

let s:mapped_keys = {
      \ 'letters': split('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ', '\zs'),
      \ 'symbols' : ['`','-','+','=','!','$','@','#','%','&','^','*','_','(',')','[',']','{','}','<','>','\','/','~',';',':',',','.','?',"'",'"'],
      \ 'numbers': ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'],
      \ 'specials': ['<bs>', '<s-bs>', '<left>', '<right>', '<up>', '<down>','<c-a>', '<c-e>', '<space>', '<cr>',
      \ '<tab>', '<s-tab>', '<c-w>', '<c-u>', '<c-n>', '<c-p>', '<pagedown>', '<pageup>', '<c-f>', '<c-b>', '<c-d>']
      \ }

function! im#keymap#setup() abort"{{{
  for key in s:mapped_keys.letters
    execute 'lnoremap <expr> ' . key . ' im#keymap#char(' . string(key) . ')'
  endfor

  for key in s:mapped_keys.symbols
    execute 'lnoremap <expr> ' . key . ' im#keymap#char(' . string(key) . ')'
  endfor

  for key in s:mapped_keys.numbers
    execute 'lnoremap <expr> ' . key . ' im#keymap#char(' . string(key) . ')'
  endfor

  lnoremap <expr> <bs>       im#keymap#backspace('bs')
  lnoremap <expr> <s-bs>     im#keymap#backspace('s-bs')
  lnoremap <expr> <c-u>      im#keymap#ctrl_u()
  " lnoremap <expr> <c-w>      im#keymap#special('s-bs')
  lnoremap <expr> <c-w>      im#keymap#ctrl_w()
  lnoremap <expr> <c-d>      im#keymap#special('c-d')
  lnoremap <expr> <left>     im#keymap#special('left')
  lnoremap <expr> <right>    im#keymap#special('right')
  lnoremap <expr> <up>       im#keymap#special('up')
  lnoremap <expr> <down>     im#keymap#special('down')
  lnoremap <expr> <c-n>      im#keymap#special('up')
  lnoremap <expr> <c-p>      im#keymap#special('down')
  lnoremap <expr> <c-a>      im#keymap#special('home')
  lnoremap <expr> <c-e>      im#keymap#special('end')
  lnoremap <expr> <space>    im#keymap#special('space')
  lnoremap <expr> <cr>       im#keymap#special('return')
  lnoremap <expr> <tab>      im#keymap#special('tab')
  lnoremap <expr> <s-tab>    im#keymap#special('s-tab')
  lnoremap <expr> <pagedown> im#keymap#special('pagedown')
  lnoremap <expr> <pageup>   im#keymap#special('pageup')
  lnoremap <expr> <c-f>      im#keymap#special('pagedown')
  lnoremap <expr> <c-b>      im#keymap#special('pageup')

  silent! doautocmd User RimeKeymapSetup
endfunction"}}}

function! im#keymap#clear() abort"{{{
  for key in s:mapped_keys.letters + s:mapped_keys.numbers +
        \ s:mapped_keys.symbols + s:mapped_keys.specials
    silent! execute 'lunmap ' . key
  endfor
  silent! doautocmd User RimeKeymapClear
endfunction"}}}

function! s:begin_composition() abort"{{{
  let state = im#state#get()
  if im#replace#active() && im#replace#dirty()
    call im#replace#sync()
  endif
  let state.boundary    = col('.')
  let state.preedit_len = 0
  let state.cursor_pos  = 0
  let state.sel_start   = 0
  let state.sel_end     = 0
endfunction"}}}

function! s:replace_passive() abort"{{{
  return !get(g:, 'im_replace_mode', 0) && mode(1) =~# '^R'
endfunction"}}}

function! im#keymap#char(char) abort"{{{
  if s:replace_passive()
    return a:char
  endif
  if !im#state#composing()
    call s:begin_composition()
  endif
  return "\<Cmd>call im#key(" . char2nr(a:char) . ", 0)\<CR>"
endfunction"}}}

function! im#keymap#toggle_scheme(name) abort"{{{
  let [code, mask, literal] = s:keys[a:name]
  if !im#state#composing()
    call s:begin_composition()
  endif
  return "\<Cmd>call im#key(" . code . ", " . mask . ")\<CR>"
endfunction"}}}

function! im#keymap#cancel() abort"{{{
  let [code, mask, literal] = s:keys["escape"]
  if !im#state#composing()
    return "\<c-u>"
  endif
  return "\<Cmd>call im#key(" . code . ", " . mask . ")\<CR>"
endfunction"}}}

function! im#keymap#ctrl_w() abort"{{{
  let [code, mask, literal] = s:keys["s-bs"]
  if !im#state#composing()
    if im#replace#active()
          \ && im#replace#at_frontier()
          \ && im#replace#restorable()
      return "\<Cmd>call im#replace#ctrl_w()\<CR>"
    endif
    return "\<c-w>"
  endif
  return "\<Cmd>call im#key(" . code . ", " . mask . ")\<CR>"
endfunction"}}}

function! im#keymap#ctrl_u() abort"{{{
  let [code, mask, literal] = s:keys["escape"]
  if !im#state#composing()
    if im#replace#active()
          \ && im#replace#at_frontier()
          \ && im#replace#restorable()
      return "\<Cmd>call im#replace#ctrl_u()\<CR>"
    endif
    return "\<c-u>"
  endif
  return "\<Cmd>call im#key(" . code . ", " . mask . ")\<CR>"
endfunction"}}}

function! im#keymap#special(name) abort"{{{
  let [code, mask, literal] = s:keys[a:name]
  if !im#state#composing()
    return literal
  endif
  return "\<Cmd>call im#key(" . code . ", " . mask . ")\<CR>"
endfunction"}}}

function! im#keymap#backspace(name) abort"{{{
  let [code, mask, literal] = s:keys[a:name]
  if !im#state#composing()
    if (a:name ==# 'bs' || a:name ==# 's-bs')
          \ && im#replace#active()
          \ && im#replace#at_frontier()
          \ && im#replace#restorable()
      return "\<Cmd>call im#replace#bs()\<CR>"
    endif
    return literal
  endif
  return "\<Cmd>call im#key(" . code . ", " . mask . ")\<CR>"
endfunction"}}}

function! im#keymap#r() abort"{{{
  let state = im#state#get()
  if !state.started
    call feedkeys('r', 'ni')
    return
  endif

  let c = getchar()
  if c == 27 || c == 3 " <Esc> / <C-c>：取消
    return
  endif

  let char = type(c) == type(0) ? nr2char(c) : c

  if index(s:mapped_keys.symbols, char) < 0
    call feedkeys('r' . char, 'ni')
    return
  endif

  let ctx = im#rime#key(char2nr(char), 0)
  let out = (ctx.accepted && !empty(get(ctx, 'committed', ''))) ? ctx.committed : char
  call im#rime#reset()

  let lnum = line('.')
  let line = getline(lnum)
  let cidx = charidx(line, col('.') - 1)
  let before = strcharpart(line, 0, cidx)
  let after  = strcharpart(line, cidx + 1)
  call setline(lnum, before . out . after)
  call cursor(lnum, byteidx(before, strchars(before)) + 1)
endfunction"}}}
