---
title: 定制中英切换与方案选单
description: 方案选单与中英切换风格
---

<!-- 本页内容由 README.zh.md 切分生成，与 README.zh.md 同步维护 -->

# 定制中英切换与方案选单

## 方案选单

`im#keymap#toggle_scheme()` 会向 Rime 发送 `` Ctrl+` ``，打开内置的「方案选单」，与系统输入法行为一致：

- 选单内容来自用户数据目录里 `default.custom.yaml` 的 `schema_list`，以及 switcher 中的开关项（简繁、中英标点、emoji 等）
- 切换后状态栏会立即刷新

## 中英切换

`im#keymap#toggle_ascii_mode()` 不带参数时，模拟一次左 Shift 按下 + 释放，与系统输入法一致；组词过程中的处理方式由 Rime 配置里的 `ascii_composer/switch_key` 决定。

带参数时可以指定「正在组词时切换」的处理风格：

| 参数                 | 组词时切换的行为                                         |
| -------------------- | -------------------------------------------------------- |
| `'commit_code'`      | 拼音字母原样上屏，再切换                                 |
| `'commit_text'`      | 有候选时上屏当前高亮候选词；无候选时原样上屏编码，再切换 |
| `'clear'`            | 丢弃当前组词内容，再切换                                 |
| `'inline_ascii'`     | 进入临时英文态：直接输出英文，本次上屏结束后自动切回中文 |
| `'set_ascii_mode'`   | 强制切到英文；正在组词时丢弃当前组词内容                 |
| `'unset_ascii_mode'` | 强制切回中文；已是英文态时为空操作                       |

::: info
这些参数只影响「正在组词时」的切换行为；空闲状态下按下都只是单纯在中/英之间切换。
:::

示例：

```vim
function RimeKeymapRemap()
  lnoremap <silent><expr> ;` im#keymap#toggle_scheme()
  lnoremap <nowait><expr> ;: im#keymap#toggle_ascii_mode()
  lnoremap <nowait><expr> ;1 im#keymap#toggle_ascii_mode('commit_code')
  lnoremap <nowait><expr> ;2 im#keymap#toggle_ascii_mode('commit_text')
  lnoremap <nowait><expr> ;3 im#keymap#toggle_ascii_mode('clear')
  lnoremap <nowait><expr> ;4 im#keymap#toggle_ascii_mode('inline_ascii')
  lnoremap <nowait><expr> ;5 im#keymap#toggle_ascii_mode('set_ascii_mode')
  lnoremap <nowait><expr> ;6 im#keymap#toggle_ascii_mode('unset_ascii_mode')
endfunction

function RimeKeymapClear()
  silent! lunmap ;`
  silent! lunmap ;:
  silent! lunmap ;1
  silent! lunmap ;2
  silent! lunmap ;3
  silent! lunmap ;4
  silent! lunmap ;5
  silent! lunmap ;6
endfunction

augroup RimeGroup
  autocmd!
  autocmd User RimeKeymapSetup call RimeKeymapRemap()
  autocmd User RimeKeymapClear call RimeKeymapClear()
augroup END
```
