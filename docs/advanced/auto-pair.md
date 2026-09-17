---
title: Auto Pair 自动成对
description: 括号引号自动成对配置
---

<!-- 本页内容由 README.md 切分生成，与 README.md 同步维护 -->

# Auto Pair 自动成对

::: tip
替换模式下会自动关闭成对功能
:::

| 功能     | 按键         | 效果                       | 说明                                               |
| -------- | ------------ | -------------------------- | --------------------------------------------------- |
| 成对补全 | `(` `「` `"` | (\|)　「\|」　"\|"         | 输入开符时自动补全闭符，并将光标移回中间             |
| 闭符跳出 | `)` `」` `"` | ()\|　「」\|　""\|         | 光标右侧已有相同闭符/引号时直接跳出，不重复插入      |
| 空对删除 | `<BS>`       | (\|) → 删除 → \|           | 在空对（开符紧邻闭符）中一次性删除整对               |
| 只删开符 | `<s-bs>`     | (\|) → 删除 → \|)          | 在空对（开符紧邻闭符）中只删除开符，保留闭符         |
| 手动跳过 | `;j`         | (\|) → 越过一个 → ()\|     | 跳过右侧一个闭符/引号（`im#pair#jump_any`）          |
| 手动连跳 | `;J`         | (\|))) → 越过全部 → ()))\| | 跳过右侧连续多个闭符/引号（`im#pair#jump_many`）     |

- 默认配对：`()` `[]` `{}` `<>` `"` `'`，以及全角 `（）` `【】` `「」` `『』` `《》` `“”` `‘’`
- 无论半角标点直接上屏，还是全角标点经 Rime 上屏，两种情况均可正确识别配对
- 配置优先级：`b:im_pair_rules` > `g:im_pair_rules` > 默认值（仅 `im_pair_rules` 支持 `b:` 局部配置，其余选项均为全局 `g:`）
- 高亮黑名单：当光标位于名单内的高亮组（如注释、字符串）时，自动成对会临时关闭，离开后自动恢复。**默认关闭**，未设置或设为空列表时不生效：

## 配置

```vim
" 自动成对开关（默认 0）
let g:im_pair_enabled = 0
" 配对规则列表，每条包含 open/close 与 kind（'matchpair' 表示开闭符不同，'quote' 表示开闭符相同）
let g:im_pair_rules = [
      \ {'open': '(',  'close': ')',  'kind': 'matchpair'},
      \ {'open': '[',  'close': ']',  'kind': 'matchpair'},
      \ {'open': '{',  'close': '}',  'kind': 'matchpair'},
      \ {'open': '<',  'close': '>',  'kind': 'matchpair'},
      \ {'open': '（', 'close': '）', 'kind': 'matchpair'},
      \ {'open': '【', 'close': '】', 'kind': 'matchpair'},
      \ {'open': '「', 'close': '」', 'kind': 'matchpair'},
      \ {'open': '『', 'close': '』', 'kind': 'matchpair'},
      \ {'open': '《', 'close': '》', 'kind': 'matchpair'},
      \ {'open': "‘",  'close': "’",  'kind': 'matchpair'},
      \ {'open': "“",  'close': "”",  'kind': 'matchpair'},
      \ {'open': '"',  'close': '"',  'kind': 'quote'},
      \ {'open': "'",  'close': "'",  'kind': 'quote'},
      \ ]

" 等价于
let g:im_pair_rules = im#pair#default_rules()


" 作用域黑名单
" 键为 &filetype，'*' 为全局默认；命中具体 filetype 则只用该条，不与 '*' 合并
" 值字段：
"   disabled: 1 则该 filetype 下完全关闭自动成对
"   syntax: vim 高亮组名的正则列表（大小写不敏感，如 'comment' 可命中 Comment/vimCommentTitle）
"   ts: treesitter 节点类型的子串列表（大小写不敏感，仅 Neovim 生效，Vim 下忽略）
" syntax 与 ts 为“或”关系，命中任一即暂停；两者皆空则不生效
let g:im_pair_config = {
      \ '*': {'syntax': ['comment', 'string'], 'ts': ['comment', 'string']},
      \ 'txt': {'disabled': 1}
      \ }

```

## `g:im_pair_rules`

- `open` : 开符
- `close` : 闭符
- `kind` : `matchpair` 表示开闭符不同，`quote` 表示开闭符相同

::: info
优先级 `b:im_pair_rules` > `g:im_pair_rules` > 默认
:::


## `g:im_pair_config`

按作用域关闭自动成对。键名可为具体 `filetype` 或 `*`（表示全局通配）；特定 `filetype` 的配置会整体覆盖 `*` 的设置。

可用字段：

- `disabled`：布尔值。设为 1 时直接关闭该 filetype 下的自动成对，并短路其余字段。
- `syntax`：列表。大小写不敏感地匹配光标处的高亮组名（Syntax Group）。
- `ts`：列表。匹配 Tree-sitter 节点类型（仅 Neovim 生效）。

::: info
`ts` 与 `syntax` 之间为「或」的关系，命中任一即可触发关闭；两者同时配置时优先判定 ts。
:::


## 快捷键


```vim
" 自动成对切换快捷键
inoremap <silent> ;p <cmd>call im#pair#toggle()<cr>
nnoremap <silent> ;p <cmd>call im#pair#toggle()<cr>

function RimeKeymapRemap()
  inoremap <expr> ;j im#pair#jump_any()   " 跳过右侧一个闭符/引号
  inoremap <expr> ;J im#pair#jump_many()  " 跳过右侧连续一串闭符/引号

  lnoremap <silent><expr> <bs> im#state#composing() ?
        \ "\<cmd>call im#key(g:RIME_KEYCODE.BackSpace, 0)\<CR>" :
        \ im#replace#can_restore() ? "\<cmd>call im#replace#bs()\<cr>" :
        \ im#pair#should_bs_pair() ? im#pair#bs() : "\<bs>"

  lnoremap <silent><expr> <s-bs> im#state#composing() ?
        \ "\<cmd>call im#key(g:RIME_KEYCODE.BackSpace, g:RIME_MASK.Shift)\<CR>" :
        \ im#replace#can_restore() ? "\<cmd>call im#replace#bs()\<cr>" :
        \ im#pair#should_bs_pair() ? "\<bs>" : "\<s-bs>"

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
