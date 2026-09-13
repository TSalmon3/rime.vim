---
title: Surround 包围编辑
description: 包围规则、别名与内置函数
---

<!-- 本页内容由 README.zh.md 切分生成，与 README.zh.md 同步维护 -->

# Surround 包围编辑

为选区、文本对象或整行**添加、删除、替换**成对分隔符（括号、引号、HTML 标签、函数调用等），并额外支持全角符号。

默认按键映射（均可用对应的 `g:im_surround_*_key` 定制）：

| 按键                | 模式   | 说明                               |
|---------------------|--------|------------------------------------|
| `ys{motion}{char}`  | normal | 为 motion 选中的内容添加分隔符     |
| `yS{motion}{char}`  | normal | 同上，但分隔符独占首尾新行         |
| `yss` / `ySS`       | normal | 为整行添加分隔符（`ySS` 独占新行） |
| `ds{char}`          | normal | 删除光标处最近的分隔符             |
| `cs{old}{new}`      | normal | 将旧分隔符替换为新分隔符           |
| `cS{old}{new}`      | normal | 同上，新分隔符独占首尾新行         |
| `S` / `gS`          | visual | 为选区添加分隔符（`gS` 独占新行）  |
| `<c-g>s` / `<c-g>S` | insert | 插入一对分隔符并将光标置于中间     |

常见用法示例（`*` 为光标位置）：

| 旧文本                       | 按键    | 新文本                |
|:-----------------------------|:--------|:----------------------|
| `surr*ound_words`            | `ysiw)` | `(surr*ound_words)`   |
| `surr*ound_words`            | `ysiw(` | `( surr*ound_words )` |
| `*make strings`              | `ys$"`  | `"*make strings"`     |
| `[delete ar*ound me!]`       | `ds]`   | `delete ar*ound me!`  |
| `remove \<b>HTML t*ags\</b>` | `dst`   | `remove HTML t*ags`   |
| `'change quot*es'`           | `cs'"`  | `"change quot*es"`    |
| `delete(functi*on calls)`    | `dsf`   | `functi*on calls`     |

## 配置

```vim
" 包围功能开关（默认 0）
let g:im_surround_enable = 1

" 自定义快捷键
let g:im_surround_add_key           = 'ys'      " 加包围 (normal)
let g:im_surround_add_cur_key       = 'yss'     " 整行加包围 (normal)
let g:im_surround_add_line_key      = 'yS'      " 加包围-新行式 (normal)
let g:im_surround_add_cur_line_key  = 'ySS'     " 整行加包围-新行式 (normal)
let g:im_surround_delete_key        = 'ds'      " 删包围 (normal)
let g:im_surround_change_key        = 'cs'      " 换包围 (normal)
let g:im_surround_change_line_key   = 'cS'      " 换包围-新行式 (normal)
let g:im_surround_visual_key        = 'S'       " 可视模式包裹 (visual)
let g:im_surround_visual_line_key   = 'gS'      " 可视模式新行包裹 (visual)
let g:im_surround_insert_key        = '<C-g>s'  " 插入模式插入 (insert)
let g:im_surround_insert_line_key   = '<C-g>S'  " 插入模式换行插入 (insert)

" ds / cs 定位到包围对时的闪光高亮时长（毫秒，0 关闭）
let g:im_surround_flash_ms          = 120

" 自定义包围规则
let g:im_surround_surrounds = im#surround#config#default_surrounds()
" 等价于
let g:im_surround_surrounds = [
      \ {'key': '(',  'add': ['( ', ' )'], 'find': function('im#surround#find#matchpair')},
      \ {'key': ')',  'add': ['(', ')'],   'find': function('im#surround#find#matchpair')},
      \ {'key': '[',  'add': ['[ ', ' ]'], 'find': function('im#surround#find#matchpair')},
      \ {'key': ']',  'add': ['[', ']'],   'find': function('im#surround#find#matchpair')},
      \ {'key': '{',  'add': ['{ ', ' }'], 'find': function('im#surround#find#matchpair')},
      \ {'key': '}',  'add': ['{', '}'],   'find': function('im#surround#find#matchpair')},
      \ {'key': '<',  'add': ['< ', ' >'], 'find': function('im#surround#find#matchpair')},
      \ {'key': '>',  'add': ['<', '>'],   'find': function('im#surround#find#matchpair')},
      \ {"key": "'",  'add': ["'", "'"],   'find': function('im#surround#find#quote')},
      \ {'key': '"',  'add': ['"', '"'],   'find': function('im#surround#find#quote')},
      \ {'key': '`',  'add': ['`', '`'],   'find': function('im#surround#find#quote')},
      \ {'key': 't',  'add': function('im#surround#add#tag'),     'find': function('im#surround#find#tag'),       'replace': function('im#surround#change#tag')},
      \ {'key': 'T',  'add': function('im#surround#add#tag'),     'find': function('im#surround#find#tag'),       'replace': function('im#surround#change#tag_full')},
      \ {'key': 'f',  'add': function('im#surround#add#func'),    'find': function('im#surround#find#func'),      'replace': function('im#surround#change#func')},
      \ {'key': 'i',  'add': function('im#surround#add#input')},
      \ {'key': '‘', 'add': ['‘', '’'], 'find': function('im#surround#find#matchpair')},
      \ {'key': '’', 'add': ['‘', '’'], 'find': function('im#surround#find#matchpair')},
      \ {'key': '“', 'add': ['“', '”'], 'find': function('im#surround#find#matchpair')},
      \ {'key': '”', 'add': ['“', '”'], 'find': function('im#surround#find#matchpair')},
      \ {'key': '（', 'add': ['（', '）'], 'find': function('im#surround#find#matchpair')},
      \ {'key': '）', 'add': ['（', '）'], 'find': function('im#surround#find#matchpair')},
      \ {'key': '【', 'add': ['【', '】'], 'find': function('im#surround#find#matchpair')},
      \ {'key': '】', 'add': ['【', '】'], 'find': function('im#surround#find#matchpair')},
      \ {'key': '「', 'add': ['「', '」'], 'find': function('im#surround#find#matchpair')},
      \ {'key': '」', 'add': ['「', '」'], 'find': function('im#surround#find#matchpair')},
      \ {'key': '『', 'add': ['『', '』'], 'find': function('im#surround#find#matchpair')},
      \ {'key': '』', 'add': ['『', '』'], 'find': function('im#surround#find#matchpair')},
      \ {'key': '《', 'add': ['《', '》'], 'find': function('im#surround#find#matchpair')},
      \ {'key': '》', 'add': ['《', '》'], 'find': function('im#surround#find#matchpair')},
      \ {'key': '＜', 'add': ['＜', '＞'], 'find': function('im#surround#find#matchpair')},
      \ {'key': '＞', 'add': ['＜', '＞'], 'find': function('im#surround#find#matchpair')},
      \ ]


" 自定义别名（整体替换默认表）
let g:im_surround_aliases = im#surround#config#default_aliases()
let g:im_surround_aliases += [
      \ {'key': ')', 'targets' : [')', '）']},
      \ {'key': '(', 'targets' : ['(', '（']},
      \ {'key': '）', 'targets' : ['）', ')']},
      \ {'key': '（', 'targets' : ['（', '(']},
      \ {'key': ']', 'targets' : [']', '」', '』', '】']},
      \ {'key': '[', 'targets' : ['[', '「', '『', '【']},
      \ {'key': '}', 'targets' : [']', '」', '』', '】']},
      \ {'key': '{', 'targets' : ['[', '「', '『', '【']},
      \ {'key': '「', 'targets' : ['[', '「', '『', '【']},
      \ {'key': '」', 'targets' : [']', '」', '』', '】']},
      \ {'key': '『', 'targets' : ['[', '「', '『', '【']},
      \ {'key': '』', 'targets' : [']', '」', '』', '】']},
      \ {'key': '【', 'targets' : ['[', '「', '『', '【']},
      \ {'key': '】', 'targets' : [']', '」', '』', '】']},
      \ {'key': '<', 'targets' : ['<',  '《']},
      \ {'key': '>', 'targets' : ['>', '》' ]},
      \ {'key': '《', 'targets' : ['《',  '<']},
      \ {'key': '》', 'targets' : ['》', '>' ]}
      \ ]
```

## g:im_surround_surrounds

该项为 `List` 类型，推荐基于 `im#surround#config#default_surrounds()` 进行扩展和修改。

每项为一个字典，包含以下核心字段：

| 字段      | 赋值要求                 | 说明                                                                        |
| --------- | ------------------------ | --------------------------------------------------------------------------- |
| `key`     | Char（必填，支持 CJK）   | 触发字符，即 `ys` / `ds` / `cs` 之后键入的字符；为空或类型不符时该项整体失效|
| `add`     | `List<String>` 或 Funcref  | 添加包围时分隔符的来源，见下                                                |
| `find`    | Funcref                  | 定位光标所在的包围对，供 `ds` / `cs` 使用，见下                             |
| `replace` | Funcref（可选）          | `cs` 时生成新分隔符，见下；缺省则高亮原包围并等待键入新分隔符               |


::: info
- `add` 只在**添加**时使用
- `find` 只在 `ds` / `cs` **定位旧包围**时使用
- `replace` 只在 `cs` **生成新包围**时使用。
:::

1. `add`（添加分隔符）

- **`List<String>`** ：左右分割符 `[left, right]`
- **Funcref**：
  - 入参：`char`，当前键入的触发字符。
  - 出参：`[left, right]`（二元字符串列表），返回空列表表示放弃操作。

2. `find`（定位包围对）

- 入参：`char`，当前键入的触发字符。
- 出参：命中时返回包围字典，未命中返回 `{}`；字典各键如下：

| 键          | 类型               | 必填 | 含义                                             |
| ----------- | ------------------ | ---- | ------------------------------------------------ |
| `first_pos` | `[Number, Number]` | 是   | 外框起点：开分隔符首字节，`[行, 字节列]`         |
| `last_pos`  | `[Number, Number]` | 是   | 外框终点：闭分隔符末字节，`[行, 字节列]`         |
| `open_len`  | `Number`           | 否   | 开分隔符占几字节，建议都写                       |
| `close_len` | `Number`           | 否   | 闭分隔符占几字节，建议都写                       |

3. `replace`（替换分隔符）

- 出参：`[left, right]`（新的左右分隔符）；返回空列表表示放弃本次替换。
- 例：`function('im#surround#change#tag')`。


## g:im_surround_aliases

List 类型，建议先用 `im#surround#config#default_aliases()` 取默认值再改。

| 字段      | 赋值要求                 | 说明            |
| --------- | ------------------------ | --------------- |
| `key`     | Char（必填，支持CJK）    | 别名触发字符    |
| `targets` | `List<String>`（必填）     | 目标 `key` 列表 |

`ds` / `cs` 时输入别名键，会在 `targets` 列出的所有目标中，挑选光标处**最内层**的那一对。

默认别名如下：

```vim
let s:default_aliases = [
      \ {'key': 'q', 'targets': ['"', "'"]},
      \ {'key': 'r', 'targets': [']']},
      \ {'key': 'b', 'targets': [')']},
      \ {'key': 'B', 'targets': ['}']},
      \ ]
```

::: info
所有 g:im_surround_* 选项均支持 b:（buffer 级别）局部覆盖，优先级规则为：b: > g: > 默认值。
surrounds 与 aliases 均采用整体替换语义：一旦自定义设置，默认表将被完全取代，因此如需保留默认项建议先通过函数获取再拼接。
:::


## 内置函数一览

内置 `add` / `replace` 函数：

| 函数                          | 入参 → 出参            | 用途                                          |
| ----------------------------- | ---------------------- | --------------------------------------------- |
| `im#surround#add#tag`         | `ch` → `[left, right]` | 输入标签名与属性，生成 `<tag ...>` / `</tag>` |
| `im#surround#add#func`        | `ch` → `[left, right]` | 输入函数名，生成 `name(...)`                  |
| `im#surround#add#input`       | `ch` → `[left, right]` | 分别输入左右分隔符                            |
| `im#surround#add#invalid`     | `ch` → `[left, right]` | 直接使用所键入的字符作为左右分隔符            |
| `im#surround#change#tag`      | 无 → `[left, right]`   | 替换标签名，保留原属性                        |
| `im#surround#change#tag_full` | 无 → `[left, right]`   | 替换标签名，丢弃原属性                        |
| `im#surround#change#func`     | 无 → `[left, right]`   | 替换函数名                                    |

内置 `find` 函数：

| 函数                          | 适用场景                                             |
| ----------------------------- | ---------------------------------------------------- |
| `im#surround#find#matchpair`  | 左右不同的定界符（`()` `[]` `{}` `<>` 及全角括号等） |
| `im#surround#find#quote`      | 左右相同的引号                                       |
| `im#surround#find#tag`        | HTML / XML 标签（复用原生 `at`）                     |
| `im#surround#find#func`       | 函数调用                                             |
| `im#surround#find#invalid`    | 兜底：光标左右最近的同名字符成对                     |
| `im#surround#find#pattern`    | 自定义正则，签名为 `fun(ch, opt)`，见下              |


用 `im#surround#find#pattern` 自定义正则包围（`add` / `ds` / `cs` 均可）：

```vim
let b:im_surround_surrounds = [
      \ {'key': 'b', 'add': ['**', '**'],
      \  'find': {ch -> im#surround#find#pattern(ch,
      \    {'open_pat': '\V**', 'close_pat': '\V**', 'scope': 'line'})}},
      \ ]
```

- 入参 `opt` 为一个字典：
  - `open_pat` / `close_pat`：左右两侧的 Vim 正则，字面量建议加 `\V` 前缀。
  - `scope`：`'line'`（默认）只在当前行内匹配；`'buffer'` 允许跨行匹配。


## 进阶使用案例：Markdown 专属快捷键

你可以通过 FileType 自动命令为特定文件类型（如 Markdown）动态扩展包围规则：

```vim
augroup RimeGroup
  autocmd!
  autocmd FileType markdown call IMSurroundMarkdown()
augroup END

function! IMSurroundMarkdown() abort
  let b:im_surround_surrounds = g:im_surround_surrounds + [
        \ {'key': 'i', 'add': ['*', '*'],     'find': {ch -> im#surround#find#pattern(ch, {'open_pat': '\V*', 'close_pat': '\V*', 'scope': 'line'})}},
        \ {'key': 'b', 'add': ['**', '**'],   'find': {ch -> im#surround#find#pattern(ch, {'open_pat': '\V**', 'close_pat': '\V**', 'scope': 'line'})}},
        \ {'key': 'h', 'add': ['==', '=='],   'find': {ch -> im#surround#find#pattern(ch, {'open_pat': '\V==', 'close_pat': '\V==', 'scope': 'line'})}},
        \ {'key': 'c', 'add': ['`', '`'],     'find': {ch -> im#surround#find#pattern(ch, {'open_pat': '\V`', 'close_pat': '\V`', 'scope': 'line'})}},
        \ {'key': 'C', 'add': ['```', '```'], 'find': {ch -> im#surround#find#pattern(ch, {'open_pat': '\V```\.\*', 'close_pat': '\V```', 'scope': 'buffer'})}},
        \ {'key': 'm', 'add': ['$', '$'],     'find': {ch -> im#surround#find#pattern(ch, {'open_pat': '\V$', 'close_pat': '\V$', 'scope': 'line'})}},
        \ {'key': 'M', 'add': ['$$', '$$'],   'find': {ch -> im#surround#find#pattern(ch, {'open_pat': '\V$$', 'close_pat': '\V$$', 'scope': 'buffer'})}},
        \ {'key': 'l', 'add': ['[', ']()'],   'find': {ch -> im#surround#find#pattern(ch, {'open_pat': '\V[', 'close_pat': '\V](\.\{-})', 'scope': 'line'})}},
        \ {'key': 'L', 'add': ['![', ']()'],  'find': {ch -> im#surround#find#pattern(ch, {'open_pat': '\V![', 'close_pat': '\V](\.\{-})', 'scope': 'line'})}},
        \ {'key': 'w', 'add': ['[[', ']]'],   'find': {ch -> im#surround#find#pattern(ch, {'open_pat': '\V[[', 'close_pat': '\V]]', 'scope': 'line'})}},
        \ {'key': 'W', 'add': ['![[', ']]'],  'find': {ch -> im#surround#find#pattern(ch, {'open_pat': '\V![[', 'close_pat': '\V]]', 'scope': 'line'})}},
      \ ]
endfunction

```
