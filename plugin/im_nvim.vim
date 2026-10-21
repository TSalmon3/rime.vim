if exists('g:loaded_im_nvim')
  finish
endif

let g:loaded_im_nvim = 1

let g:RIME_MASK = im#keycode#mask()
let g:RIME_KEYCODE = im#keycode#keycodes()

function! s:pin_keycodes() abort
  let g:RIME_MASK = im#keycode#mask()
  let g:RIME_KEYCODE = im#keycode#keycodes()
  lockvar! g:RIME_MASK
  lockvar! g:RIME_KEYCODE
endfunction

if has('vim_starting')
  augroup im_nvim_pin_keycodes
    autocmd!
    autocmd VimEnter * call s:pin_keycodes()
  augroup END
else
  call s:pin_keycodes()
endif

if !has('nvim') && !has('patch-8.2.1978')
  finish
endif
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
  autocmd User RimeIMEnable  call im#textobj#enable()
  autocmd User RimeIMDisable call im#textobj#disable()
  autocmd User RimeIMEnable  call im#pair#imap_enable()
  autocmd User RimeIMDisable call im#pair#imap_disable()
  autocmd User RimeIMEnable  call im#snip#register_builtin_engines()
  autocmd User RimeIMCommit call im#pair#complete()
  autocmd InsertLeave * call im#typeset#on_insert_leave()
augroup END
