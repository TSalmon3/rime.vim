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

if !get(g:, 'im_no_default_mappings', 0)
  let s:toggle_key = get(g:, 'im_toggle_key', ';;')
  let s:toggle_ascii_punct_key   = get(g:, 'im_toggle_ascii_punct_key', ';a')
  let s:toggle_ascii_mode_key   = get(g:, 'im_toggle_ascii_mode_key', '<c-;>')
  let s:toggle_traditional_key   = get(g:, 'im_toggle_traditional_key', ';f')
  let s:toggle_emoji_key   = get(g:, 'im_toggle_emoji_key', ';e')
  let s:toggle_pair_key   = get(g:, 'im_toggle_pair_key', ';p')
  execute 'nnoremap <silent> ' . s:toggle_key . ' <cmd>call im#toggle()<cr>'
  execute 'inoremap <silent><expr> ' . s:toggle_key . ' im#toggle_insert()'
  execute 'inoremap <silent> ' . s:toggle_ascii_punct_key . ' <cmd>call im#rime#toggle_ascii_punct()<cr>'
  execute 'nnoremap <silent> ' . s:toggle_ascii_punct_key . ' <cmd>call im#rime#toggle_ascii_punct()<cr>'
  execute 'nnoremap <silent> ' . s:toggle_ascii_mode_key . ' <cmd>call im#rime#toggle_ascii_mode()<cr>'
  execute 'inoremap <silent><expr> ' . s:toggle_ascii_mode_key . ' <cmd>call im#keymap#toggle_ascii_mode()<cr>'
  execute 'inoremap <silent> ' . s:toggle_emoji_key . ' <cmd>call im#rime#toggle_emoji()<cr>'
  execute 'nnoremap <silent> ' . s:toggle_emoji_key . ' <cmd>call im#rime#toggle_emoji()<cr>'
  execute 'inoremap <silent> ' . s:toggle_traditional_key . ' <cmd>call im#rime#toggle_traditional()<cr>'
  execute 'nnoremap <silent> ' . s:toggle_traditional_key . ' <cmd>call im#rime#toggle_traditional()<cr>'
  execute 'inoremap <silent> ' . s:toggle_pair_key . ' <cmd>call im#pair#toggle()<cr>'
  execute 'nnoremap <silent> ' . s:toggle_pair_key . ' <cmd>call im#pair#toggle()<cr>'
endif

let g:im_underline_disable = get(g:, 'im_underline_disable', 0)

function! IM_Status() abort
  return im#status()
endfunction

augroup im_lifecycle
  autocmd!
  autocmd VimEnter    * call im#rime#start()
  autocmd VimLeavePre * call im#rime#stop()
  autocmd User RimeIMEnable  call im#hooks#on_enable()
  autocmd User RimeIMDisable call im#hooks#on_disable()
augroup END

let g:RIME_MASK = {
      \ 'Shift'   : 0x00000001,
      \ 'Lock'    : 0x00000002,
      \ 'Control' : 0x00000004,
      \ 'Alt'     : 0x00000008,
      \ 'Mod2'    : 0x00000010,
      \ 'Mod3'    : 0x00000020,
      \ 'Mod4'    : 0x00000040,
      \ 'Mod5'    : 0x00000080,
      \ 'Button1' : 0x00000100,
      \ 'Button2' : 0x00000200,
      \ 'Button3' : 0x00000400,
      \ 'Button4' : 0x00000800,
      \ 'Button5' : 0x00001000,
      \ 'Handled' : 0x01000000,
      \ 'Forward' : 0x02000000,
      \ 'Super'   : 0x04000000,
      \ 'Hyper'   : 0x08000000,
      \ 'Meta'    : 0x10000000,
      \ 'Release' : 0x40000000,
      \ }

let g:RIME_KEYCODE = {
      \ 'BackSpace'   : 0xff08,
      \ 'Tab'         : 0xff09,
      \ 'Linefeed'    : 0xff0a,
      \ 'Clear'       : 0xff0b,
      \ 'Return'      : 0xff0d,
      \ 'Pause'       : 0xff13,
      \ 'ScrollLock'  : 0xff14,
      \ 'Escape'      : 0xff1b,
      \ 'Delete'      : 0xffff,
      \ 'Space'       : 0x0020,
      \
      \ 'Home'        : 0xff50,
      \ 'Left'        : 0xff51,
      \ 'Up'          : 0xff52,
      \ 'Right'       : 0xff53,
      \ 'Down'        : 0xff54,
      \ 'PageUp'      : 0xff55,
      \ 'PageDown'    : 0xff56,
      \ 'End'         : 0xff57,
      \ 'Begin'       : 0xff58,
      \
      \ 'Select'      : 0xff60,
      \ 'Print'       : 0xff61,
      \ 'Execute'     : 0xff62,
      \ 'Insert'      : 0xff63,
      \ 'Undo'        : 0xff65,
      \ 'Redo'        : 0xff66,
      \ 'Menu'        : 0xff67,
      \ 'Find'        : 0xff68,
      \ 'Cancel'      : 0xff69,
      \ 'Help'        : 0xff6a,
      \ 'Break'       : 0xff6b,
      \ 'ModeSwitch'  : 0xff7e,
      \ 'NumLock'     : 0xff7f,
      \
      \ 'KP_Space'    : 0xff80,
      \ 'KP_Tab'      : 0xff89,
      \ 'KP_Enter'    : 0xff8d,
      \ 'KP_F1'       : 0xff91,
      \ 'KP_F2'       : 0xff92,
      \ 'KP_F3'       : 0xff93,
      \ 'KP_F4'       : 0xff94,
      \ 'KP_Home'     : 0xff95,
      \ 'KP_Left'     : 0xff96,
      \ 'KP_Up'       : 0xff97,
      \ 'KP_Right'    : 0xff98,
      \ 'KP_Down'     : 0xff99,
      \ 'KP_PageUp'   : 0xff9a,
      \ 'KP_PageDown' : 0xff9b,
      \ 'KP_End'      : 0xff9c,
      \ 'KP_Begin'    : 0xff9d,
      \ 'KP_Insert'   : 0xff9e,
      \ 'KP_Delete'   : 0xff9f,
      \ 'KP_Multiply' : 0xffaa,
      \ 'KP_Add'      : 0xffab,
      \ 'KP_Separator': 0xffac,
      \ 'KP_Subtract' : 0xffad,
      \ 'KP_Decimal'  : 0xffae,
      \ 'KP_Divide'   : 0xffaf,
      \ 'KP_0'        : 0xffb0,
      \ 'KP_1'        : 0xffb1,
      \ 'KP_2'        : 0xffb2,
      \ 'KP_3'        : 0xffb3,
      \ 'KP_4'        : 0xffb4,
      \ 'KP_5'        : 0xffb5,
      \ 'KP_6'        : 0xffb6,
      \ 'KP_7'        : 0xffb7,
      \ 'KP_8'        : 0xffb8,
      \ 'KP_9'        : 0xffb9,
      \ 'KP_Equal'    : 0xffbd,
      \
      \ 'F1'          : 0xffbe,
      \ 'F2'          : 0xffbf,
      \ 'F3'          : 0xffc0,
      \ 'F4'          : 0xffc1,
      \ 'F5'          : 0xffc2,
      \ 'F6'          : 0xffc3,
      \ 'F7'          : 0xffc4,
      \ 'F8'          : 0xffc5,
      \ 'F9'          : 0xffc6,
      \ 'F10'         : 0xffc7,
      \ 'F11'         : 0xffc8,
      \ 'F12'         : 0xffc9,
      \ 'F13'         : 0xffca,
      \ 'F14'         : 0xffcb,
      \ 'F15'         : 0xffcc,
      \ 'F16'         : 0xffcd,
      \
      \ 'ShiftL'      : 0xffe1,
      \ 'ShiftR'      : 0xffe2,
      \ 'ControlL'    : 0xffe3,
      \ 'ControlR'    : 0xffe4,
      \ 'CapsLock'    : 0xffe5,
      \ 'MetaL'       : 0xffe7,
      \ 'MetaR'       : 0xffe8,
      \ 'AltL'        : 0xffe9,
      \ 'AltR'        : 0xffea,
      \ 'SuperL'      : 0xffeb,
      \ 'SuperR'      : 0xffec,
      \ 'HyperL'      : 0xffed,
      \ 'HyperR'      : 0xffee,
      \ }
