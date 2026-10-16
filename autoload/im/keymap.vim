let s:KC = im#keycode#keycodes()
let s:MK = im#keycode#mask()
let s:keys = {
      \ '<del>' :      [s:KC.Delete,    0],
      \ '<bs>' :       [s:KC.BackSpace, 0],
      \ '<s-bs>' :     [s:KC.BackSpace, s:MK.Shift],
      \ '<left>' :     [s:KC.Left,      0],
      \ '<right>' :    [s:KC.Right,     0],
      \ '<up>' :       [s:KC.Up,        0],
      \ '<down>' :     [s:KC.Down,      0],
      \ '<home>' :     [s:KC.Home,      0],
      \ '<end>' :      [s:KC.End,       0],
      \ '<tab>' :      [s:KC.Right,     s:MK.Shift],
      \ '<s-tab>' :    [s:KC.Left,      s:MK.Shift],
      \ '<pagedown>' : [s:KC.Page_Down, 0],
      \ '<pageup>' :   [s:KC.Page_Up,   0],
      \ '<cr>' :       [s:KC.Return,    0],
      \ '<esc>' :      [s:KC.Escape,    0],
      \ '<space>' :    [s:KC.space,     0],
      \ '<c-u>' :      [s:KC.Escape,    0],
      \ '<c-f>' :      [s:KC.Right,     0],
      \ '<c-b>' :      [s:KC.Left,      0],
      \ '<c-`>' :      [s:KC.grave,     s:MK.Control],
      \ '<f4>' :       [s:KC.F4,        0],
      \ '<c-h>' :      [s:KC.BackSpace, 0],
      \ '<c-d>' :      [s:KC.Delete,    0],
      \ '<c-l>' :      [s:KC.Delete,    s:MK.Shift],
      \ '<c-k>' :      [s:KC.Up,        0],
      \ '<c-j>' :      [s:KC.Down,      0],
      \ '<c-n>' :      [s:KC.Down,      0],
      \ '<c-p>' :      [s:KC.Up,        0],
      \ '<c-a>' :      [s:KC.Home,      0],
      \ '<c-e>' :      [s:KC.End,       0],
      \ '<c-t>' :      [s:KC.t,         s:MK.Control],
      \ }

let s:mapped_keys = {
      \ 'letters': split('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ', '\zs'),
      \ 'symbols' : ['`','-','+','=','!','$','@','#','%','&','^','*','_','(',')','[',']','{','}','<','>','\','/','~',';',':',',','.','?',"'",'"'],
      \ 'numbers': ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'],
      \ 'specials': ['<bs>', '<s-bs>', '<left>', '<right>', '<up>', '<down>','<c-a>', '<c-e>', '<space>', '<cr>', '<c-j>', '<c-k>', '<c-h>', '<c-l>',
      \ '<tab>', '<s-tab>', '<c-w>', '<c-u>', '<c-n>', '<c-p>', '<pagedown>', '<pageup>', '<c-f>', '<c-b>',
      \ '<esc>', '<home>', '<end>', '<c-t>', '<c-d>']
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
  lnoremap <buffer><expr> <c-h>      im#keymap#ctrl_h()
  lnoremap <buffer><expr> <c-d>      im#keymap#ctrl_d()
  lnoremap <buffer><expr> <c-j>      im#keymap#ctrl_j()
  lnoremap <buffer><expr> <c-k>      im#keymap#ctrl_k()
  lnoremap <buffer><expr> <c-a>      im#keymap#ctrl_a()
  lnoremap <buffer><expr> <c-e>      im#keymap#ctrl_e()

  for key in s:mapped_keys.specials
    if index(['<bs>', '<s-bs>', '<c-u>', '<c-w>',
          \ '<c-a>', '<c-e>', '<c-h>', '<c-j>', '<c-k>', '<c-d>'], key) >= 0
      continue
    endif
    let name = substitute(key, '[<>]', '', 'g')
    execute 'lnoremap <buffer><expr> ' . key . ' im#keymap#special(' . string(name) . ')'
  endfor

  silent! doautocmd User RimeKeymapSetup
endfunction"}}}

function! im#keymap#clear() abort"{{{
  for key in s:mapped_keys.letters + s:mapped_keys.numbers +
        \ s:mapped_keys.symbols + s:mapped_keys.specials
    silent! execute 'lunmap <buffer> ' . key
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

function! im#keymap#special(name) abort"{{{
  let [code, mask] = s:keys['<' . a:name . '>']
  if !im#state#composing()
    return eval('"\<' . a:name . '>"')
  endif
  return "\<Cmd>call im#engine#key(" . code . ", " . mask . ")\<CR>"
endfunction"}}}

function! im#keymap#ctrl_h() abort"{{{
  let [code, mask] = s:keys["<bs>"]
  if !im#state#composing()
    return "\<left>"
  endif
  return "\<Cmd>call im#engine#key(" . code . ", " . mask . ")\<CR>"
endfunction"}}}

function! im#keymap#ctrl_d() abort"{{{
  let [code, mask] = s:keys["<del>"]
  if !im#state#composing()
    return "\<del>"
  endif
  return "\<Cmd>call im#engine#key(" . code . ", " . mask . ")\<CR>"
endfunction"}}}

function! im#keymap#ctrl_j() abort"{{{
  let [code, mask] = s:keys["<down>"]
  if !im#state#composing()
    return "\<down>"
  endif
  return "\<Cmd>call im#engine#key(" . code . ", " . mask . ")\<CR>"
endfunction"}}}

function! im#keymap#ctrl_k() abort"{{{
  let [code, mask] = s:keys["<up>"]
  if !im#state#composing()
    return "\<up>"
  endif
  return "\<Cmd>call im#engine#key(" . code . ", " . mask . ")\<CR>"
endfunction"}}}

function! im#keymap#ctrl_a() abort"{{{
  let [code, mask] = s:keys["<home>"]
  if !im#state#composing()
    return "\<home>"
  endif
  return "\<Cmd>call im#engine#key(" . code . ", " . mask . ")\<CR>"
endfunction"}}}

function! im#keymap#ctrl_e() abort"{{{
  let [code, mask] = s:keys["<end>"]
  if !im#state#composing()
    return "\<end>"
  endif
  return "\<Cmd>call im#engine#key(" . code . ", " . mask . ")\<CR>"
endfunction"}}}

function! im#keymap#ctrl_w() abort"{{{
  let [code, mask] = s:keys["<s-bs>"]
  if !im#state#composing()
    if im#replace#can_restore()
      return "\<Cmd>call im#replace#ctrl_w()\<CR>"
    endif
    return "\<c-w>"
  endif
  return "\<Cmd>call im#engine#key(" . code . ", " . mask . ")\<CR>"
endfunction"}}}

function! im#keymap#ctrl_u() abort"{{{
  let [code, mask] = s:keys['<esc>']
  if !im#state#composing()
    if im#replace#can_restore()
      return "\<Cmd>call im#replace#ctrl_u()\<CR>"
    endif
    return "\<c-u>"
  endif
  return "\<Cmd>call im#engine#key(" . code . ", " . mask . ")\<CR>"
endfunction"}}}

function! im#keymap#bs() abort"{{{
  let [code, mask] = s:keys['<bs>']
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
  let [code, mask] = s:keys["<s-bs>"]
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

function! im#keymap#toggle_scheme() abort"{{{
  let [code, mask] = s:keys['<c-`>']
  if !im#state#composing()
    call im#state#start_composition()
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
