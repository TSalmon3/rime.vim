---
title: Replace Mode 替换模式
description: 替换模式下的 Rime 支持
---

<!-- 本页内容由 README.zh.md 切分生成，与 README.zh.md 同步维护 -->

# Replace Mode 替换模式

> 以下功能还处于实验性阶段。

![demo4](https://github.com/user-attachments/assets/f2fba3e1-d7dc-4b1c-bd5a-779b4e725a45)

开启该功能后，Rime 可以在替换模式（`R` / `gR`）下工作：上屏内容将从光标处**覆盖**原有字符（而非插入），且支持像原生 Replace 一样撤销还原。

```vim
" 设为 1：在 R/gR 替换模式下启用 Rime
let g:im_replace_mode = 1
```

`g:im_replace_mode` 默认值为 `0`，此时替换模式下的按键不会被 Rime 拦截，完全遵循 Vim 原生行为，也不会弹出候选窗口。

设为 `1` 后，进入 `R` / `gR` 即开启一个替换会话，期间上屏的内容可按原生 Replace 的方式撤销还原：

| 按键    | 功能                               |
| ------- | ---------------------------------- |
| `<bs>`  | 撤销上一步覆盖的字符               |
| `<c-w>` | 撤销上一个空格分隔词所覆盖的字符   |
| `<c-u>` | 撤销本次会话中覆盖的全部字符       |


移动光标会终止当前会话的撤销能力（与原生 Replace 行为一致），此后将从新位置重新开始覆盖。

- 重新映射 `r`，以支持半角/全角切换：

```vim
nnoremap r <Cmd>call im#keymap#r()<CR>
```
