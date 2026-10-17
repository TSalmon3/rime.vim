let s:code2name = {}
let s:probed = 0

let s:xkb2vim = {
      \ 'space'        : 'Space',
      \ 'exclam'       : '!',
      \ 'quotedbl'     : '"',
      \ 'numbersign'   : '#',
      \ 'dollar'       : '$',
      \ 'percent'      : '%',
      \ 'ampersand'    : '&',
      \ 'apostrophe'   : "'",
      \ 'parenleft'    : '(',
      \ 'parenright'   : ')',
      \ 'asterisk'     : '*',
      \ 'plus'         : '+',
      \ 'comma'        : ',',
      \ 'minus'        : '-',
      \ 'period'       : '.',
      \ 'slash'        : '/',
      \ 'colon'        : ':',
      \ 'semicolon'    : ';',
      \ 'less'         : '<',
      \ 'equal'        : '=',
      \ 'greater'      : '>',
      \ 'question'     : '?',
      \ 'at'           : '@',
      \ 'bracketleft'  : '[',
      \ 'backslash'    : '\',
      \ 'bracketright' : ']',
      \ 'asciicircum'  : '^',
      \ 'underscore'   : '_',
      \ 'grave'        : '`',
      \ 'braceleft'    : '{',
      \ 'bar'          : '|',
      \ 'braceright'   : '}',
      \ 'asciitilde'   : '~',
      \ 'ISO_Left_Tab' : 'S-Tab',
      \ 'BackSpace'    : 'BackSpace',
      \ 'Tab'          : 'Tab',
      \ 'Linefeed'     : 'Linefeed',
      \ 'Clear'        : '',
      \ 'Return'       : 'Return',
      \ 'Pause'        : '',
      \ 'Scroll_Lock'  : '',
      \ 'Escape'       : 'Esc',
      \ 'Home'         : 'Home',
      \ 'Left'         : 'Left',
      \ 'Up'           : 'Up',
      \ 'Right'        : 'Right',
      \ 'Down'         : 'Down',
      \ 'Page_Up'      : 'PageUp',
      \ 'Page_Down'    : 'PageDown',
      \ 'End'          : 'End',
      \ 'Begin'        : '',
      \ 'Select'       : '',
      \ 'Print'        : '',
      \ 'Execute'      : '',
      \ 'Insert'       : 'Insert',
      \ 'Undo'         : 'Undo',
      \ 'Redo'         : '',
      \ 'Menu'         : '',
      \ 'Find'         : '',
      \ 'Cancel'       : '',
      \ 'Help'         : 'Help',
      \ 'Break'        : '',
      \ 'Mode_switch'  : '',
      \ 'Num_Lock'     : '',
      \ 'KP_Space'     : 'Space',
      \ 'KP_Tab'       : 'Tab',
      \ 'KP_Enter'     : 'kEnter',
      \ 'KP_F1'        : '',
      \ 'KP_F2'        : '',
      \ 'KP_F3'        : '',
      \ 'KP_F4'        : '',
      \ 'KP_Home'      : 'kHome',
      \ 'KP_Left'      : 'Left',
      \ 'KP_Up'        : 'Up',
      \ 'KP_Right'     : 'Right',
      \ 'KP_Down'      : 'Down',
      \ 'KP_Page_Up'   : 'kPageUp',
      \ 'KP_Page_Down' : 'kPageDown',
      \ 'KP_End'       : 'kEnd',
      \ 'KP_Begin'     : '',
      \ 'KP_Insert'    : 'kInsert',
      \ 'KP_Delete'    : 'Del',
      \ 'KP_Multiply'  : 'kMultiply',
      \ 'KP_Add'       : 'kPlus',
      \ 'KP_Separator' : ',',
      \ 'KP_Subtract'  : 'kMinus',
      \ 'KP_Decimal'   : 'kPoint',
      \ 'KP_Divide'    : 'kDivide',
      \ 'KP_0'         : 'k0',
      \ 'KP_1'         : 'k1',
      \ 'KP_2'         : 'k2',
      \ 'KP_3'         : 'k3',
      \ 'KP_4'         : 'k4',
      \ 'KP_5'         : 'k5',
      \ 'KP_6'         : 'k6',
      \ 'KP_7'         : 'k7',
      \ 'KP_8'         : 'k8',
      \ 'KP_9'         : 'k9',
      \ 'KP_Equal'     : '=',
      \ 'F1'           : 'F1',
      \ 'F2'           : 'F2',
      \ 'F3'           : 'F3',
      \ 'F4'           : 'F4',
      \ 'F5'           : 'F5',
      \ 'F6'           : 'F6',
      \ 'F7'           : 'F7',
      \ 'F8'           : 'F8',
      \ 'F9'           : 'F9',
      \ 'F10'          : 'F10',
      \ 'F11'          : 'F11',
      \ 'F12'          : 'F12',
      \ 'F13'          : 'F13',
      \ 'F14'          : 'F14',
      \ 'F15'          : 'F15',
      \ 'F16'          : 'F16',
      \ 'Shift_L'      : '',
      \ 'Shift_R'      : '',
      \ 'Control_L'    : '',
      \ 'Control_R'    : '',
      \ 'Caps_Lock'    : '',
      \ 'Meta_L'       : '',
      \ 'Meta_R'       : '',
      \ 'Alt_L'        : '',
      \ 'Alt_R'        : '',
      \ 'Super_L'      : '',
      \ 'Super_R'      : '',
      \ 'Hyper_L'      : '',
      \ 'Hyper_R'      : '',
      \ 'Delete'       : 'Del',
      \ }

function! s:init() abort
  if s:probed
    return
  endif
  let s:probed = 1
  let table = im#keycode#keycodes()
  if exists('g:RIME_KEYCODE')
    call extend(table, g:RIME_KEYCODE, 'force')
  endif
  for [name, code] in items(table)
    if !has_key(s:code2name, code)
      let s:code2name[code] = name
    endif
  endfor
endfunction

function! s:expand(vimname) abort
  try
    let expanded = eval('"' . '\' . a:vimname . '"')
    return expanded !=# a:vimname ? expanded : ''
  catch /^Vim\%((\a\+)\)\=:E\d\+:/
    return ''
  endtry
endfunction

function! im#keysym#decode(keycode, mask) abort
  call s:init()
  if empty(s:code2name)
    return ''
  endif
  let MK = exists('g:RIME_MASK') ? g:RIME_MASK : im#keycode#mask()
  if and(a:mask, MK.Release)
    return ''
  endif
  let xkb = get(s:code2name, a:keycode, '')
  if xkb ==# ''
    return ''
  endif
  if a:keycode >= 0x20 && a:keycode < 0x7f && a:mask == 0
    return nr2char(a:keycode)
  endif
  let mods = ''
  if and(a:mask, MK.Control)
    let mods .= 'c-'
  endif
  if and(a:mask, MK.Alt) || and(a:mask, MK.Meta)
    let mods .= 'm-'
  endif
  if and(a:mask, MK.Shift)
    let mods .= 's-'
  endif
  if and(a:mask, MK.Super) || and(a:mask, MK.Hyper)
    return ''
  endif
  if len(xkb) == 1
    let key = xkb
  else
    let key = get(s:xkb2vim, xkb, '')
    if key ==# ''
      return ''
    endif
    if key =~# '^S-'
      let mods = substitute(mods, 's-', '', '')
    endif
    if len(key) > 1
      return s:expand('<' . mods . key . '>')
    endif
  endif
  if mods ==# ''
    return key
  endif
  if mods ==# 's-' && key =~# '^[a-z]$'
    return toupper(key)
  endif
  return s:expand('<' . mods . tolower(key) . '>')
endfunction
