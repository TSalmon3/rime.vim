<p align="center">
  <img alt="Logo" src="./icon.png" height="200" />
  <p align="center">Rime input method support for Vim/Neovim</p>
  <p align="center">
    <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square"></a>
    <a href="https://GitHub.com/Naereen/StrapDown.js/graphs/commit-activity"><img alt="Maintenance" src="https://img.shields.io/badge/Maintained%3F-yes-green.svg?style=flat-square"></a>
  </p>
</p>

---

<details>
<summary>写在最前面</summary>

<br>
对于常见的问题的统一回答。

- 是否会跟系统的 rime 输入法 产生冲突？

  ```answer
  会产生冲突，建议新建一个目录，存放你的拼音方案，也就是你的「用户数据目录」最好不要跟系统输入法的是同一目录。
  ```
</details>

---

## 目录

- [简介](#简介)
- [快速开始](#快速开始)
  - [环境要求](#环境要求)
  - [安装](#安装)
  - [编译后端](#编译后端)
- [配置](#配置)
  - [选项](#选项)
  - [环境变量](#环境变量)
- [使用](#使用)
  - [命令](#命令)
  - [按键映射](#按键映射)
- [集成](#集成)
  - [事件](#事件)
  - [状态栏](#状态栏)
- [高级主题](#高级主题)
  - [rime-ice 配置示例](#rime-ice-配置示例)
  - [让中文编辑更加丝滑](#让中文编辑更加丝滑)
  - [定制中英切换与方案选单](#定制中英切换与方案选单)
  - [Replace Mode 替换模式](#replace-mode-替换模式)
  - [Auto Pair 自动成对](#auto-pair-自动成对)
  - [其他搭配插件](#其他搭配插件)
- [致谢](#致谢)
- [License](#license)

## 简介

Rime（中州韵）输入法在 Vim / Neovim 中的集成方案，基于 [rime-ice](https://github.com/iDvel/rime-ice) 词库，同时支持 Vim（>= 8.2.1978）与 Neovim。

**用法**：进入插入模式后直接键入拼音，候选词浮窗出现；数字键或 `Up` / `Down` 选择候选，`Enter` / `Space` 上屏，`Esc` 取消本次组合。

![demo](https://github.com/user-attachments/assets/20978d66-c198-426f-97f1-0ba7322cf656)
![demo2](https://github.com/user-attachments/assets/820db16b-b76b-4b15-a5f4-a8a6a58306bd)

主要特性：

- 支持全拼、双拼、九宫格等输入方案
- 支持简繁、中英文标点、emoji 切换
- 候选词浮窗，下划线渲染，状态栏可显示当前输入状
- 支持括号、引号等自动补全
- 支持多实例共享词频学习，甚至 Vim 和 Neovim 混合多实例
- 提供命令行和终端输入解决方案

## 快速开始

### 环境要求

- Vim >= 8.2.1978 或 Neovim
- [librime](https://github.com/rime/librime)（编译后端所必需）
- Rime 共享数据目录与用户数据目录（例如 [rime-ice](https://github.com/iDvel/rime-ice)）

### 安装

- **vim.pack**

```vim
vim.pack.add({
  "https://github.com/TSalmon3/rime.vim"
})
```

- **vim-plug**

```vim
Plug 'TSalmon3/rime.vim'
```

### 编译后端

构建的 `rime-query` 可执行文件需能被找到（默认查找 `PATH`，也可通过 `g:im_rime_bin` 指定路径），否则 `:IMStart` 会失败。

> 以下命令中的仓库路径 `/path/to/rime.vim` 请替换为你的实际路径。

#### macOS

```bash
cd /path/to/rime.vim/cpp
brew install librime
clang++ -std=c++17 -I./3rd -I/opt/homebrew/include -L/opt/homebrew/lib -lstdc++ -lrime -o build/rime-query rime-query.cc
```

也可以使用 CMake（必要时修改 `CMakeLists.txt` 中的 librime include / lib 路径）：

```bash
cd /path/to/rime.vim/cpp
cmake -S . -B build
cmake --build build
```

#### Linux

需手动编译 librime，并分别指定其头文件 include 路径与动态库 lib 路径：

```bash
cd /path/to/rime.vim/cpp
clang++ -std=c++17 -I./3rd -I/path/to/librime/include -L/path/to/librime/lib -lstdc++ -lrime -o build/rime-query rime-query.cc
```

#### Windows

1. 下载 librime 预编译 release 压缩包，解压后得到包含 `include/` 与 `lib/` 的目录（下述命令中的 `/path/to/librime` 即指向该目录）。
2. 编译 `rime-query`。
3. 将 `rime.dll` 拷贝到可执行文件同一目录。
4. 将可执行文件所在目录加入 `PATH`，或在 vimrc 中用 `let g:im_rime_bin = '完整路径'` 直接指定。

```bash
cd /path/to/rime.vim/cpp
mkdir build
clang++ -std=c++17 -O2 -I./3rd -I/path/to/librime/include -c rime-query.cc -o build/rime-query.o
clang++ build/rime-query.o -L/path/to/librime/lib -lrime -lws2_32 -o build/rime-query.exe
```

其中 `-lws2_32` 链接 Windows Sockets，为后端 TCP 监听所必需；它是系统自带组件（System32），无需额外安装。

或者使用 CMake（必要时修改 `CMakeLists.txt` 中的编译器与 librime include / lib 路径）：

```bash
cd /path/to/rime.vim/cpp
cmake -S . -B build -G "MinGW Makefiles"
cmake --build build
```

> [!note]
>
> - 需要 `clang++` 与 `mingw32-make` 在 `PATH` 中；若已安装 Ninja，可省略 `-G` 参数（CMake 会优先选用）
> - 不要使用 Visual Studio 生成器——项目的编译选项是 clang/GCC 风格，MSVC 工具链无法识别

构建完成后，请把生成的 `rime-query` 添加到 `PATH`。

## 配置

### 选项

> [!Tip]
> 以雾凇拼音（rime-ice） 为例，如果你系统中已安装了「鼠须管」或者「小狼毫」，用户数据目录可以新建一个，避免产生冲突。

以下均为常用 `g:` 变量，可省略（使用默认值）。请在 vimrc 中、插件加载**之前**设置：

```vim
" rime-query 可执行文件路径（需在 PATH 中）
let g:im_rime_bin                  = 'rime-query'
" 用户数据目录，也就是你的拼音方案安装的目录（$RIME_USER_DATA_DIR）
let g:im_user_data_dir             = '/path/to/rime'
" 共享数据目录（$RIME_SHARED_DATA_DIR）
let g:im_shared_data_dir           = '/usr/share/rime-data'
" 后端日志路径（$RIME_LOG）
let g:im_log_file                  = '~/.local/state/log/vim/rime.log'


" Unix：socket 文件路径
" 留空时依 $XDG_RUNTIME_DIR，其次 ~/.cache/rime-query.sock
let g:im_unix_socket                = ''
" Windows：TCP 回环端点，Vim 与 Neovim 共用同一条通道
" 留空时默认 127.0.0.1:18666
let g:im_tcp_addr                   = ''
" 最后一个客户端离开后 daemon 的空闲存活时间（毫秒，0 为常驻）
let g:im_idle_exit_ms              = 60000
" 拉起 daemon 后等待其就绪的超时（毫秒）
let g:im_connect_timeout_ms        = 30000

" 候选词弹窗高度
let g:im_pumheight                 = 9
" 设为 1 关闭下划线渲染
let g:im_underline_disable         = 0
" 设为 1 不创建默认按键映射
let g:im_no_default_mappings       = 0
" 设为 1 在 R/gR 替换模式下启用 Rime（默认关闭）
let g:im_replace_mode              = 0
" 切换输入法开关
let g:im_toggle_key                = ';;'
" 切换中文/英文模式切换开关
let g:im_toggle_ascii_mode_key     = '<c-;>'
" 切换中英文标点
let g:im_toggle_ascii_punct_key    = ';a'
" 切换简繁体
let g:im_toggle_traditional_key    = ';f'
" 切换 emoji
let g:im_toggle_emoji_key          = ';e'
" :IMDeploy / :IMSync 的后端等待超时（毫秒）
let g:im_deploy_timeout            = 60000
" 状态栏图标
let g:im_status_text               = 'ㄓ'
" 半角标点状态文本
let g:im_status_half_text          = '$'
" 全角标点状态文本
let g:im_status_full_text          = '¥'
" 简体状态文本
let g:im_status_simplified_text    = '简'
" 繁体状态文本
let g:im_status_traditional_text   = '繁'
" 输入法断连状态文本
let g:im_status_disconnect         = '断'
" 初始标点状态（1 为半角）
let g:im_option_ascii_punct        = 0
" 初始简繁状态（1 为繁体）
let g:im_option_traditional        = 0


" 在 Cmdline 中使用
function! IMCmdEdit()
    let cmdtype = getcmdtype()
    if cmdtype != ':' && cmdtype != '/' && cmdtype != '?'
        return ''
    endif

    call im#start()

    let cmdline = getcmdline()
    if cmdline ==# ''
        call feedkeys("\<c-c>q" . cmdtype . 'a', 'nt')
    else
        let charPos = strchars(strpart(cmdline, 0, getcmdpos() - 1))
        let moveRight = charPos > 0 ? charPos . 'l' : ''
        call feedkeys("\<c-c>q" . cmdtype . 'k0' . moveRight . 'a', 'nt')
    endif
    return ''
endfunction
cnoremap <silent><expr> ;; IMCmdEdit()


" 在 Terminal 中使用
function! PassToTerm(text)
  let @t = a:text
  if has('nvim')
    call feedkeys('"tpa', 'nt')
  else
    call feedkeys("a\<c-w>\"t", 'nt')
  endif
  redraw!
endfunction
command! -nargs=* PassToTerm :call PassToTerm(<q-args>)
tnoremap ;; <c-\><c-n><cmd>call im#start()<cr>q:a:PassToTerm<space>
```

其中：

- `g:im_rime_bin` 对应后端可执行文件。
- `g:im_user_data_dir` / `g:im_shared_data_dir` / `g:im_log_file` 分别对应下述三个环境变量，且**优先级更高**。

各平台 / 编辑器的传输支持情况：

| 平台          | 编辑器 | 默认传输    | 可选传输 | 自定义端点                                  |
| ------------- | ------ | ----------- | -------- | ------------------------------------------- |
| macOS / Linux | Neovim | Unix socket | —        | `g:im_unix_socket`                          |
| macOS / Linux | Vim    | Unix socket | —        | `g:im_unix_socket`                          |
| Windows       | Neovim | TCP 回环    | —        | `g:im_tcp_addr` / 环境变量 `RIME_QUERY_TCP` |
| Windows       | Vim    | TCP 回环    | —        | `g:im_tcp_addr` / 环境变量 `RIME_QUERY_TCP` |

> [!Note]
> Windows 上 daemon 只监听单条 TCP 通道（Vim 与 Neovim 共用），
> 自定义 `g:im_tcp_addr` 时 vimrc 与 Neovim 配置需保持一致。

### 环境变量

插件通过三个环境变量获取数据目录与日志路径，两种设置方式任选其一：

#### 在 Vim 中设置

在 vimrc 中、插件加载前设置：

```vim
" RIME_LOG — 后端日志路径
let $RIME_LOG = expand("~/.local/state/log/vim/rime.log")

" RIME_USER_DATA_DIR — 用户数据目录
let $RIME_USER_DATA_DIR = "/path/to/rime"

" RIME_SHARED_DATA_DIR — 共享数据目录
let $RIME_SHARED_DATA_DIR = "/usr/share/rime-data"
```

#### 在终端中设置

如果希望这些目录对所有程序生效，可在 shell 配置（如 `~/.zshrc`）中导出：

```sh
export RIME_LOG="$HOME/.local/state/log/vim/rime.log"
export RIME_USER_DATA_DIR="$HOME/.local/share/rime-ice"
export RIME_SHARED_DATA_DIR="/usr/share/rime-data"
```

Windows 下还可通过 `RIME_QUERY_TCP` 覆盖后端 TCP 监听端点（默认 `127.0.0.1:18666`；
与 `g:im_tcp_addr` 同义，`g:im_tcp_addr` 优先）。

> 注意：在 Vim 中设置 `g:im_user_data_dir` / `g:im_shared_data_dir` / `g:im_log_file` 会覆盖同名环境变量。

## 使用

### 命令

| 命令          | 说明                                                  |
|---------------|-------------------------------------------------------|
| `:IMStart`    | 启动/重启输入法（连接或拉起共享 `rime-query` daemon） |
| `:IMStop`     | 停止输入法（只断开本编辑器的连接）                    |
| `:IMToggle`   | 切换输入法开关                                        |
| `:IMDeploy`   | 重新部署 Rime（改配置后生效）                         |
| `:IMSync`     | 同步用户词库并重新部署                                |
| `:IMShutdown` | 关停共享 daemon（所有编辑器断开）                     |

#### 重新部署

修改用户数据目录中的配置（如 `default.custom.yaml` 的 `schema_list` / `page_size`）后，执行 `:IMDeploy` 使改动生效。部署期间编辑器会短暂阻塞，超时可用 `g:im_deploy_timeout`（毫秒）调整。

#### 同步词库

`:IMSync` 先将用户词库（`*.userdb/`）与 `sync/<installation_id>/*.userdb.txt` 备份双向合并，再重新部署。便于跨设备、多平台同步个人词频；多台设备建议将 `installation.yaml` 中的 `installation_id` 设为同一值，否则可能合并失败。

### 按键映射

默认按键映射（可设 `g:im_no_default_mappings=1` 关闭，用对应的 `g:im_*_key` 修改）：

| 按键    | 模式                                 | 功能           |
| ------- | ------------------------------------ | -------------- |
| `;;`    | normal / insert / command / terminal | 切换输入法开关 |
| `<c-;>` | normal / insert                      | 切换中/英模式  |
| `;a`    | normal / insert                      | 切换中英文标点 |
| `;f`    | normal / insert                      | 切换简/繁体    |
| `;e`    | normal / insert                      | 切换 emoji     |

按键和组合键基本兼容系统级输入法

| 按键         | 功能               |
| ------------ | ------------------ |
| `<cr>`       | 拼音上屏           |
| `<space>`    | 选择               |
| `<left>`     | 光标左移           |
| `<right>`    | 光标右移           |
| `<up>`       | 上一个候选         |
| `<down>`     | 下一个候选         |
| `<c-p>`      | 上一个候选         |
| `<c-n>`      | 下一个候选         |
| `<pageup>`   | 上一页             |
| `<pagedown>` | 下一页             |
| `-`          | 上一页             |
| `=`          | 下一页             |
| `<bs>`       | 删除一个字符       |
| `<s-bs>`     | 删除一个音节       |
| `<tab>`      | 下一个音节结尾     |
| `<s-tab>`    | 下一个音节开头     |
| `<c-u>`      | 清空拼音           |
| `<c-w>`      | 删除一个音节       |
| `<c-d>`      | 删除自造词         |
| `<c-a>`      | 光标移动到拼音开头 |
| `<c-e>`      | 光标移动到拼音结尾 |

## 集成

### 事件

**`autocmd User RimeKeymapSetup {command}`**

插入模式按键映射建立后触发。

**`autocmd User RimeKeymapClear {command}`**

插入模式按键映射清除后触发。

**`autocmd User RimeIMEnable {command}`**

输入法使能后触发，可用于关闭其他插件补全。

**`autocmd User RimeIMDisable {command}`**

输入法禁用后触发，可用于使能其他插件补全。

示例：

```vim
function! im_nvim#hooks#on_enable() abort
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

function! im_nvim#hooks#on_disable() abort
  if exists('*coc#config')
    call coc#config('suggest.autoTrigger', 'always')
  endif
  if exists(':Codeium')
    Codeium Enable
  endif
  if exists('g:blink_cmp_enabled')
    let g:blink_cmp_enabled = v:true
  endif
endfunction

augroup IMGroup
  autocmd!
  autocmd User RimeIMEnable  call im_nvim#hooks#on_enable()
  autocmd User RimeIMDisable call im_nvim#hooks#on_disable()
augroup END
```

### 状态栏

最简单的方式是在你的 `'statusline'` 选项中加入 `%{IM_Status()}`。开启时显示
`[ㄓ]半|简`（图标 / 标点 / 简繁，文本可分别用 `g:im_status_*` 定制），关闭时返回空串。

```vim
let statusline^=%{IM_Status()}
```

## 高级主题

### rime-ice 配置示例

**`default.custom.yaml`**

```yaml
patch:
  schema_list:
    # 可以直接删除或注释不需要的方案，对应的 *.schema.yaml 方案文件也可以直接删除
    # 除了 t9，它依赖于 rime_ice，用九宫格别删 rime_ice.schema.yaml
    - schema: double_pinyin_flypy # 小鹤双拼
    - schema: rime_ice # 雾凇拼音（全拼）
    - schema: t9 # 九宫格（仓输入法）
    - schema: double_pinyin # 自然码双拼
    - schema: double_pinyin_abc # 智能 ABC 双拼
    - schema: double_pinyin_mspy # 微软双拼
    - schema: double_pinyin_sogou # 搜狗双拼
    - schema: double_pinyin_ziguang # 紫光双拼

  # 菜单
  menu:
    page_size: 5 # 候选词个数
```

**`double_pinyin_flypy.custom.yaml`**

```yaml
patch:
  schema:
    dependencies:
      - melt_eng # 英文输入，作为次翻译器挂载到拼音方案
      - radical_pinyin # 部件拆字，反查及辅码

  # 词频 {{{1
  "translator/enable_user_dict": true

  # 混拼 {{{1
  # 在 engine/filters 插入长词优先的 Lua
  # 双拼不转换为全拼编码
  translator/preedit_format: []

  engine/filters:
    - lua_filter@*corrector
    - reverse_lookup_filter@radical_reverse_lookup
    - lua_filter@*autocap_filter
    - lua_filter@*pin_cand_filter
    - lua_filter@*long_word_filter # 增加长词优先
    - lua_filter@*reduce_english_filter
    - simplifier@emoji
    - simplifier@traditionalize
    - lua_filter@*search@radical_pinyin
    - uniquifier

  # 长词优先设置为提升 10 个词到第 1 个位置
  long_word_filter:
    count: 10
    idx: 1

  # xform 变形改为 derive 派生
  speller/algebra:
    # 模糊音
    - derive/^([zcs])h/$1/
    - derive/^([zcs])([^h])/$1h$2/
    - derive/ang$/an/
    - derive/an$/ang/
    - derive/eng$/en/
    - derive/en$/eng/
    - derive/in$/ing/
    - derive/ing$/in/
    - derive/ian$/iang/
    - derive/iang$/ian/
    - derive/uan$/uang/
    - derive/uang$/uan/
    - derive/ong$/on/
      ### v u 转换
      # 雾凇的词库严格按照正确的 u v(ü) 注音的，下面两行支持使用错误的拼音，例如 qv nue 来响应 qu nve
    - derive/^([nl])ve$/$1ue/
    - derive/^([jqxy])u/$1v/
      # 以防引入的其他词库没按照正确方式注音，也做一个转换
    - derive/^([nl])ue$/$1ve/
    - derive/^([jqxy])v/$1u/

    # 双拼
    - derive/^([jqxy])u$/$1v/
    - derive/^([aoe])([ioun])$/$1$1$2/
    - derive/^([aoe])(ng)?$/$1$1$2/
    - derive/iu$/Ⓠ/
    - derive/(.)ei$/$1Ⓦ/
    - derive/uan$/Ⓡ/
    - derive/[uv]e$/Ⓣ/
    - derive/un$/Ⓨ/
    - derive/^sh/Ⓤ/
    - derive/^ch/Ⓘ/
    - derive/^zh/Ⓥ/
    - derive/uo$/Ⓞ/
    - derive/ie$/Ⓟ/
    - derive/(.)i?ong$/$1Ⓢ/
    - derive/ing$|uai$/Ⓚ/
    - derive/(.)ai$/$1Ⓓ/
    - derive/(.)en$/$1Ⓕ/
    - derive/(.)eng$/$1Ⓖ/
    - derive/[iu]ang$/Ⓛ/
    - derive/(.)ang$/$1Ⓗ/
    - derive/ian$/Ⓜ/
    - derive/(.)an$/$1Ⓙ/
    - derive/(.)ou$/$1Ⓩ/
    - derive/[iu]a$/Ⓧ/
    - derive/iao$/Ⓝ/
    - derive/(.)ao$/$1Ⓒ/
    - derive/ui$/Ⓥ/
    - derive/in$/Ⓑ/
    - xlit/ⓆⓌⓇⓉⓎⓊⒾⓄⓅⓈⒹⒻⒼⒽⒿⓀⓁⓏⓍⒸⓋⒷⓃⓂ/qwrtyuiopsdfghjklzxcvbnm/
```

### 让中文编辑更加丝滑

如果你安装了 [ultisnips](https://github.com/SirVer/ultisnips) 和 [bullets.vim](https://github.com/bullets-vim/bullets.vim)，你可以这样使用。

```vim
function RimeKeymapRemap()
  if &filetype ==# 'markdown'
    lnoremap <silent><expr> <tab> im#state#composing() ?
          \ "\<cmd>call im#key(g:RIME_KEYCODE.Tab, 0)\<CR>" :
          \ UltiSnips#CanJumpForwards() ?
          \"\<c-r>=UltiSnips#JumpForwards()\<cr>" :  bullet#is_bullet() ?
          \ "\<C-o>\<Plug>(bullets-demote)\<C-o>$" :  "\<tab>"

    lnoremap <silent><expr> <s-tab> im#state#composing() ?
          \ "\<cmd>call im#key(g:RIME_KEYCODE.Tab, g:RIME_MASK.Shift)\<CR>" :
          \ UltiSnips#CanJumpBackwards() ?
          \ "\<c-r>=UltiSnips#JumpBackwards()\<cr>" : bullet#is_bullet()?
          \ "\<C-o>\<Plug>(bullets-promote)\<C-o>$" : "\<s-tab>"

    lnoremap <silent><expr> <cr> im#state#composing() ?
          \ "\<cmd>call im#key(g:RIME_KEYCODE.Return, 0)\<cr>" :
          \ delimitMate#WithinEmptyPair() ?
          \ "\<c-r>=delimitMate#ExpandReturn()\<cr>" : "\<Plug>(bullets-newline)"
  else
    lnoremap <silent><expr> <tab> im#state#composing() ?
          \ "\<cmd>call im#key(g:RIME_KEYCODE.Tab, 0)\<CR>" :
          \ UltiSnips#CanJumpForwards() ?
          \"\<c-r>=UltiSnips#JumpForwards()\<cr>" : "\<tab>"

    lnoremap <silent><expr> <s-tab> im#state#composing() ?
          \ "\<cmd>call im#key(g:RIME_KEYCODE.Tab, g:RIME_MASK.Shift)\<CR>" :
          \ UltiSnips#CanJumpBackwards() ?
          \ "\<c-r>=UltiSnips#JumpBackwards()\<cr>" : "\<s-tab>"

    lnoremap <silent><expr> <cr> im#state#composing() ?
          \ "\<cmd>call im#key(g:RIME_KEYCODE.Return, 0)\<CR>" :
          \ delimitMate#WithinEmptyPair() ?
          \ "\<c-r>=delimitMate#ExpandReturn()\<cr>" : "\<cr>"
  endif
endfunction

function RimeKeymapClear()

endfunction

augroup RimeGroup
  autocmd!
  autocmd User RimeKeymapSetup call RimeKeymapRemap()
  autocmd User RimeKeymapClear call RimeKeymapClear()
augroup END
```

![demo3](https://github.com/user-attachments/assets/093e5089-0b8c-4528-854f-5d4aee85328d)

如果你安装了 [jieba.vim](https://github.com/kkew3/jieba.vim)，你可以对 `<c-w>` 进行增强。

```vim
function RimeKeymapRemap()
  lnoremap <silent><expr> <c-w> im#state#composing() ?
        \ "\<cmd>call im#key(g:RIME_KEYCODE.BackSpace, 0)\<CR>" :
        \ im#replace#can_restore() ? "\<cmd>call im#replace#ctrl_w()\<cr>" :
        \ "<Plug>(Jieba_C_w)"
endfunction

function RimeKeymapClear()

endfunction

augroup RimeGroup
  autocmd!
  autocmd User RimeKeymapSetup call RimeKeymapRemap()
  autocmd User RimeKeymapClear call RimeKeymapClear()
augroup END

```

### 定制中英切换与方案选单

#### 方案选单

`im#keymap#toggle_scheme()` 向 Rime 发送 `` Ctrl+` ``，打开内置的「方案选单」，与系统输入法行为一致：

- 选单内容来自用户数据目录里 `default.custom.yaml` 的 `schema_list`，以及 switcher 中的开关项（简繁、中英标点、emoji 等）
- 切换后状态栏立即刷新

#### 中英切换

`im#keymap#toggle_ascii_mode()` 不带参数时模拟一次左 Shift 按下 + 释放，与系统输入法一致，组词时的处理方式由 rime 配置的 `ascii_composer/switch_key` 决定。

带参数时可指定「正在组词时切换」的处理风格：

| 参数                 | 组词时切换的行为                                         |
| -------------------- | -------------------------------------------------------- |
| `'commit_code'`      | 拼音字母原样上屏，再切换                                 |
| `'commit_text'`      | 有候选时上屏当前高亮候选词；无候选时原样上屏编码，再切换 |
| `'clear'`            | 丢弃当前组词内容，再切换                                 |
| `'inline_ascii'`     | 进入临时英文态：直接输出英文，本次上屏结束后自动切回中文 |
| `'set_ascii_mode'`   | 强制切到英文；正在组词时丢弃当前组词内容                 |
| `'unset_ascii_mode'` | 强制切回中文；已是英文态时为空操作                       |

> [!Note]
> 这些参数只影响「正在组词时」的切换；空闲时按下都只是单纯在中/英之间切换。

示例：

```vim
function RimeKeymapRemap()
  lnoremap <silent><expr> ;` im#keymap#toggle_scheme()
  lnoremap <nowait><expr> <c-;> im#keymap#toggle_ascii_mode()
  lnoremap <nowait><expr> ;1 im#keymap#toggle_ascii_mode('commit_code')
  lnoremap <nowait><expr> ;2 im#keymap#toggle_ascii_mode('commit_text')
  lnoremap <nowait><expr> ;3 im#keymap#toggle_ascii_mode('clear')
  lnoremap <nowait><expr> ;4 im#keymap#toggle_ascii_mode('inline_ascii')
  lnoremap <nowait><expr> ;5 im#keymap#toggle_ascii_mode('set_ascii_mode')
  lnoremap <nowait><expr> ;6 im#keymap#toggle_ascii_mode('unset_ascii_mode')
endfunction

function RimeKeymapClear()
  silent! lunmap ;`
  silent! lunmap <c-;>
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

### Replace Mode 替换模式

以下功能还处于实验性阶段。

![demo4](https://github.com/user-attachments/assets/f2fba3e1-d7dc-4b1c-bd5a-779b4e725a45)

开启后，Rime 可以在替换模式（`R` / `gR`）中工作：上屏内容从光标处开始**覆盖**而非插入，并支持像原生 Replace 一样还原。

```vim
" 设为 1：在 R/gR 替换模式下启用 Rime
let g:im_replace_mode = 1
```

`g:im_replace_mode` 默认为 `0`：替换模式下的按键不会被 Rime 拦截，完全回退到 Vim 原生行为，不弹候选窗。

设为 `1` 后，进入 `R` / `gR` 即开始替换会话，上屏内容以原生 Replace 的方式还原：

| 按键    | 功能                             |
| ------- | -------------------------------- |
| `<bs>`  | 还原上一步覆盖的字符             |
| `<c-w>` | 还原上一个空白分隔的词覆盖的字符 |
| `<c-u>` | 还原本会话内覆盖的全部字符       |

移动光标会放弃该会话的还原能力（对齐原生 Replace），之后从新位置继续覆盖。

- 重映射 `r`，支持半角和全角切换。

```vim
nnoremap r <Cmd>call im#keymap#r()<CR>
```

### Auto Pair 自动成对

> [!Tip]
> 替换模式下自动成对关闭

| 功能     | 按键         | 效果                       | 说明                                             |
| -------- | ------------ | -------------------------- | ------------------------------------------------ |
| 成对补全 | `(` `「` `"` | (\|)　「\|」　"\|"         | 输入开符自动补闭符并回移光标                     |
| 闭符跳出 | `)` `」` `"` | ()\|　「」\|　""\|         | 光标右侧已有相同闭符/引号则直接跳出，不重复插入  |
| 空对删除 | `<BS>`       | (\|) → 删除 → \|           | 在空对（开符紧邻闭符）内一次删除成对             |
| 只删开符 | `<s-bs>`     | (\|) → 删除 → \|)          | 在空对（开符紧邻闭符）内只删开符，保留闭符       |
| 手动跳过 | `<c-tab>`    | (\|) → 越过一个 → ()\|     | 跳过右侧一个闭符/引号（`im#pair#jump_any`）      |
| 手动连跳 | `<c-g>`      | (\|))) → 越过全部 → ()))\| | 跳过右侧连续一串闭符/引号（`im#pair#jump_many`） |

- 默认配对：`()` `[]` `{}` `<>` `"` `'` 与全角 `（）` `【】` `「」` `『』` `《》` `“”` `‘’`
- 半角标点直接上屏、全角标点经 Rime 上屏，两种情况都能正确处理成对
- 配置优先级：`b:im_pair_rules` > `g:im_pair_rules` > 默认值（仅 `im_pair_rules` 支持 `b:`，其余选项为全局 `g:`）
- 高亮黑名单：光标位于名单内的高亮组（如注释、字符串）时自动成对关闭，离开后恢复。**默认关闭**，未设置或为空列表时不生效：

```vim
" 自动成对开关（默认 0）
let g:im_pair_enabled = 0
" 切换自动成对
let g:im_toggle_pair_key = ';p'
" 配对规则列表，每条含 open/close 与 kind（'delim' 开闭不同符、'quote' 开=闭同符）
let g:im_pair_rules = [
      \ {'open': '(',  'close': ')',  'kind': 'delim'},
      \ {'open': '[',  'close': ']',  'kind': 'delim'},
      \ {'open': '{',  'close': '}',  'kind': 'delim'},
      \ {'open': '<',  'close': '>',  'kind': 'delim'},
      \ {'open': '（', 'close': '）', 'kind': 'delim'},
      \ {'open': '【', 'close': '】', 'kind': 'delim'},
      \ {'open': '「', 'close': '」', 'kind': 'delim'},
      \ {'open': '『', 'close': '』', 'kind': 'delim'},
      \ {'open': '《', 'close': '》', 'kind': 'delim'},
      \ {'open': "‘",  'close': "’",  'kind': 'delim'},
      \ {'open': "“",  'close': "”",  'kind': 'delim'},
      \ {'open': '"',  'close': '"',  'kind': 'quote'},
      \ {'open': "'",  'close': "'",  'kind': 'quote'},
      \ ]

" 或者
let g:im_pair_rules = im#pair#default_rules()

" 按 highlight 关闭自动成对，高亮组名为正则列表（大小写不敏感），命中即关闭自动成对（默认 []，即关闭）
let g:im_pair_blacklist_highlight = ['comment', 'doc', 'string']
" 按 filetype 关闭自动成对
let g:im_pair_blacklist_filetypes = ['vim']

" 以下配置仅在 neovim 中生效（需要 Treesitter 支持），默认 vim 中高亮使用的是正则匹配。
" 优先级为 `g:im_pair_blacklist_filetypes` > `g:im_pair_ts_config` > `g:im_pair_blacklist_highlight`
let g:im_pair_ts_check  = 0

" '*' 为全局通配，具体 filetype 会覆盖全局（显式定义为 [] 表示该 filetype 关闭检查）
let g:im_pair_ts_config = {
      \ '*':      ['comment', 'string'],
      \ 'lua':    ['comment', 'string'],
      \ 'python': ['comment', 'string'],
      \ }
```

或者修改默认按键映射

```vim
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

### 其他搭配插件

- [jieba.vim](https://github.com/kkew3/jieba.vim) — jieba 的 Vim/Nvim 按词跳转插件
- [pangu.vim](https://github.com/hotoo/pangu.vim) — 中文排版自动规范化的 Vim 插件
- [vim-easymotion-zh](https://github.com/zzhirong/vim-easymotion-zh) — 基于小鹤双拼让 EasyMotion 识别中文

## 致谢

- [ZFVimIM](https://github.com/ZSaberLv0/ZFVimIM) — vim 输入法 / Vim Input Method by pure vim script, support: user word, dynamic word priority, cloud db files
- [rime-ls](https://github.com/wlh320/rime-ls) — A language server that provides input method functionality using librime，通过 LSP 代码补全使用 Rime 输入法
- [rime.nvim](https://github.com/rimeinn/rime.nvim) — ㄓ rime for neovim
- [delimitMate](https://github.com/Raimondi/delimitMate) - Vim plugin, provides insert mode auto-completion for quotes, parens, brackets, etc.

## License

MIT
