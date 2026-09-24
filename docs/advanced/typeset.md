---
title: Typeset 自动排版
description: 中英文混排自动规范
---

<!-- 本页内容由 README.md 切分生成，与 README.md 同步维护 -->

# Typeset 自动排版

遵循 [中文文案排版指北](https://github.com/sparanoid/chinese-copywriting-guidelines)，自动规范中英文混排文本：中英文、数字之间自动补空格，全角 / 半角标点与字母数字自动归一，清理零宽字符与行尾空白，合并连续重复的标点符号。

* **触发方式**：
  - 手动执行 `:IMTypeset`
  - 离开插入模式时自动触发（受 `g:im_typeset_insert_leave` 控制）
  - 回车换行时格式化上一行（映射 `<Plug>(im-typeset-line)`）

::: tip
本插件仅提供轻量、启发式的行内排版，不保证高精度结果；如需高精度排版推荐使用 [autocorrect](https://github.com/huacnlee/autocorrect)。
:::

## 配置

```vim
" 退出插入模式时自动格式化当前行，默认关闭（0）
let g:im_typeset_insert_leave = 1

let g:im_typeset_config = {
      \ 'markdown': {
      \   'syntax': ['link', 'code', 'math', 'table', 'bold', 'italic'],
      \   'rules': im#typeset#rule#default_rules()
      \     + [function('im#typeset#rule#markdown_space_at_bounds')]},
      \ }

" 例外词表：产品名等专有名词内部不受排版影响（默认为空）；保护机制详见下文 Note
let g:im_typeset_ignore_words = ['豆瓣FM']
```

**配置字段：**

* **`ts`**（`List`）：treesitter 节点类型子串（大小写不敏感），命中即视为保护区域
* **`syntax`**（`List`）：高亮组名子串（大小写不敏感），命中即视为保护区域
* **`rules`**(`List`）：格式化规则链，类型为 `Funcref(ctx, in) -> out`，按数组顺序依次执行
  * **`ctx`**（`Dict`）：上下文信息，包含以下字段
    * `filetype`：当前 buffer 的文件类型（`&filetype`）
    * `bufnr`：当前 buffer 编号（`bufnr()`）
    * `bufname`：当前 buffer 文件名（`bufname()`）
    * `lnum`：当前行号
    * `left_char`：当前片段左边界外的一个字符；若片段位于行首，则为 `''`
    * `right_char`：当前片段右边界外的一个字符；若片段位于行尾，则为 `''`
  * **`in`**(`String`）：待处理的文本片段，同时是上一条规则的输出。
  * **`out`**(`String`)：已处理的文本片段，同时是下一条规则的输入


**内置规则 API**（完整函数名为 `im#typeset#rule#<规则名>(ctx, s)`，下面只列出 `<规则名>` 部分）：

* **`invisible_spaces`**：删零宽字符；行尾空白清理
* **`halfwidth_word`**：全角字母数字 → 半角（含全角空格、数字间时间冒号）
* **`fullwidth_punctuation`**：CJK 旁半角标点 → 全角（括号/书名号；`html` 跳过书名号）
* **`halfwidth_punctuation`**：纯英文段全角标点 → 半角（`,;:!?` 后补空格；含 CJK 整段跳过）
* **`no_space_fullwidth`**：宽字符之间删空格（含 ASCII 侧、全角引号；缩进保留）
* **`space_word`**：段内 CJK ↔ 字母数字间补空格（含 `±n` 双向、`n%`、`C++`/`+`/`#` 后缀；`%s`/`$1`/`\d` 占位符不碰）
* **`space_bracket`**：段内 CJK ↔ 半角 `[]()` 间补空格（拉丁侧不动；`{}` 不管）
* **`space_punctuation`**：`!` + CJK 间补空格
* **`space_pipe_plus`**：段内 CJK/引号旁 `|`/`+` 两侧补空格（`3+5`/`C++`/行首 `+` 不动）
* **`space_backticks`**：段内 CJK ↔ 整对行内代码补空格（孤反引号/围栏不动；跨保护区接缝由 `markdown_space_at_bounds` 处理）
* **`space_dash`**：段内 CJK/引号/括号间 `-` 两侧补空格（`3-5` / `e-mail` 等不动）
* **`space_dollar`**：段内 CJK 旁 `$` 两侧补空格
* **`repeated_punct`**：叠标归一（`。。。` → `······`，`！？` 至多连 3）
* **`markdown_space_at_bounds`**：仅 markdown，正文与行内代码/公式/链接接缝处补空格

```vim
function! im#typeset#rule#default_rules() abort
  return [
        \ function('im#typeset#rule#invisible_spaces'),
        \ function('im#typeset#rule#space_word'),
        \ function('im#typeset#rule#space_punctuation'),
        \ function('im#typeset#rule#space_bracket'),
        \ function('im#typeset#rule#fullwidth_punctuation'),
        \ function('im#typeset#rule#halfwidth_word'),
        \ function('im#typeset#rule#halfwidth_punctuation'),
        \ function('im#typeset#rule#no_space_fullwidth'),
        \ function('im#typeset#rule#repeated_punct'),
        \ ]
endfunction
```

## 命令

| 命令                | 说明             |
| ------------------- | ---------------- |
| `:IMTypeset`        | 格式化当前行     |
| `:{range}IMTypeset` | 格式化指定行范围 |

## 按键映射

```vim
nnoremap <silent> ;t <cmd>IMTypeset<cr>
xnoremap <silent> ;t :IMTypeset<cr>
```

绑定 `<Plug>(im-typeset-line)`，使回车键在换行的同时自动排版当前行。

```vim
function RimePairImapRemap()
  inoremap <buffer><expr> <cr> luaeval("require('blink.cmp').is_menu_visible()") && luaeval("require('blink.cmp').get_selected_item() ~= nil") ?
          \ "\<cmd>lua require('blink.cmp').accept()\<cr>"
          \ : pumvisible() && complete_info()['selected'] != -1 ? "\<c-y>"
          \ : im#pair#should_cr() ? im#pair#cr() : "\<Plug>(im-typeset-line)\<cr>"
endfunction

function RimePairImapRestore()
  inoremap <silent><expr> <cr> luaeval("require('blink.cmp').is_menu_visible()") && luaeval("require('blink.cmp').get_selected_item() ~= nil") ?
        \ "\<cmd>lua require('blink.cmp').accept()\<cr>"
        \ : pumvisible() && complete_info()['selected'] != -1 ?
        \ "\<c-y>" : "\<cr>"
endfunction

function RimeKeymapRemap()
  lnoremap <silent><expr> <cr> im#state#composing() ?
          \ "\<cmd>call im#key(g:RIME_KEYCODE.Return, 0)\<cr>"
          \ : im#pair#should_cr() ? im#pair#cr() : "\<Plug>(im-typeset-line)\<cr>"

endfunction

augroup RimeGroup
  autocmd!
  autocmd User RimeKeymapSetup call RimeKeymapRemap()
  autocmd User RimePairImapSetup call RimePairImapRemap()
  autocmd User RimePairImapRestore call RimePairImapRestore()
augroup END

```
