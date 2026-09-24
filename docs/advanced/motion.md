---
title: Motion 行内跳转
description: 替代原生 f/t 的拼音感知行内跳转
---

<!-- 本页内容由 README.md 切分生成，与 README.md 同步维护 -->

# Motion 行内跳转

替代原生 `f / F / t / T` 的行内跳转，支持 `normal / visual / operator-pending`，行为参考 [clever-f.vim](https://github.com/rhysd/clever-f.vim)：键入一个 ASCII 字符，即可跳到该字符、拼音以它开头的汉字或对应的全角符号上。

| 按键                 | 说明                                                                 |
| -------------------- | -------------------------------------------------------------------- |
| `f{char}`            | 向右跳到 `{char}` 上                                                 |
| `F{char}`            | 向左跳到 `{char}` 上                                                 |
| `t{char}`            | 向右跳到 `{char}` 之前                                               |
| `T{char}`            | 向左跳到 `{char}` 之后                                               |
| `[count]` 前缀       | 如 `2fa` 跳到第 2 个匹配（对 `;` / `,` 同样有效）                    |
| 复按 `f / F / t / T` | 在落点原地再按，沿用上次的字符：`f / t` 向右、`F / T` 向左，无需重输 |
| `;` / `,`            | 沿上次方向重复 / 反向重复                                            |
| 与 operator 组合     | 如 `dfa` 删除至 `a`（含），`yta` 复制至 `a` 之前                     |

拼音匹配与限制：

- 字母键同时匹配该字母本身与拼音以它开头的汉字，如 `fa` 可跳到 `a`、`啊`、`阿` 等；符号键同时匹配半角与全角，如 `f.` 可跳到 `.` 或 `。`。
- `quanpin`（默认）：`c` 兼匹配 `ch` 开头汉字，`s` 兼匹配 `sh`，`z` 兼匹配 `zh`；`flypy`：按键与拼音严格一一对应。
- 大小写敏感，只搜索当前行，找不到时光标不动。
- 按 `Esc` / `<C-c>` 或输入非 ASCII 字符取消；跳转记忆与光标位置绑定，光标移动后即失效。

## 配置

```vim
" 等键时 shade 整行（0 关闭）
let g:im_motion_shade = 1

" 跳转后高亮当行目标字（0 关闭）
let g:im_motion_mark = 1

" 标记高亮持续毫秒数（默认 0=只靠移动清除，>0 再加定时）
let g:im_motion_mark_ms = 0

" 记忆过期毫秒数（默认 0=不过期，过期后复按重新读键）
let g:im_motion_timeout_ms = 0

" 拼音模式：quanpin（默认，全拼）或 flypy（小鹤双拼）
let g:im_motion_mode = 'quanpin'
```

## 快捷键

```vim
nnoremap f <Cmd>call im#motion#f()<CR>
nnoremap F <Cmd>call im#motion#F()<CR>
nnoremap t <Cmd>call im#motion#t()<CR>
nnoremap T <Cmd>call im#motion#T()<CR>
nnoremap ; <Cmd>call im#motion#repeat()<CR>
nnoremap , <Cmd>call im#motion#repeat_back()<CR>
xnoremap f <Cmd>call im#motion#f()<CR>
xnoremap F <Cmd>call im#motion#F()<CR>
xnoremap t <Cmd>call im#motion#t()<CR>
xnoremap T <Cmd>call im#motion#T()<CR>
xnoremap ; <Cmd>call im#motion#repeat()<CR>
xnoremap , <Cmd>call im#motion#repeat_back()<CR>

onoremap <expr> f 'v<Cmd>call im#motion#f()<CR>'
onoremap <expr> F 'v<Cmd>call im#motion#F()<CR>'
onoremap <expr> t 'v<Cmd>call im#motion#t()<CR>'
onoremap <expr> T 'v<Cmd>call im#motion#T()<CR>'
onoremap <expr> ; 'v<Cmd>call im#motion#repeat()<CR>'
onoremap <expr> , 'v<Cmd>call im#motion#repeat_back()<CR>'
```

## 高亮

```vim
highlight link ImMotionShade Grey
highlight link ImMotionTarget Search
```
