let s:kShiftMask = 0x01
let s:kCtrlMask = 0x04
let s:kReleaseMask = 0x40000000  " librime kReleaseMask = 1 << 30

let s:keys = {
      \ 'bs'             : [0xff08, 0,              "\<bs>"],
      \ 's-bs'           : [0xff08, s:kShiftMask,   "\<bs>"],
      \ 'left'           : [0xff51, 0,              "\<left>"],
      \ 'right'          : [0xff53, 0,              "\<right>"],
      \ 'up'             : [0xff52, 0,              "\<up>"],
      \ 'down'           : [0xff54, 0,              "\<down>"],
      \ 'home'           : [0xff50, 0,              "\<home>"],
      \ 'end'            : [0xff57, 0,              "\<end>"],
      \ 'tab'            : [0xff09, 0,              "\<tab>"],
      \ 's-tab'          : [0xff09, s:kShiftMask,   "\<s-tab>"],
      \ 'pagedown'       : [0xff56, 0,              "\<pagedown>"],
      \ 'pageup'         : [0xff55, 0,              "\<pageup>"],
      \ 'return'         : [0xff0d, 0,              "\<cr>"],
      \ 'escape'         : [0xff1b, 0,              "\<esc>"],
      \ 'space'          : [0x0020, 0,              "\<space>"],
      \ 'c-u'            : [0x75,   s:kCtrlMask,    "\<c-u>"],
      \ 'c-d'            : [0xffff, s:kShiftMask,   "\<c-d>"],
      \ 'c-f'            : [0x66,   s:kCtrlMask,    "\<c-f>"],
      \ 'c-b'            : [0x62,   s:kCtrlMask,    "\<c-b>"],
      \ 'c-`'            : [0x60,   s:kCtrlMask,    "\<c-`>"],
      \ 'f4'             : [0xffc1, 0,              "\<f4>"],
      \ 'l-shift'        : [0xffe1, 0,              ""],
      \ 'l-shift-release': [0xffe1, s:kReleaseMask, ""],
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
      \ 'specials': ['<bs>', '<s-bs>', '<left>', '<right>', '<up>', '<down>','<c-a>', '<c-e>', '<space>', '<cr>', '<c-j>', '<c-k>', '<c-h>', '<c-l>',
      \ '<tab>', '<s-tab>', '<c-w>', '<c-u>', '<c-n>', '<c-p>', '<pagedown>', '<pageup>', '<c-f>', '<c-b>', '<c-d>', '<esc>']
      \ }

function! im#keymap#setup() abort"{{{
  for key in s:mapped_keys.letters
    execute 'lnoremap <buffer><expr> ' . key . ' im#keymap#char(' . string(key) . ')'
  endfor

  for key in s:mapped_keys.symbols
    execute 'lnoremap <buffer><expr> ' . key . ' im#keymap#char(' . string(key) . ')'
  endfor

  for key in s:mapped_keys.numbers
    execute 'lnoremap <buffer><expr> ' . key . ' im#keymap#char(' . string(key) . ')'
  endfor

  lnoremap <buffer><expr> <bs>       im#keymap#bs()
  lnoremap <buffer><expr> <s-bs>     im#keymap#shift_bs()
  lnoremap <buffer><expr> <c-u>      im#keymap#ctrl_u()
  lnoremap <buffer><expr> <c-w>      im#keymap#ctrl_w()
  lnoremap <buffer><expr> <c-d>      im#keymap#special('c-d')
  lnoremap <buffer><expr> <left>     im#keymap#special('left')
  lnoremap <buffer><expr> <right>    im#keymap#special('right')
  lnoremap <buffer><expr> <up>       im#keymap#special('up')
  lnoremap <buffer><expr> <down>     im#keymap#special('down')
  lnoremap <buffer><expr> <c-h>     im#keymap#special('left')
  lnoremap <buffer><expr> <c-l>    im#keymap#special('right')
  lnoremap <buffer><expr> <c-k>     im#keymap#special('up')
  lnoremap <buffer><expr> <c-j>     im#keymap#special('down')
  lnoremap <buffer><expr> <c-n>      im#keymap#special('up')
  lnoremap <buffer><expr> <c-p>      im#keymap#special('down')
  lnoremap <buffer><expr> <c-a>      im#keymap#special('home')
  lnoremap <buffer><expr> <c-e>      im#keymap#special('end')
  lnoremap <buffer><expr> <space>    im#keymap#special('space')
  lnoremap <buffer><expr> <cr>       im#keymap#special('return')
  lnoremap <buffer><expr> <tab>      im#keymap#special('tab')
  lnoremap <buffer><expr> <s-tab>    im#keymap#special('s-tab')
  lnoremap <buffer><expr> <pagedown> im#keymap#special('pagedown')
  lnoremap <buffer><expr> <pageup>   im#keymap#special('pageup')
  lnoremap <buffer><expr> <c-f>      im#keymap#special('pagedown')
  lnoremap <buffer><expr> <c-b>      im#keymap#special('pageup')
  lnoremap <buffer><expr> <esc>      im#keymap#special('escape')

  silent! doautocmd User RimeKeymapSetup
endfunction"}}}

function! im#keymap#clear() abort"{{{
  for key in s:mapped_keys.letters + s:mapped_keys.numbers +
        \ s:mapped_keys.symbols + s:mapped_keys.specials
    silent! execute 'lunmap <buffer>' . key
  endfor

  silent! doautocmd User RimeKeymapClear
endfunction"}}}

function! im#keymap#char(char) abort"{{{
  if !im#replace#active() && mode(1) =~# '^R'
    return a:char
  endif
  if !im#state#composing()
    call im#state#start_composition()
  endif
  return "\<Cmd>call im#engine#key(" . char2nr(a:char) . ", 0)\<CR>"
endfunction"}}}

function! im#keymap#toggle_scheme() abort"{{{
  let [code, mask, literal] = s:keys['c-`']
  if !im#state#composing()
    call im#state#start_composition()
  endif
  return "\<Cmd>call im#engine#key(" . code . ", " . mask . ")\<CR>"
endfunction"}}}

function! im#keymap#cancel() abort"{{{
  let [code, mask, literal] = s:keys["escape"]
  if !im#state#composing()
    return "\<c-u>"
  endif
  return "\<Cmd>call im#engine#key(" . code . ", " . mask . ")\<CR>"
endfunction"}}}

function! im#keymap#toggle_ascii_mode(...) abort"{{{
  let style = a:0 ? a:1 : 'commit_code'
  if empty(style)
    let style = 'commit_code'
  endif
  return "\<Cmd>call im#engine#ascii_switch('" . style . "')\<CR>"
endfunction"}}}

function! im#keymap#ctrl_w() abort"{{{
  let [code, mask, literal] = s:keys["s-bs"]
  if !im#state#composing()
    if im#replace#can_restore()
      return "\<Cmd>call im#replace#ctrl_w()\<CR>"
    endif
    return "\<c-w>"
  endif
  return "\<Cmd>call im#engine#key(" . code . ", " . mask . ")\<CR>"
endfunction"}}}

function! im#keymap#ctrl_u() abort"{{{
  let [code, mask, literal] = s:keys["escape"]
  if !im#state#composing()
    if im#replace#can_restore()
      return "\<Cmd>call im#replace#ctrl_u()\<CR>"
    endif
    return "\<c-u>"
  endif
  return "\<Cmd>call im#engine#key(" . code . ", " . mask . ")\<CR>"
endfunction"}}}

function! im#keymap#special(name) abort"{{{
  let [code, mask, literal] = s:keys[a:name]
  if !im#state#composing()
    return literal
  endif
  return "\<Cmd>call im#engine#key(" . code . ", " . mask . ")\<CR>"
endfunction"}}}

function! im#keymap#bs() abort"{{{
  let [code, mask, literal] = s:keys["bs"]
  if !im#state#composing()
    if im#replace#can_restore()
      return "\<Cmd>call im#replace#bs()\<CR>"
    endif
    if im#pair#should_bs()
      return im#pair#bs()
    endif
    return "\<bs>"
  endif
  return "\<Cmd>call im#engine#key(" . code . ", " . mask . ")\<CR>"
endfunction"}}}

function! im#keymap#shift_bs() abort"{{{
  let [code, mask, literal] = s:keys["s-bs"]
  if !im#state#composing()
    if im#replace#can_restore()
      return "\<Cmd>call im#replace#bs()\<CR>"
    endif
    if im#pair#should_bs()
      return "\<bs>"
    endif
    return "\<s-bs>"
  endif
  return "\<Cmd>call im#engine#key(" . code . ", " . mask . ")\<CR>"
endfunction"}}}
