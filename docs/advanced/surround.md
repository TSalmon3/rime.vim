---
title: Surround 包围编辑
description: 包围规则、别名与内置函数
---

<!-- 本页内容由 README.md 切分生成，与 README.md 同步维护 -->

# Surround 包围编辑

为选区、文本对象或整行**添加、删除、替换**成对分隔符（括号、引号、HTML 标签、函数调用等），并额外支持全角符号。

默认按键映射（均可用对应的 `g:im_surround_*_key` 定制）：

| 按键                        | 模式                    | 说明                               |
| --------------------------- | ----------------------- | ---------------------------------- |
| `[count]ys{motion}{char}`   | normal                  | 为 motion 选中的内容添加分隔符     |
| `[count]yS{motion}{char}`   | normal                  | 同上，但分隔符独占首尾新行         |
| `[count]yss` / `[count]ySS` | normal                  | 为整行添加分隔符（`ySS` 独占新行） |
| `[count]ds{char}`           | normal                  | 删除光标处最近的分隔符             |
| `[count]cs{old}{new}`       | normal                  | 将旧分隔符替换为新分隔符           |
| `[count]cS{old}{new}`       | normal                  | 同上，新分隔符独占首尾新行         |
| `S` / `gS`                  | visual                  | 为选区添加分隔符（`gS` 独占新行）  |
| `<c-g>s` / `<c-g>S`         | insert                  | 插入一对分隔符并将光标置于中间     |
| `ib` / `ab`                 | visual/operator-pending | 自动识别最近包围，选中其内部/整体  |

常见用法示例（`*` 为光标位置）：

| 旧文本                       | 按键     | 新文本                 | 说明              |
| :--------------------------- | :------- | :--------------------- | :---------------- |
| `surr*ound_words`            | `ysiw)`  | `(surr*ound_words)`    | 紧凑括号包裹单词  |
| `surr*ound_words`            | `ysiw(`  | `( surr*ound_words )`  | 带空格括号包裹    |
| `*make strings`              | `ys$"`   | `"*make strings"`      | 引号包裹到行尾    |
| `[delete ar*ound me!]`       | `ds]`    | `delete ar*ound me!`   | 删除方括号        |
| `remove \<b>HTML t*ags\</b>` | `dst`    | `remove HTML t*ags`    | 删除标签对        |
| `'change quot*es'`           | `cs'"`   | `"change quot*es"`     | 单引号换双引号    |
| `delete(functi*on calls)`    | `dsf`    | `functi*on calls`      | 删除函数调用      |
| `surr*ound_words`            | `2ysiw)` | `((surr*ound_words))`  | 叠两层紧凑括号    |
| `((delete ar*ound me!))`     | `2ds)`   | `(delete ar*ound me!)` | 删外层（第 2 层） |
| `(f*oo)`                     | `dsa`    | `foo`                  | 自动识别并删除    |
| `(f*oo)`                     | `dib`    | `()`                   | 删内部，保留括号  |
| `(f*oo)`                     | `dab`    | `(空)`                 | 删整体，包括括号  |

**前置计数**：在 `ys / yss / ds / cs` 前加数字。`ys` 系一次套多层，如 `2ysiw)` 得到 `((word))`；`ds / cs` 系操作由内向外第 N 层，如嵌套括号内 `2ds)` 删外层、`2cs)]` 换外层。

**点重复**：`ys / yss / ds / cs` 做完后按 `.` 可在别处重复上一次操作，不用重输符号，如 `ysiw)` 后移动光标按 `.` 直接套同种括号。`S / gS` 可视包裹和 `insert` 的 `<C-g>s / <C-g>S` 不支持 `.`。

## 配置

```vim
" 包围功能开关（默认 0）
let g:im_surround_enable = 1

" 自定义快捷键
let g:im_surround_add_key              = 'ys'     " 加包围 (normal)
let g:im_surround_add_cur_key          = 'yss'    " 整行加包围 (normal)
let g:im_surround_add_linewise_key     = 'yS'     " 加包围-新行式 (normal)
let g:im_surround_add_cur_linewise_key = 'ySS'    " 整行加包围-新行式 (normal)
let g:im_surround_delete_key           = 'ds'     " 删包围 (normal)
let g:im_surround_change_key           = 'cs'     " 换包围 (normal)
let g:im_surround_change_linewise_key  = 'cS'     " 换包围-新行式 (normal)
let g:im_surround_visual_key           = 'S'      " 可视模式包裹 (visual)
let g:im_surround_visual_linewise_key  = 'gS'     " 可视模式新行包裹 (visual)
let g:im_surround_insert_key           = '<C-g>s' " 插入模式插入 (insert)
let g:im_surround_insert_linewise_key  = '<C-g>S' " 插入模式换行插入 (insert)
let g:im_surround_ib_key               = 'ib'     " 文本对象-内部 (visual/operator-pending)
let g:im_surround_ab_key               = 'ab'     " 文本对象-整体 (visual/operator-pending)

" ds / cs 定位到包围对时的闪光高亮时长（毫秒，0 关闭）
let g:im_surround_flash_ms          = 120

" 独占新行 / 跨行操作后自动重缩进（默认 1）
let g:im_surround_indent            = 1

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
      \ {'key': 'a',  'find': function('im#surround#find#auto')},
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
      \ {'key': '[', 'targets' : ['{', '[', '「', '『', '【']},
      \ {'key': ']', 'targets' : ['}', ']', '」', '』', '】']},
      \ {'key': '{', 'targets' : ['{', '[', '「', '『', '【']},
      \ {'key': '}', 'targets' : ['}', ']', '」', '』', '】']},
      \ {'key': '「', 'targets' : ['{', '[', '「', '『', '【']},
      \ {'key': '」', 'targets' : ['}', ']', '」', '』', '】']},
      \ {'key': '『', 'targets' : ['{', '[', '「', '『', '【']},
      \ {'key': '』', 'targets' : ['}', ']', '」', '』', '】']},
      \ {'key': '【', 'targets' : ['{', '[', '「', '『', '【']},
      \ {'key': '】', 'targets' : ['}', ']', '」', '』', '】']},
      \ {'key': '<', 'targets' : ['<',  '《']},
      \ {'key': '>', 'targets' : ['>', '》' ]},
      \ {'key': '《', 'targets' : ['《',  '<']},
      \ {'key': '》', 'targets' : ['》', '>' ]}
      \ ]
```

## g:im_surround_surrounds

该项为 `List`，推荐基于 `im#surround#config#default_surrounds()` 扩展。

| 字段      | 类型                              | 含义                                      |
| --------- | --------------------------------- | ----------------------------------------- |
| `key`     | `String`                          | 触发字符；为空或类型不符整项失效          |
| `add`     | `List` 或 `Funcref(char) -> List` | 添加时分隔符来源                          |
| `find`    | `Funcref(char) -> Dict`           | `ds` / `cs` 定位旧包围                    |
| `replace` | `Funcref() -> List`               | `cs` 生成新分隔符；缺省则高亮旧包围等新键 |

`add` 只管添加，`find` 只管 `ds` / `cs` 定位，`replace` 只管 `cs` 生成。

**add**

| 形式      | 入参   | 返回值                    | 含义               |
| --------- | ------ | ------------------------- | ------------------ |
| `List`    | —      | `[String, String]`        | 直接赋值左右分隔符 |
| `Funcref` | `char` | `[String, String]` / `[]` | 动态生成，空表放弃 |

**find**

| 形式      | 入参   | 返回值        | 含义                                  |
| --------- | ------ | ------------- | ------------------------------------- |
| `Funcref` | `char` | `Dict` / `{}` | 定位光标处旧包围，供 `ds` / `cs` 使用 |

命中返回 `Dict` 键值如下：

| 键          | 类型               | 必填 | 含义                          |
| ----------- | ------------------ | ---- | ----------------------------- |
| `first_pos` | `[Number, Number]` | 是   | 开分隔符首字节 `[行, 字节列]` |
| `last_pos`  | `[Number, Number]` | 是   | 闭分隔符末字节 `[行, 字节列]` |
| `open_len`  | `Number`           | 否   | 开分隔符字节数                |
| `close_len` | `Number`           | 否   | 闭分隔符字节数                |

**replace**

| 形式      | 入参 | 返回值                 | 含义                   |
| --------- | ---- | ---------------------- | ---------------------- |
| `Funcref` | —    | `[left, right]` / `[]` | 新左右分隔符，空表放弃 |

## g:im_surround_aliases

该项为 `List`，建议先用 `im#surround#config#default_aliases()` 取默认再改。

| 字段      | 类型     | 含义            |
| --------- | -------- | --------------- |
| `key`     | `String` | 别名触发字符    |
| `targets` | `List`   | 目标 `key` 列表 |

`ds` / `cs` 输入别名键时，在 `targets` 的所有目标中挑光标处最内层的一对。

默认别名如下：

```vim
let s:default_aliases = [
      \ {'key': 'q', 'targets': ['"', "'"]},
      \ {'key': 'r', 'targets': [']']},
      \ {'key': 'b', 'targets': [')']},
      \ {'key': 'B', 'targets': ['}']},
      \ ]
```

所有 g:im_surround_\* 支持 b: 局部覆盖，优先级为 b: > g: > 默认值。surrounds 与 aliases 为整体替换语义，自定义后默认全被取代，需先取默认再拼接。

## 内置函数一览

内置 `add` / `replace` 函数（`add` 入参均为 `ch`，`replace` 均无入参，出参均为 `[left, right]` / `[]`）：

| 函数                          | 入参 | 返回值                 | 含义                 |
| ----------------------------- | ---- | ---------------------- | -------------------- |
| `im#surround#add#tag`         | `ch` | `[left, right]` / `[]` | 输标签名与属性       |
| `im#surround#add#func`        | `ch` | `[left, right]` / `[]` | 输函数名             |
| `im#surround#add#input`       | `ch` | `[left, right]` / `[]` | 各输左右分隔符       |
| `im#surround#add#invalid`     | `ch` | `[left, right]` / `[]` | 所键字符作左右分隔符 |
| `im#surround#change#tag`      | —    | `[left, right]` / `[]` | 换标签名，留属性     |
| `im#surround#change#tag_full` | —    | `[left, right]` / `[]` | 换标签名，去属性     |
| `im#surround#change#func`     | —    | `[left, right]` / `[]` | 换函数名             |

内置 `find` 函数（入参均为 `ch`，`pattern` 多一个 `opt`）：

| 函数                         | 入参      | 返回值        | 含义                         |
| ---------------------------- | --------- | ------------- | ---------------------------- |
| `im#surround#find#matchpair` | `ch`      | `Dict` / `{}` | 左右不同定界符               |
| `im#surround#find#quote`     | `ch`      | `Dict` / `{}` | 左右相同引号                 |
| `im#surround#find#tag`       | `ch`      | `Dict` / `{}` | HTML / XML 标签（复用 `at`） |
| `im#surround#find#func`      | `ch`      | `Dict` / `{}` | 函数调用                     |
| `im#surround#find#invalid`   | `ch`      | `Dict` / `{}` | 兜底同字符成对               |
| `im#surround#find#auto`      | `ch`      | `Dict` / `{}` | 自动识别最近包围             |
| `im#surround#find#pattern`   | `ch, opt` | `Dict` / `{}` | 自定义正则，见下             |

用 `im#surround#find#pattern` 自定义正则包围（`add` / `ds` / `cs` 均可）：

```vim
let b:im_surround_surrounds = [
      \ {'key': 'b', 'add': ['**', '**'],
      \  'find': {ch -> im#surround#find#pattern(ch,
      \    {'open_pat': '\V**', 'close_pat': '\V**', 'scope': 'line'})}},
      \ ]
```

其中 `opt` 字段键值如下

| 字段        | 含义                                     |
| ----------- | ---------------------------------------- |
| `open_pat`  | 左侧 Vim 正则，字面加 `\V`               |
| `close_pat` | 右侧 Vim 正则，字面加 `\V`               |
| `scope`     | `line` 仅当前行（默认），`buffer` 可跨行 |

## 进阶使用案例

你可以通过 FileType 自动命令为特定文件类型（如 Markdown）动态扩展包围规则：

````vim
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
````
