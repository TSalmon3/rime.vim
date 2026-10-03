---
title: Auto Pair 自动成对
description: 括号引号自动成对配置
---

<!-- 本页内容由 README.md 切分生成，与 README.md 同步维护 -->

# Auto Pair 自动成对

::: tip
替换模式下会自动关闭成对功能
:::

| 功能     | 按键         | 效果                       | 说明                                             |
| -------- | ------------ | -------------------------- | ------------------------------------------------ |
| 成对补全 | `(` `「` `"` | (\|)　「\|」　"\|"         | 输入开符时自动补全闭符，并将光标移回中间         |
| 闭符跳出 | `)` `」` `"` | ()\|　「」\|　""\|         | 光标右侧已有相同闭符/引号时直接跳出，不重复插入  |
| 空对删除 | `<bs>`       | (\|) → 删除 → \|           | 在空对（开符紧邻闭符）中一次性删除整对           |
| 只删开符 | `<s-bs>`     | (\|) → 删除 → \|)          | 在空对（开符紧邻闭符）中只删除开符，保留闭符     |
| 回车展开 | `<cr>`       | (\|) → 回车 → (⏎\|⏎)       | 空对中分三行，光标留中行；只管分行不管缩进       |
| 空格展开 | `<space>`    | (\|) → 空格 → ( \| )       | 空对中两侧各垫一空格；需自配含空格规则           |
| 手动跳过 | `;j`         | (\|) → 越过一个 → ()\|     | 跳过右侧一个闭符/引号（`im#pair#jump_any`）      |
| 手动连跳 | `;J`         | (\|))) → 越过全部 → ()))\| | 跳过右侧连续多个闭符/引号（`im#pair#jump_many`） |

- 默认配对：`()` `[]` `{}` `"` `'`，以及全角 `（）` `【】` `「」` `『』` `《》` `“”` `‘’`
- 无论半角标点直接上屏，还是全角标点经 Rime 上屏，两种情况均可正确识别配对
- 配置优先级：`b:im_pair_rules` > `g:im_pair_rules` > 默认值（仅 `im_pair_rules` 支持 `b:` 局部配置，其余选项均为全局 `g:`）
- 高亮黑名单：当光标位于名单内的高亮组（如注释、字符串）时，自动补全/删除/展开临时关闭，离开后自动恢复，但跳过（自动跳出与 `;j` / `;J`）不受影响。**默认关闭**，未设置或设为空列表时不生效：

## 配置

```vim
" 自动成对开关（默认 0）
let g:im_pair_enabled = 0
" 拦截 ([{'" 等 imap 映射（默认1）
let g:im_pair_imap_enabled = 1
" 配对规则列表，每条包含 open/close、kind 与可选的 with_* 门控
let g:im_pair_rules = [
      \ {'open': '(',  'close': ')',  'kind': 'matchpair'},
      \ {'open': '[',  'close': ']',  'kind': 'matchpair'},
      \ {'open': '{',  'close': '}',  'kind': 'matchpair'},
      \ {'open': '（', 'close': '）', 'kind': 'matchpair', 'with_cr': im#pair#cond#never()},
      \ {'open': '【', 'close': '】', 'kind': 'matchpair', 'with_cr': im#pair#cond#never()},
      \ {'open': '「', 'close': '」', 'kind': 'matchpair', 'with_cr': im#pair#cond#never()},
      \ {'open': '『', 'close': '』', 'kind': 'matchpair', 'with_cr': im#pair#cond#never()},
      \ {'open': '《', 'close': '》', 'kind': 'matchpair', 'with_cr': im#pair#cond#never()},
      \ {'open': "‘",  'close': "’",  'kind': 'matchpair', 'with_cr': im#pair#cond#never()},
      \ {'open': "“",  'close': "”",  'kind': 'matchpair', 'with_cr': im#pair#cond#never()},
      \ {'open': '"',  'close': '"',  'kind': 'quote', 'with_cr': im#pair#cond#never()},
      \ {'open': "'",  'close': "'",  'kind': 'quote', 'with_cr': im#pair#cond#never()},
      \ ]

" 等价于
let g:im_pair_rules = im#pair#default_rules()


" 作用域黑名单
let g:im_pair_config = {
      \ '*': {'syntax': ['comment', 'string'], 'ts': ['comment', 'string']},
      \ 'txt': {'disabled': 1}
      \ }

```

## `g:im_pair_config`

按 `filetype` 暂停自动成对功能。键名可为具体 `filetype`，也可用 `*` 表示全局默认；命中具体 `filetype` 时整体覆盖 `*` 对应配置，两者不合并。

字段说明：

- `disabled`（`Number`）：为 `1` 时该 `filetype` 完全停用
- `syntax`（`List`）：高亮组命中即暂停
- `ts`（`List`）：treesitter capture 命中即暂停

::: tip
- `syntax` / `ts` 命中时，仅暂停**改字类动作**（自动补全、成对删除、回车 / 空格展开），**跳出动作不受影响**：光标右侧已有闭符时仍可自动跳出，`im#pair#jump_any()` / `im#pair#jump_many()` 照常可用（例如字符串 `"foo|"` 处按 `"` 会直接跳到引号外）
- 只有 `disabled: 1` 才会完全停用（含跳出动作），且此时会忽略同条目下的 `syntax` / `ts` 配置
- `ts` 与 `syntax` 为“或”关系，命中任一即暂停；两者同时配置时优先判定 `ts`；两者均为空时不生效；匹配均不区分大小写
:::

## `g:im_pair_rules`

`with_pair` / `with_move` / `with_del` / `with_cr` 均为“门控函数”：返回 `true` 时放行对应动作，返回 `false` 时拦截；传入列表时按 AND 求值（全部为真才放行）。

参数说明：

- `open`（`String`）：开符
- `close`（`String`）：闭符
- `kind`（`String`）：`matchpair` 表示开闭符不同，`quote` 表示开闭符相同
- `with_pair`（`Funcref(ctx) -> Bool` 或其列表）：成对补全门控
- `with_move`（`Funcref(ctx) -> Bool` 或其列表）：闭符跳出门控
- `with_del`（`Funcref(ctx) -> Bool` 或其列表）：空对删除门控
- `with_cr`（`Funcref(ctx) -> Bool` 或其列表）：回车展开门控

其中 `ctx` 为 `Dict`，键值如下：

- `before`(`String`）：光标左侧的当前行文本片段
- `after`(`String`）：光标右侧的当前行文本片段
- `line`（`String`）：当前整行
- `col`（`Number`）：字节列号，即 `col('.')`
- `filetype`（`String`）：即 `&filetype`，可能为空

::: tip
优先级：`b:im_pair_rules` > `g:im_pair_rules` > 默认值
:::

## 内置函数一览

以下函数均返回 `Funcref(ctx) -> Bool`，用于 `with_pair` / `with_move` / `with_del` / `with_cr`。

**恒定结果：**

- `im#pair#cond#always()`：恒为真，始终放行
- `im#pair#cond#done()`：恒为真，与 `always()` 等价
- `im#pair#cond#never()`：恒为假，始终拦截
- `im#pair#cond#none()`：恒为假，与 `never()` 等价

**基于光标前后文本：**

- `im#pair#cond#before_text(t)`：`before` 以字符串 `t` 结尾时放行
- `im#pair#cond#not_before_text(t)`：上一条取反
- `im#pair#cond#before_regex(p)`：`before` 匹配 Vim 正则 `p` 时放行（自动补 `$` 锚尾）
- `im#pair#cond#not_before_regex(p)`：上一条取反
- `im#pair#cond#after_text(t)`：`after` 以字符串 `t` 开头时放行
- `im#pair#cond#not_after_text(t)`：上一条取反
- `im#pair#cond#after_regex(p)`：`after` 匹配 Vim 正则 `p` 时放行（自动补 `^` 锚首）
- `im#pair#cond#not_after_regex(p)`：上一条取反

**基于语法上下文：**

- `im#pair#cond#is_inside_quote()`：光标处于未转义引号内时放行
- `im#pair#cond#not_inside_quote()`：上一条取反
- `im#pair#cond#is_vim_comment()`：光标位于 vim 文件的注释行行首（该行仅有空白）时放行
- `im#pair#cond#not_vim_comment()`：上一条取反

```vim
" 引号内不再补全括号
let g:im_pair_rules = [
      \ {'open': '(', 'close': ')', 'with_pair': im#pair#cond#not_inside_quote()},
      \ {'open': '"', 'close': '"', 'with_move': im#pair#cond#always()},
      \ ]

" vim 中 `"` 在注释行行首不补全
autocmd FileType vim let b:im_pair_rules = [
      \ {'open': '"', 'close': '"', 'with_pair': im#pair#cond#not_vim_comment()},
      \ ]
```

## 按键映射

```vim
" 自动成对切换快捷键
inoremap <silent> ;p <cmd>call im#pair#toggle()<cr>
nnoremap <silent> ;p <cmd>call im#pair#toggle()<cr>

function RimeKeymapRemap()
  inoremap <expr> ;j im#pair#jump_any()   " 跳过右侧一个闭符/引号
  inoremap <expr> ;J im#pair#jump_many()  " 跳过右侧连续一串闭符/引号
endfunction

function RimeKeymapClear()
  silent! iunmap ;j
  silent! iunmap ;J
endfunction

augroup RimeGroup
  autocmd!
  autocmd User RimeKeymapSetup call RimeKeymapRemap()
  autocmd User RimeKeymapClear call RimeKeymapClear()
augroup END
```

**backspace**

```vim
function RimePairImapRemap()
  inoremap <buffer><expr> <bs> im#pair#should_bs() ? im#pair#bs() : "\<bs>"
  inoremap <buffer> <s-bs> <bs>
endfunction

function RimePairImapRestore()
  inoremap <buffer> <bs> <bs>
  inoremap <buffer> <s-bs> <bs>
endfunction

function RimeKeymapRemap()
  lnoremap <buffer><silent><expr> <bs> im#state#composing() ?
        \ "\<cmd>call im#composer#key(g:RIME_KEYCODE.BackSpace, 0)\<CR>" :
        \ im#replace#can_restore() ? "\<cmd>call im#replace#bs()\<cr>" :
        \ im#pair#should_bs() ? im#pair#bs() : "\<bs>"

  lnoremap <buffer><silent><expr> <s-bs> im#state#composing() ?
        \ "\<cmd>call im#composer#key(g:RIME_KEYCODE.BackSpace, g:RIME_MASK.Shift)\<CR>" :
        \ im#replace#can_restore() ? "\<cmd>call im#replace#bs()\<cr>" :
        \ im#pair#should_bs() ? "\<bs>" : "\<s-bs>"

endfunction

augroup RimeGroup
  autocmd!
  autocmd User RimeKeymapSetup call RimeKeymapRemap()
  autocmd User RimePairImapSetup call RimePairImapRemap()
  autocmd User RimePairImapRestore call RimePairImapRestore()
augroup END
```

**return**

```vim
function RimePairImapRemap()
  inoremap <buffer><expr> <cr> luaeval("require('blink.cmp').is_menu_visible()") && luaeval("require('blink.cmp').get_selected_item() ~= nil") ?
          \ "\<cmd>lua require('blink.cmp').accept()\<cr>"
          \ : pumvisible() && complete_info()['selected'] != -1 ? "\<c-y>"
          \ : im#pair#should_cr() ? im#pair#cr() : "\<cr>"
endfunction

function RimePairImapRestore()
  inoremap <silent><expr> <cr> luaeval("require('blink.cmp').is_menu_visible()") && luaeval("require('blink.cmp').get_selected_item() ~= nil") ?
        \ "\<cmd>lua require('blink.cmp').accept()\<cr>"
        \ : pumvisible() && complete_info()['selected'] != -1 ?
        \ "\<c-y>" : "\<cr>"
endfunction

function RimeKeymapRemap()
  lnoremap <buffer><silent><expr> <cr> im#state#composing() ?
          \ "\<cmd>call im#composer#key(g:RIME_KEYCODE.Return, 0)\<cr>"
          \ : im#pair#should_cr() ? im#pair#cr() : "\<cr>"

endfunction

augroup RimeGroup
  autocmd!
  autocmd User RimeKeymapSetup call RimeKeymapRemap()
  autocmd User RimePairImapSetup call RimePairImapRemap()
  autocmd User RimePairImapRestore call RimePairImapRestore()
augroup END

```

**space**

```vim

let g:im_pair_rules += [
      \ {'open': ' ', 'close': ' ',
      \  'with_pair': {c -> c.before[-1:] ==# '(' && c.after[:0] ==# ')'}},
      \ ]

function RimePairImapRemap()
  inoremap <buffer><expr> <space> im#pair#space()
endfunction

function RimePairImapRestore()
  inoremap <buffer> <space> <space>
endfunction

function RimeKeymapRemap()
  lnoremap <buffer><silent><expr> <space> im#state#composing() ?
        \ "\<cmd>call im#composer#key(g:RIME_KEYCODE.Space, 0)\<CR>" : im#pair#space()
endfunction

augroup RimeGroup
  autocmd!
  autocmd User RimeKeymapSetup call RimeKeymapRemap()
  autocmd User RimePairImapSetup call RimePairImapRemap()
  autocmd User RimePairImapRestore call RimePairImapRestore()
augroup END


```

## 事件

| 事件                  | 用途                                     |
| --------------------- | ---------------------------------------- |
| `RimePairImapSetup`   | 拦截：接管当前文件的退格 / 回车 / 空格键 |
| `RimePairImapRestore` | 还原：离开时恢复现场                     |

## 进阶使用案例

**markdown**

```vim
autocmd FileType markdown call IMPairMarkdown()
function! IMPairMarkdown() abort
  let b:im_pair_rules = deepcopy(g:im_pair_rules) + [
        \ {'open': "`",  'close': "`",  'kind': 'quote'},
        \ ]
endfunction
```

**vim**

```vim
autocmd FileType vim call IMPairVim()
function! IMPairVim() abort
  let b:im_pair_rules = deepcopy(g:im_pair_rules)
  call filter(b:im_pair_rules, {i, v -> v.open !=# '"'})
  call insert(b:im_pair_rules, {'open': '"',  'close': '"',  'kind': 'quote', 'with_cr': im#pair#cond#never(),
        \  'with_pair': im#pair#cond#not_vim_comment(), 'with_move': im#pair#cond#not_vim_comment()})
        \ ]
endfunction
```
