if exists('g:loaded_im_nvim')
  finish
endif

if !has('nvim') && !has('patch-8.2.1978')
  finish
endif

let g:loaded_im_nvim = 1

call im#rime#init()

command! IMToggle             call im#toggle()
command! IMStart              call im#start()
command! IMStop               call im#stop()
command! IMDeploy             call im#deploy()
command! IMSync               call im#sync()
command! IMShutdown           call im#rime#shutdown()

command! IMBuild              call im#build#build()
command! IMClean              call im#build#clean()
command! IMCheck              call im#build#check()

command! -nargs=1 IMSchemeDownload call im#scheme#download(<q-args>)

function! s:IMTypeset(l1, l2) abort
  if !im#typeset#is_enabled()
    echohl WarningMsg
    echom '[IM] typeset: filetype not enabled'
    echohl None
    return
  endif
  let n = im#typeset#range(a:l1, a:l2)
  echo '[IM] format ' . n . ' line(s) changed'
endfunction

command! -range IMTypeset call s:IMTypeset(<line1>, <line2>)
" command! IMTypesetAll call s:IMTypeset(1, line('$'))

inoremap <silent> <Plug>(im-typeset-line) <Cmd>call im#typeset#line()<CR>

if !get(g:, 'im_no_default_mappings', 0)
  let s:toggle_key = get(g:, 'im_toggle_key', ';;')
  let s:toggle_ascii_punct_key   = get(g:, 'im_toggle_ascii_punct_key', ';a')
  let s:toggle_ascii_mode_key   = get(g:, 'im_toggle_ascii_mode_key', ';,')
  execute 'nnoremap <silent> ' . s:toggle_key . ' <cmd>call im#toggle()<cr>'
  execute 'inoremap <silent><expr> ' . s:toggle_key . ' im#toggle_insert()'
  execute 'nnoremap <silent> ' . s:toggle_ascii_punct_key . ' <cmd>call im#engine#toggle_ascii_punct()<cr>'
  execute 'inoremap <silent> ' . s:toggle_ascii_punct_key . ' <cmd>call im#engine#toggle_ascii_punct()<cr>'
  execute 'nnoremap <silent> ' . s:toggle_ascii_mode_key . ' <cmd>call im#engine#toggle_ascii_mode()<cr>'
  execute 'inoremap <silent> ' . s:toggle_ascii_mode_key . ' <cmd>call im#engine#toggle_ascii_mode()<cr>'
endif

let g:im_underline_disable = get(g:, 'im_underline_disable', 0)

function! IM_Status() abort
  return im#status()
endfunction

augroup im_lifecycle
  autocmd!
  if get(g:, 'im_daemon_autostart', 1)
    autocmd VimEnter * call im#rime#start()
  endif
  autocmd VimLeave * call im#rime#stop()
  autocmd User RimeIMEnable  call im#hooks#suppress_completion()
  autocmd User RimeIMDisable call im#hooks#restore_completion()
  autocmd User RimeIMReady   call im#on_ready()
  autocmd User RimeContextChinese  call im#hooks#suppress_completion()
  autocmd User RimeContextEnglish call im#hooks#restore_completion()
  autocmd User RimeIMEnable  call im#surround#enable()
  autocmd User RimeIMDisable call im#surround#disable()
  autocmd User RimeIMEnable  call im#pair#imap_enable()
  autocmd User RimeIMDisable call im#pair#imap_disable()
  autocmd User RimeIMCommit call im#pair#complete()
  autocmd InsertLeave * call im#typeset#on_insert_leave()
augroup END

let g:RIME_MASK = {
      \ 'Shift'        : 0x00000001,
      \ 'Lock'         : 0x00000002,
      \ 'Control'      : 0x00000004,
      \ 'Alt'          : 0x00000008,
      \ 'Mod2'         : 0x00000010,
      \ 'Mod3'         : 0x00000020,
      \ 'Mod4'         : 0x00000040,
      \ 'Mod5'         : 0x00000080,
      \ 'Button1'      : 0x00000100,
      \ 'Button2'      : 0x00000200,
      \ 'Button3'      : 0x00000400,
      \ 'Button4'      : 0x00000800,
      \ 'Button5'      : 0x00001000,
      \ 'Handled'      : 0x01000000,
      \ 'Ignored'      : 0x02000000,
      \ 'Super'        : 0x04000000,
      \ 'Hyper'        : 0x08000000,
      \ 'Meta'         : 0x10000000,
      \ 'Release'      : 0x40000000,
      \ }

let g:RIME_KEYCODE = {
      \ 'space'        : 0x0020,
      \ 'exclam'       : 0x0021,
      \ 'quotedbl'     : 0x0022,
      \ 'numbersign'   : 0x0023,
      \ 'dollar'       : 0x0024,
      \ 'percent'      : 0x0025,
      \ 'ampersand'    : 0x0026,
      \ 'apostrophe'   : 0x0027,
      \ 'parenleft'    : 0x0028,
      \ 'parenright'   : 0x0029,
      \ 'asterisk'     : 0x002a,
      \ 'plus'         : 0x002b,
      \ 'comma'        : 0x002c,
      \ 'minus'        : 0x002d,
      \ 'period'       : 0x002e,
      \ 'slash'        : 0x002f,
      \ '0'            : 0x0030,
      \ '1'            : 0x0031,
      \ '2'            : 0x0032,
      \ '3'            : 0x0033,
      \ '4'            : 0x0034,
      \ '5'            : 0x0035,
      \ '6'            : 0x0036,
      \ '7'            : 0x0037,
      \ '8'            : 0x0038,
      \ '9'            : 0x0039,
      \ 'colon'        : 0x003a,
      \ 'semicolon'    : 0x003b,
      \ 'less'         : 0x003c,
      \ 'equal'        : 0x003d,
      \ 'greater'      : 0x003e,
      \ 'question'     : 0x003f,
      \ 'at'           : 0x0040,
      \ 'A'            : 0x0041,
      \ 'B'            : 0x0042,
      \ 'C'            : 0x0043,
      \ 'D'            : 0x0044,
      \ 'E'            : 0x0045,
      \ 'F'            : 0x0046,
      \ 'G'            : 0x0047,
      \ 'H'            : 0x0048,
      \ 'I'            : 0x0049,
      \ 'J'            : 0x004a,
      \ 'K'            : 0x004b,
      \ 'L'            : 0x004c,
      \ 'M'            : 0x004d,
      \ 'N'            : 0x004e,
      \ 'O'            : 0x004f,
      \ 'P'            : 0x0050,
      \ 'Q'            : 0x0051,
      \ 'R'            : 0x0052,
      \ 'S'            : 0x0053,
      \ 'T'            : 0x0054,
      \ 'U'            : 0x0055,
      \ 'V'            : 0x0056,
      \ 'W'            : 0x0057,
      \ 'X'            : 0x0058,
      \ 'Y'            : 0x0059,
      \ 'Z'            : 0x005a,
      \ 'bracketleft'  : 0x005b,
      \ 'backslash'    : 0x005c,
      \ 'bracketright' : 0x005d,
      \ 'asciicircum'  : 0x005e,
      \ 'underscore'   : 0x005f,
      \ 'grave'        : 0x0060,
      \ 'a'            : 0x0061,
      \ 'b'            : 0x0062,
      \ 'c'            : 0x0063,
      \ 'd'            : 0x0064,
      \ 'e'            : 0x0065,
      \ 'f'            : 0x0066,
      \ 'g'            : 0x0067,
      \ 'h'            : 0x0068,
      \ 'i'            : 0x0069,
      \ 'j'            : 0x006a,
      \ 'k'            : 0x006b,
      \ 'l'            : 0x006c,
      \ 'm'            : 0x006d,
      \ 'n'            : 0x006e,
      \ 'o'            : 0x006f,
      \ 'p'            : 0x0070,
      \ 'q'            : 0x0071,
      \ 'r'            : 0x0072,
      \ 's'            : 0x0073,
      \ 't'            : 0x0074,
      \ 'u'            : 0x0075,
      \ 'v'            : 0x0076,
      \ 'w'            : 0x0077,
      \ 'x'            : 0x0078,
      \ 'y'            : 0x0079,
      \ 'z'            : 0x007a,
      \ 'braceleft'    : 0x007b,
      \ 'bar'          : 0x007c,
      \ 'braceright'   : 0x007d,
      \ 'asciitilde'   : 0x007e,
      \
      \ 'ISO_Left_Tab' : 0xfe20,
      \
      \ 'BackSpace'    : 0xff08,
      \ 'Tab'          : 0xff09,
      \ 'Linefeed'     : 0xff0a,
      \ 'Clear'        : 0xff0b,
      \ 'Return'       : 0xff0d,
      \ 'Pause'        : 0xff13,
      \ 'Scroll_Lock'  : 0xff14,
      \ 'Escape'       : 0xff1b,
      \
      \ 'Home'         : 0xff50,
      \ 'Left'         : 0xff51,
      \ 'Up'           : 0xff52,
      \ 'Right'        : 0xff53,
      \ 'Down'         : 0xff54,
      \ 'Page_Up'      : 0xff55,
      \ 'Page_Down'    : 0xff56,
      \ 'End'          : 0xff57,
      \ 'Begin'        : 0xff58,
      \
      \ 'Select'       : 0xff60,
      \ 'Print'        : 0xff61,
      \ 'Execute'      : 0xff62,
      \ 'Insert'       : 0xff63,
      \ 'Undo'         : 0xff65,
      \ 'Redo'         : 0xff66,
      \ 'Menu'         : 0xff67,
      \ 'Find'         : 0xff68,
      \ 'Cancel'       : 0xff69,
      \ 'Help'         : 0xff6a,
      \ 'Break'        : 0xff6b,
      \ 'Mode_switch'  : 0xff7e,
      \ 'Num_Lock'     : 0xff7f,
      \
      \ 'KP_Space'     : 0xff80,
      \ 'KP_Tab'       : 0xff89,
      \ 'KP_Enter'     : 0xff8d,
      \ 'KP_F1'        : 0xff91,
      \ 'KP_F2'        : 0xff92,
      \ 'KP_F3'        : 0xff93,
      \ 'KP_F4'        : 0xff94,
      \ 'KP_Home'      : 0xff95,
      \ 'KP_Left'      : 0xff96,
      \ 'KP_Up'        : 0xff97,
      \ 'KP_Right'     : 0xff98,
      \ 'KP_Down'      : 0xff99,
      \ 'KP_Page_Up'   : 0xff9a,
      \ 'KP_Page_Down' : 0xff9b,
      \ 'KP_End'       : 0xff9c,
      \ 'KP_Begin'     : 0xff9d,
      \ 'KP_Insert'    : 0xff9e,
      \ 'KP_Delete'    : 0xff9f,
      \ 'KP_Multiply'  : 0xffaa,
      \ 'KP_Add'       : 0xffab,
      \ 'KP_Separator' : 0xffac,
      \ 'KP_Subtract'  : 0xffad,
      \ 'KP_Decimal'   : 0xffae,
      \ 'KP_Divide'    : 0xffaf,
      \ 'KP_0'         : 0xffb0,
      \ 'KP_1'         : 0xffb1,
      \ 'KP_2'         : 0xffb2,
      \ 'KP_3'         : 0xffb3,
      \ 'KP_4'         : 0xffb4,
      \ 'KP_5'         : 0xffb5,
      \ 'KP_6'         : 0xffb6,
      \ 'KP_7'         : 0xffb7,
      \ 'KP_8'         : 0xffb8,
      \ 'KP_9'         : 0xffb9,
      \ 'KP_Equal'     : 0xffbd,
      \
      \ 'F1'           : 0xffbe,
      \ 'F2'           : 0xffbf,
      \ 'F3'           : 0xffc0,
      \ 'F4'           : 0xffc1,
      \ 'F5'           : 0xffc2,
      \ 'F6'           : 0xffc3,
      \ 'F7'           : 0xffc4,
      \ 'F8'           : 0xffc5,
      \ 'F9'           : 0xffc6,
      \ 'F10'          : 0xffc7,
      \ 'F11'          : 0xffc8,
      \ 'F12'          : 0xffc9,
      \ 'F13'          : 0xffca,
      \ 'F14'          : 0xffcb,
      \ 'F15'          : 0xffcc,
      \ 'F16'          : 0xffcd,
      \
      \ 'Shift_L'      : 0xffe1,
      \ 'Shift_R'      : 0xffe2,
      \ 'Control_L'    : 0xffe3,
      \ 'Control_R'    : 0xffe4,
      \ 'Caps_Lock'    : 0xffe5,
      \ 'Meta_L'       : 0xffe7,
      \ 'Meta_R'       : 0xffe8,
      \ 'Alt_L'        : 0xffe9,
      \ 'Alt_R'        : 0xffea,
      \ 'Super_L'      : 0xffeb,
      \ 'Super_R'      : 0xffec,
      \ 'Hyper_L'      : 0xffed,
      \ 'Hyper_R'      : 0xffee,
      \
      \ 'Delete'       : 0xffff,
      \ }
