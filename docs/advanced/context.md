---
title: Context 自动切换
description: 按高亮作用域自动切换中英
---

<!-- 本页内容由 README.zh.md 切分生成，与 README.zh.md 同步维护 -->

# Context 自动切换

根据光标所在的高亮（语法作用域）自动切换【Rime 接管】与【原生直通】模式。

::: info
- 仅在光标跨越高亮区域边界时才会触发切换判断
- 进入插入模式时强制校准一次；离开插入模式后状态复位；组词过程中不会切换
- 插入模式下用 `;;` 重启输入法时，同样会强制校准一次
:::


## 配置

```vim
" 上下文自动切换总开关（默认关闭）
let g:im_context_enabled = 1

" 是否启用 treesitter 检测（仅 Neovim 生效；Vim 只能用 syntax 高亮判断）
let g:im_context_ts_check = 1

" '*' 为全局默认规则，具体 filetype 的配置优先级更高
let g:im_context_config = {
      \ '*':        {'mode': 'blacklist'},
      \ 'vim':      {'mode': 'whitelist', 'ts': ['comment', 'string'], 'syntax': ['comment', 'string']},
      \ 'markdown': {'mode': 'blacklist', 'syntax': ['math', 'code']},
      \ }
```

- `mode` 为 `whitelist` 时，仅在列出的高亮区域内接管为 Rime，其余区域保持直通；为 `blacklist` 时反之。
- `ts` 对应 treesitter capture 名称。
- `syntax` 对应 vim syntax 高亮组名称。
- `ts` 与 `syntax` 之间为「或」的关系，命中任一即生效；两者同时配置时 `ts` 优先级更高。

## 事件

状态变化时会触发以下 `autocmd`，可用于联动第三方插件（如补全、AI 续写等）：

| 事件                 | 触发时机                                          |
|----------------------|---------------------------------------------------|
| `RimeContextChinese` | 进入【Rime 接管】模式时触发，常用于关闭第三方补全 |
| `RimeContextEnglish` | 回到【原生直通】模式时触发，常用于恢复第三方补全  |
| `RimeContextChanged` | 接管状态发生变化时触发（不区分方向）              |

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

augroup IMGroup
  autocmd!
  autocmd User RimeContextChinese  call im#hooks#suppress_completion()
  autocmd User RimeContextEnglish call im#hooks#restore_completion()
augroup END
```

## 快捷键

手动切换【Rime 接管】与【原生直通】模式：

```
inoremap <silent> <c-;> <cmd>im#context#toggle()<cr>
```

开关整个自动切换功能：

```
nnoremap <silent> ;c <cmd>call im#context#auto_toggle()<cr>
inoremap <silent> ;c <cmd>call im#context#auto_toggle()<cr>
```
