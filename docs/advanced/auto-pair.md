---
title: Auto Pair 自动成对
description: 括号引号自动成对配置
---

<!-- 本页内容由 README.zh.md 切分生成，与 README.zh.md 同步维护 -->

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
| 手动跳过 | `<c-tab>`    | (\|) → 越过一个 → ()\|     | 跳过右侧一个闭符/引号（`im#pair#jump_any`）          |
| 手动连跳 | `<c-g>`      | (\|))) → 越过全部 → ()))\| | 跳过右侧连续多个闭符/引号（`im#pair#jump_many`）     |

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

" 也可以直接使用默认规则
let g:im_pair_rules = im#pair#default_rules()

" 按 highlight 关闭自动成对：高亮组名支持正则列表（大小写不敏感），命中任一项即关闭自动成对（默认 []，不启用）
let g:im_pair_blacklist_highlight = ['comment', 'doc', 'string']
" 按 filetype 关闭自动成对
let g:im_pair_blacklist_filetypes = ['vim']

" 以下配置仅在 Neovim 中生效（需要 Treesitter 支持）；Vim 中高亮判断始终使用正则匹配
" 优先级：g:im_pair_blacklist_filetypes > g:im_pair_ts_config > g:im_pair_blacklist_highlight
let g:im_pair_ts_check  = 0

" '*' 表示全局通配规则，具体 filetype 的配置会覆盖全局配置（显式设为 [] 表示该 filetype 关闭检查）
let g:im_pair_ts_config = {
      \ '*':      ['comment', 'string'],
      \ 'lua':    ['comment', 'string'],
      \ 'python': ['comment', 'string'],
      \ }
```

## 快捷键


```vim
" 自动成对切换快捷键
inoremap <silent> ;p <cmd>call im#pair#toggle()<cr>
nnoremap <silent> ;p <cmd>call im#pair#toggle()<cr>

function RimeKeymapRemap()
  lnoremap <expr> <c-g> im#pair#jump_any()   " 跳过右侧一个闭符/引号
  lnoremap <expr> <c-tab> im#pair#jump_many()  " 跳过右侧连续一串闭符/引号

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
  silent! lunmap <c-g>
  silent! lunmap <c-tab>
endfunction

augroup RimeGroup
  autocmd!
  autocmd User RimeKeymapSetup call RimeKeymapRemap()
  autocmd User RimeKeymapClear call RimeKeymapClear()
augroup END
```
