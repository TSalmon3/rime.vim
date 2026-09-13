---
title: 集成
description: 事件与状态栏
---

<!-- 本页内容由 README.zh.md 切分生成，与 README.zh.md 同步维护 -->

# 集成

## 事件

**`autocmd User RimeKeymapSetup {command}`**

插入模式按键映射建立后触发。

**`autocmd User RimeKeymapClear {command}`**

插入模式按键映射清除后触发。

**`autocmd User RimeIMEnable {command}`**

输入法启用后触发，可用于关闭其他插件的补全。

**`autocmd User RimeIMDisable {command}`**

输入法禁用后触发，可用于恢复其他插件的补全。

示例：

```vim
function! im#hooks#suppress_completion() abort
  if exists('*coc#config')
    call coc#config('suggest.autoTrigger', 'none')
  endif
  if exists(':Codeium')
    Codeium Disable
  endif
  if exists('g:blink_cmp_enabled')
    let g:blink_cmp_enabled = v:false
  endif
endfunction

function! im#hooks#restore_completion() abort
  if exists('*coc#config')
    call coc#config('suggest.autoTrigger', 'always')
  endif
  if exists(':Codeium')
    Codeium Enable
  endif
  if exists('g:blink_cmp_enabled')
    let g:blink_cmp_enabled = v:true
  endif
endfunction


augroup IMGroup
  autocmd!
  autocmd User RimeIMEnable  call im#hooks#suppress_completion()
  autocmd User RimeIMDisable call im#hooks#restore_completion()
augroup END
```

## 状态栏

最简单的方式是在你的 `'statusline'` 选项中加入 `%{IM_Status()}`。开启时显示
`[ㄓ]半|简`（图标 / 标点 / 简繁，文本均可用对应的 `g:im_status_*` 定制），关闭时返回空串。

```vim
let statusline^=%{IM_Status()}
```
