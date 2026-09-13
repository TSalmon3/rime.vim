---
title: 让中文编辑更加丝滑
description: ultisnips / bullets / jieba 搭配
---

<!-- 本页内容由 README.zh.md 切分生成，与 README.zh.md 同步维护 -->

# 让中文编辑更加丝滑

如果你安装了 [ultisnips](https://github.com/SirVer/ultisnips) 和 [bullets.vim](https://github.com/bullets-vim/bullets.vim)，可以这样配置：

```vim
function RimeKeymapRemap()
  if &filetype ==# 'markdown'
    lnoremap <silent><expr> <tab> im#state#composing() ?
          \ "\<cmd>call im#key(g:RIME_KEYCODE.Tab, 0)\<CR>" :
          \ UltiSnips#CanJumpForwards() ?
          \"\<c-r>=UltiSnips#JumpForwards()\<cr>" :  bullet#is_bullet() ?
          \ "\<C-o>\<Plug>(bullets-demote)\<C-o>$" :  "\<tab>"

    lnoremap <silent><expr> <s-tab> im#state#composing() ?
          \ "\<cmd>call im#key(g:RIME_KEYCODE.Tab, g:RIME_MASK.Shift)\<CR>" :
          \ UltiSnips#CanJumpBackwards() ?
          \ "\<c-r>=UltiSnips#JumpBackwards()\<cr>" : bullet#is_bullet()?
          \ "\<C-o>\<Plug>(bullets-promote)\<C-o>$" : "\<s-tab>"

    lnoremap <silent><expr> <cr> im#state#composing() ?
          \ "\<cmd>call im#key(g:RIME_KEYCODE.Return, 0)\<cr>" :
          \ delimitMate#WithinEmptyPair() ?
          \ "\<c-r>=delimitMate#ExpandReturn()\<cr>" : "\<Plug>(bullets-newline)"
  else
    lnoremap <silent><expr> <tab> im#state#composing() ?
          \ "\<cmd>call im#key(g:RIME_KEYCODE.Tab, 0)\<CR>" :
          \ UltiSnips#CanJumpForwards() ?
          \"\<c-r>=UltiSnips#JumpForwards()\<cr>" : "\<tab>"

    lnoremap <silent><expr> <s-tab> im#state#composing() ?
          \ "\<cmd>call im#key(g:RIME_KEYCODE.Tab, g:RIME_MASK.Shift)\<CR>" :
          \ UltiSnips#CanJumpBackwards() ?
          \ "\<c-r>=UltiSnips#JumpBackwards()\<cr>" : "\<s-tab>"

    lnoremap <silent><expr> <cr> im#state#composing() ?
          \ "\<cmd>call im#key(g:RIME_KEYCODE.Return, 0)\<CR>" :
          \ delimitMate#WithinEmptyPair() ?
          \ "\<c-r>=delimitMate#ExpandReturn()\<cr>" : "\<cr>"
  endif
endfunction

function RimeKeymapClear()

endfunction

augroup RimeGroup
  autocmd!
  autocmd User RimeKeymapSetup call RimeKeymapRemap()
  autocmd User RimeKeymapClear call RimeKeymapClear()
augroup END
```

![demo3](https://github.com/user-attachments/assets/093e5089-0b8c-4528-854f-5d4aee85328d)

如果你安装了 [jieba.vim](https://github.com/kkew3/jieba.vim)，还可以对 `<c-w>` 进行增强：

```vim
function RimeKeymapRemap()
  lnoremap <silent><expr> <c-w> im#state#composing() ?
        \ "\<cmd>call im#key(g:RIME_KEYCODE.BackSpace, g:RIME_MASK.Shift)\<CR>" :
        \ im#replace#can_restore() ? "\<cmd>call im#replace#ctrl_w()\<cr>" :
        \ "<Plug>(Jieba_C_w)"
endfunction

function RimeKeymapClear()

endfunction

augroup RimeGroup
  autocmd!
  autocmd User RimeKeymapSetup call RimeKeymapRemap()
  autocmd User RimeKeymapClear call RimeKeymapClear()
augroup END

```
