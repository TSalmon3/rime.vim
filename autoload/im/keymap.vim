let s:keys = {
      \ 'bs'        : [g:RIME_KEYCODE.BackSpace, 0, '<bs>'],
      \ 's-bs'      : [g:RIME_KEYCODE.BackSpace, g:RIME_MASK.Shift, '<s-bs>'],
      \ 'left'      : [g:RIME_KEYCODE.Left,      0, '<left>'],
      \ 'right'     : [g:RIME_KEYCODE.Right,     0, '<right>'],
      \ 'up'        : [g:RIME_KEYCODE.Up,        0, '<up>'],
      \ 'down'      : [g:RIME_KEYCODE.Down,      0, '<down>'],
      \ 'home'      : [g:RIME_KEYCODE.Home,      0, '<home>'],
      \ 'end'       : [g:RIME_KEYCODE.End,       0, '<end>'],
      \ 'tab'       : [g:RIME_KEYCODE.Tab,       0, '<tab>'],
      \ 's-tab'     : [g:RIME_KEYCODE.Tab,       g:RIME_MASK.Shift, '<s-tab>'],
      \ 'pagedown'  : [g:RIME_KEYCODE.Page_Down, 0, '<pagedown>'],
      \ 'pageup'    : [g:RIME_KEYCODE.Page_Up,   0, '<pageup>'],
      \ 'cr'        : [g:RIME_KEYCODE.Return,    0, '<cr>'],
      \ 'esc'       : [g:RIME_KEYCODE.Escape,    0, '<esc>'],
      \ 'space'     : [g:RIME_KEYCODE.space,     0, '<space>'],
      \ 'c-u'       : [g:RIME_KEYCODE.u,         g:RIME_MASK.Control, '<c-u>'],
      \ 'c-d'       : [g:RIME_KEYCODE.Delete,    g:RIME_MASK.Shift, '<c-d>'],
      \ 'c-f'       : [g:RIME_KEYCODE.Page_Down, 0, '<c-f>'],
      \ 'c-b'       : [g:RIME_KEYCODE.Page_Up,   0, '<c-b>'],
      \ 'c-`'       : [g:RIME_KEYCODE.grave,     g:RIME_MASK.Control, '<c-`>'],
      \ 'f4'        : [g:RIME_KEYCODE.F4,        0, '<f4>'],
      \ 'c-h'       : [g:RIME_KEYCODE.Left,      0, '<c-h>'],
      \ 'c-l'       : [g:RIME_KEYCODE.Right,     0, '<c-l>'],
      \ 'c-k'       : [g:RIME_KEYCODE.Up,        0, '<c-k>'],
      \ 'c-j'       : [g:RIME_KEYCODE.Down,      0, '<c-j>'],
      \ 'c-n'       : [g:RIME_KEYCODE.Down,      0, '<c-n>'],
      \ 'c-p'       : [g:RIME_KEYCODE.Up,        0, '<c-p>'],
      \ 'c-a'       : [g:RIME_KEYCODE.Home,      0, '<c-a>'],
      \ 'c-e'       : [g:RIME_KEYCODE.End,       0, '<c-e>'],
      \ 'c-t'       : [g:RIME_KEYCODE.t,         g:RIME_MASK.Control, '<c-t>'],
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
  for key in s:mapped_keys.specials
    if index(['<bs>', '<s-bs>', '<c-u>', '<c-w>'], key) >= 0
      continue
    endif
    execute 'lnoremap <buffer><expr> ' . key . ' im#keymap#special(' . string(key[1:-2]) . ')'
  endfor

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

function! im#keymap#special(name) abort"{{{
  let [code, mask, fbkey] = s:keys[a:name]
  let fb = eval('"' . '\' . fbkey . '"')
  if !im#state#composing()
    return fb
  endif
  return "\<Cmd>call im#engine#key(" . code . ", " . mask . ", " . string(fb) . ")\<CR>"
endfunction"}}}

function! im#keymap#ctrl_w() abort"{{{
  let [code, mask, _] = s:keys["s-bs"]
  if !im#state#composing()
    if im#replace#can_restore()
      return "\<Cmd>call im#replace#ctrl_w()\<CR>"
    endif
    return "\<c-w>"
  endif
  return "\<Cmd>call im#engine#key(" . code . ", " . mask . ", " . string("\<c-w>") . ")\<CR>"
endfunction"}}}

function! im#keymap#ctrl_u() abort"{{{
  let [code, mask, _] = s:keys['esc']
  if !im#state#composing()
    if im#replace#can_restore()
      return "\<Cmd>call im#replace#ctrl_u()\<CR>"
    endif
    return "\<c-u>"
  endif
  return "\<Cmd>call im#engine#key(" . code . ", " . mask . ", " . string("\<c-u>") . ")\<CR>"
endfunction"}}}

function! im#keymap#bs() abort"{{{
  let [code, mask, _] = s:keys['bs']
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
  let [code, mask, _] = s:keys["s-bs"]
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
  let [code, mask, _] = s:keys['c-`']
  if !im#state#composing()
    call im#state#start_composition()
  endif
  return "\<Cmd>call im#engine#key(" . code . ", " . mask . ", " . string("\<c-`>") . ")\<CR>"
endfunction"}}}

function! im#keymap#toggle_ascii_mode(...) abort"{{{
  let style = a:0 ? a:1 : 'commit_code'
  if empty(style)
    let style = 'commit_code'
  endif
  return "\<Cmd>call im#engine#ascii_switch('" . style . "')\<CR>"
endfunction"}}}
