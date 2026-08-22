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

