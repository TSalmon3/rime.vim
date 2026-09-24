<p align="center">
  <img alt="Logo" src="./icon.png" height="200" />
  <p align="center">Rime input method support for Vim/Neovim</p>
  <p align="center">
    <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square"></a>
    <a href="https://GitHub.com/Naereen/StrapDown.js/graphs/commit-activity"><img alt="Maintenance" src="https://img.shields.io/badge/Maintained%3F-yes-green.svg?style=flat-square"></a>
    <a href="https://www.vim.org"><img alt="Vim" src="https://img.shields.io/badge/Vim-8.2+-green.svg?style=flat-square&logo=vim"></a>
    <a href="https://neovim.io"><img alt="NeoVim" src="https://img.shields.io/badge/NeoVim-0.4+-green.svg?style=flat-square&logo=neovim"></a>
  </p>
</p>

<p align="center">
  <a href="https://github.com/TSalmon3/rime.vim/blob/master/index.md">导航页</a>
  ·
  <a href="https://tsalmon3.github.io/rime.vim/">文档站 Website</a>
  ·
  <a href="https://github.com/TSalmon3/rime.vim/blob/master/README.md">中文说明</a>
  ·
  <a href="https://github.com/TSalmon3/rime.vim/blob/master/README.en.md">英文说明</a>
</p>

---

<details>
<summary><strong>FAQ</strong></summary>
<br>

- 是否会跟系统的 Rime 输入法产生冲突？

  ```answer
  会产生冲突。建议新建一个独立目录存放你的拼音方案，即你的「用户数据目录」，最好不要与系统输入法共用同一目录。
  ```

</details>

---

<details>
<summary><strong>CHANGELOG</strong></summary>
<br>

## v1.15.0

**Changed**

- `g:im_surround_add_line_key` -> `g:im_surround_add_linewise_key`。
- `g:im_surround_add_cur_line_key` -> `g:im_surround_add_cur_linewise_key`。
- `g:im_surround_change_line_key` -> `g:im_surround_change_linewise_key`。
- `g:im_surround_visual_line_key` -> `g:im_surround_visual_linewise_key`。
- `g:im_surround_insert_line_key` -> `g:im_surround_insert_linewise_key`。
- 旧名无别名保留；默认按键不变。

## v1.14.0

**Changed**

- `im#pair#should_bs_pair()` 更名为 `im#pair#should_bs()`，旧名无别名保留。

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
  - [定制中英切换与方案选单](#定制中英切换与方案选单)
  - [Replace Mode 替换模式](#replace-mode-替换模式)
  - [Motion 行内跳转](#motion-行内跳转)
  - [Auto Pair 自动成对](#auto-pair-自动成对)
  - [Context 自动切换](#context-自动切换)
  - [Typeset 自动排版](#typeset-自动排版)
  - [Surround 包围编辑](#surround-包围编辑)
  - [Extend 外部集成](#Extend-外部集成)
  - [Tmux 弹窗输入](#tmux-弹窗输入)
  - [其他搭配插件](#其他搭配插件)
- [致谢](#致谢)
- [License](#license)

## 简介

Rime（中州韵）输入法在 Vim / Neovim 中的集成方案，，同时支持 Vim（>= 8.2.1978）与 Neovim。

**用法**：进入插入模式后直接键入拼音，即可弹出候选词浮窗；用数字键或 `Up` / `Down` 选择候选，`Enter` / `Space` 上屏，`Esc` 取消本次输入。

![demo](https://github.com/user-attachments/assets/20978d66-c198-426f-97f1-0ba7322cf656)
![demo2](https://github.com/user-attachments/assets/820db16b-b76b-4b15-a5f4-a8a6a58306bd)

主要特性：

- 支持全拼、双拼、九宫格等输入方案
- 支持简繁、中英文标点、emoji 切换
- 候选词浮窗、下划线渲染、状态栏可显示当前输入状态
- 支持括号、引号等自动补全
- 支持中英文自动切换
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

构建出的 `rime-query` 可执行文件需能被找到（默认查找 `PATH`，也可通过 `g:im_rime_bin` 指定路径），否则 `:IMStart` 会失败。

> 以下命令中的仓库路径 `/path/to/rime.vim` 请替换为你的实际路径。

#### macOS

```bash
cd /path/to/rime.vim/cpp
mkdir -p build
brew install librime
clang++ -std=c++17 -I./3rd -I/opt/homebrew/include -L/opt/homebrew/lib -lstdc++ -lrime -o build/rime-query rime-query.cc
```

也可以使用 CMake（必要时修改 `CMakeLists.txt` 中的 librime include / lib 路径）：

```bash
cd /path/to/rime.vim/cpp
cmake -S . -B build
cmake --build build
```

---

#### Linux

需手动编译 librime，并分别指定其头文件 include 路径与动态库 lib 路径：

```bash
cd /path/to/rime.vim/cpp
clang++ -std=c++17 -I./3rd -I/path/to/librime/include -L/path/to/librime/lib -lstdc++ -lrime -o build/rime-query rime-query.cc
```

---

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

其中 `-lws2_32` 用于链接 Windows Sockets，是后端 TCP 监听所必需的；它是系统自带组件（System32），无需额外安装。

也可以使用 CMake（必要时修改 `CMakeLists.txt` 中的编译器与 librime include / lib 路径）：

```bash
cd /path/to/rime.vim/cpp
cmake -S . -B build -G "MinGW Makefiles"
cmake --build build
```

> [!note]
>
> 需要 `clang++` 与 `mingw32-make` 在 `PATH` 中

构建完成后，请把生成的 `rime-query` 加入 `PATH`。

---

#### 在编辑器内编译

配好 librime 路径后，也可以直接在 Vim 内完成编译，无需切换到终端：

```vim
let g:im_build_rime_include = '/opt/homebrew/include'
let g:im_build_rime_lib     = '/opt/homebrew/lib'
let g:im_build_compiler     = 'clang++'              " 可省略，默认值
let g:im_build_flags        = '-std=c++17 -O2 -Wall' " 可省略，默认值
```

Windows 下需要额外指定 `rime.dll` 路径：

```vim
let g:im_build_rime_dll     = 'D:/Library/librime/lib/rime.dll'
```

| 命令       | 说明                              |
| ---------- | --------------------------------- |
| `:IMCheck` | 自检：编译器/参数/路径/是否已编译 |
| `:IMBuild` | 后台异步编译                      |
| `:IMClean` | 清理编译结果                      |

流程：配置 → `:IMCheck` 验证 → `:IMBuild`。

## 配置

### 选项

> [!Tip]
> 以雾凇拼音（rime-ice）为例，如果你的系统中已安装了「鼠须管」或「小狼毫」，建议新建一个用户数据目录，避免产生冲突。

以下均为常用 `g:` 变量，可省略（使用默认值）。请在 vimrc 中、插件加载**之前**设置：

```vim
" rime-query 可执行文件路径（需在 PATH 中可找到）
let g:im_rime_bin                  = 'rime-query'
" 用户数据目录，即拼音方案的安装目录（$RIME_USER_DATA_DIR）
let g:im_user_data_dir             = '/path/to/rime'
" 共享数据目录（$RIME_SHARED_DATA_DIR）
let g:im_shared_data_dir           = '/usr/share/rime-data'
" 后端日志文件路径（$RIME_LOG）
let g:im_log_file                  = '~/.local/state/log/vim/rime.log'


" Unix：socket 文件路径，留空则默认为 ~/.cache/rime-query.sock
let g:im_unix_socket                = '~/.cache/rime-query.sock'
" Windows：TCP 回环地址，Vim 与 Neovim 共用同一通道，留空则默认为 127.0.0.1:18666
let g:im_tcp_addr                   = '127.0.0.1:18666'
" 最后一个客户端断开后，daemon 的空闲存活时长（毫秒，设为 0 表示常驻不退出）
let g:im_idle_exit_ms               = 60000
" 拉起 daemon 后，等待其就绪的超时时长（毫秒）
let g:im_connect_timeout_ms         = 30000


" 候选词弹窗的显示行数
let g:im_pumheight                 = 9
" 设为 1 可关闭下划线渲染
let g:im_underline_disable         = 0
" 设为 1 则不创建默认按键映射
let g:im_no_default_mappings       = 0
" 输入法切换快捷键
let g:im_toggle_key                = ';;'
" 中文/英文模式切换快捷键
let g:im_toggle_ascii_mode_key     = ';,'
" 中英文标点切换快捷键
let g:im_toggle_ascii_punct_key    = ';a'
" 简体/繁体切换快捷键
let g:im_toggle_traditional_key    = ';f'
" emoji 开关快捷键
let g:im_toggle_emoji_key          = ';e'
" :IMDeploy / :IMSync 等待后端响应的超时时长（毫秒）
let g:im_deploy_timeout            = 60000
" :IMSchemeDownload 方案下载的根目录
let g:im_scheme_dir                = '~/.local/share/rime-schemes'
" 状态栏输入法图标
let g:im_status_text               = 'ㄓ'
" 半角标点状态文本
let g:im_status_half_text          = '$'
" 全角标点状态文本
let g:im_status_full_text          = '¥'
" 简体状态文本
let g:im_status_simplified_text    = '简'
" 繁体状态文本
let g:im_status_traditional_text   = '繁'
" Rime 接管输入时的指示文本
let g:im_status_lmap_text          = 'L'
" 原生直通（未接管）时的指示文本
let g:im_status_imap_text          = 'I'
" 输入法断开连接时的状态文本
let g:im_status_disconnect         = '断'
" 标点初始状态（1 表示启动时为半角标点）
let g:im_option_ascii_punct        = 0
" 简繁初始状态（1 表示启动时为繁体）
let g:im_option_traditional        = 0
" 中英文初始状态（1 表示启动时为英文模式）
let g:im_option_ascii_mode         = 0
" emoji 初始状态（1 表示启动时开启）
let g:im_option_emoji              = 0


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


" 打开 :/? 命令行窗口并开启输出法
function! IMQSearch(cmdtype, zone) abort"{{{
  if getcmdwintype() !=# ''
    return
  endif
  if index(['/', '?', ':'], a:cmdtype) < 0
    return
  endif
  call im#start()
  call timer_start(0, {-> im#context#set(a:zone)})
  call feedkeys('q' . a:cmdtype . 'a', 'nt')
endfunction"}}}
nnoremap <silent> ;/ <Cmd>call IMQSearch('/', 'Chinese')<CR>
nnoremap <silent> ;? <Cmd>call IMQSearch('?', 'Chinese')<CR>
nnoremap <silent> ;: <Cmd>call IMQSearch(':', 'English')<CR>

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
> Windows 上 daemon 只监听单条 TCP 通道（Vim 与 Neovim 共用）。
> 如自定义了 `g:im_tcp_addr`，vimrc 与 Neovim 配置需保持一致。

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
与 `g:im_tcp_addr` 同义，二者同时设置时以 `g:im_tcp_addr` 优先）。

> 注意：在 Vim 中设置 `g:im_user_data_dir` / `g:im_shared_data_dir` / `g:im_log_file` 会覆盖同名环境变量。

## 使用

### 命令

| 命令                          | 说明                                                  |
| ----------------------------- | ----------------------------------------------------- |
| `:IMStart`                    | 启动/重启输入法（连接或拉起共享 `rime-query` daemon） |
| `:IMStop`                     | 停止输入法（只断开本编辑器的连接）                    |
| `:IMToggle`                   | 切换输入法开关                                        |
| `:IMDeploy`                   | 重新部署 Rime（改配置后生效）                         |
| `:IMSync`                     | 同步用户词库并重新部署                                |
| `:IMShutdown`                 | 关停共享 daemon（所有编辑器断开）                     |
| `:IMSchemeDownload <git-url>` | 下载输入方案到 `g:im_scheme_dir`                      |

#### 重新部署

修改用户数据目录中的配置（如 `default.custom.yaml` 的 `schema_list` / `page_size`）后，需执行 `:IMDeploy` 使改动生效。部署期间编辑器会短暂阻塞，超时时间可用 `g:im_deploy_timeout`（毫秒）调整。

#### 同步词库

`:IMSync` 会先将用户词库（`*.userdb/`）与 `sync/<installation_id>/*.userdb.txt` 备份双向合并，再重新部署，便于跨设备、跨平台同步个人词频。多台设备之间建议将 `installation.yaml` 中的 `installation_id` 设为同一值，否则合并可能失败。

#### 下载方案

`:IMSchemeDownload <git-url>` 会用 `git clone --depth 1` 把输入方案下载到 `g:im_scheme_dir`（默认 `~/.local/share/rime-schemes`），目录名取自 URL 最后一段（自动去掉 `.git` 后缀）。若目标目录已存在则跳过，不会覆盖。

### 按键映射

默认按键映射（可设 `g:im_no_default_mappings=1` 关闭，用对应的 `g:im_*_key` 修改）：

| 按键 | 模式                                 | 功能           |
| ---- | ------------------------------------ | -------------- |
| `;;` | normal / insert / command / terminal | 切换输入法开关 |
| `;,` | normal / insert                      | 切换中/英模式  |
| `;a` | normal / insert                      | 切换中英文标点 |
| `;f` | normal / insert                      | 切换简/繁体    |
| `;e` | normal / insert                      | 切换 emoji     |

组词过程中的按键和组合键基本兼容系统级输入法：

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

输入法启用后触发，可用于关闭其他插件的补全。

**`autocmd User RimeIMDisable {command}`**

输入法禁用后触发，可用于恢复其他插件的补全。

示例：

```vim
function! im#hooks#suppress_completion() abort
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

function! im#hooks#restore_completion() abort
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
  autocmd User RimeIMEnable  call im#hooks#suppress_completion()
  autocmd User RimeIMDisable call im#hooks#restore_completion()
augroup END
```

### 状态栏

最简单的方式是在你的 `'statusline'` 选项中加入 `%{IM_Status()}`。开启时显示
`[ㄓ]半|简`（图标 / 标点 / 简繁，文本均可用对应的 `g:im_status_*` 定制），关闭时返回空串。

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

### 定制中英切换与方案选单

#### 方案选单

`im#keymap#toggle_scheme()` 会向 Rime 发送 `` Ctrl+` ``，打开内置的「方案选单」，与系统输入法行为一致：

- 选单内容来自用户数据目录里 `default.custom.yaml` 的 `schema_list`，以及 switcher 中的开关项（简繁、中英标点、emoji 等）
- 切换后状态栏会立即刷新

#### 中英切换

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

> [!Note]
> 这些参数只影响「正在组词时」的切换行为；空闲状态下按下都只是单纯在中/英之间切换。

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

### Replace Mode 替换模式

> 以下功能还处于实验性阶段。

![demo4](https://github.com/user-attachments/assets/f2fba3e1-d7dc-4b1c-bd5a-779b4e725a45)

开启该功能后，Rime 可以在替换模式（`R` / `gR`）下工作：上屏内容将从光标处**覆盖**原有字符（而非插入），且支持像原生 Replace 一样撤销还原。

```vim
" 设为 1：在 R/gR 替换模式下启用 Rime
let g:im_replace_mode = 1
```

`g:im_replace_mode` 默认值为 `0`，此时替换模式下的按键不会被 Rime 拦截，完全遵循 Vim 原生行为，也不会弹出候选窗口。

设为 `1` 后，进入 `R` / `gR` 即开启一个替换会话，期间上屏的内容可按原生 Replace 的方式撤销还原：

| 按键    | 功能                             |
| ------- | -------------------------------- |
| `<bs>`  | 撤销上一步覆盖的字符             |
| `<c-w>` | 撤销上一个空格分隔词所覆盖的字符 |
| `<c-u>` | 撤销本次会话中覆盖的全部字符     |

移动光标会终止当前会话的撤销能力（与原生 Replace 行为一致），此后将从新位置重新开始覆盖。

- 重新映射 `r`，以支持半角/全角切换：

```vim
nnoremap r <Cmd>call im#keymap#r()<CR>
```

### Motion 行内跳转

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

#### 配置

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

#### 快捷键

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

#### 高亮

```vim
highlight link ImMotionShade Grey
highlight link ImMotionTarget Search
```

### Auto Pair 自动成对

> [!Tip]
> 替换模式下会自动关闭成对功能

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

#### 配置

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

#### `g:im_pair_config`

按 `filetype` 暂停自动成对功能。键名可为具体 `filetype`，也可用 `*` 表示全局默认；命中具体 `filetype` 时整体覆盖 `*` 对应配置，两者不合并。

字段说明：

* `disabled`（`Number`）：为 `1` 时该 `filetype` 完全停用
* `syntax`（`List`）：高亮组命中即暂停
* `ts`（`List`）：TS 节点命中即暂停（仅 Neovim）

> [!Tip]
> * `syntax` / `ts` 命中时，仅暂停**改字类动作**（自动补全、成对删除、回车 / 空格展开），**跳出动作不受影响**：光标右侧已有闭符时仍可自动跳出，`im#pair#jump_any()` / `im#pair#jump_many()` 照常可用（例如字符串 `"foo|"` 处按 `"` 会直接跳到引号外）
> * 只有 `disabled: 1` 才会完全停用（含跳出动作），且此时会忽略同条目下的 `syntax` / `ts` 配置
> * `ts` 与 `syntax` 为“或”关系，命中任一即暂停；两者同时配置时优先判定 `ts`；两者均为空时不生效；匹配均不区分大小写

#### `g:im_pair_rules`

`with_pair` / `with_move` / `with_del` / `with_cr` 均为“门控函数”：返回 `true` 时放行对应动作，返回 `false` 时拦截；传入列表时按 AND 求值（全部为真才放行）。

参数说明：

* `open`（`String`）：开符
* `close`（`String`）：闭符
* `kind`（`String`）：`matchpair` 表示开闭符不同，`quote` 表示开闭符相同
* `with_pair`（`Funcref(ctx) -> Bool` 或其列表）：成对补全门控
* `with_move`（`Funcref(ctx) -> Bool` 或其列表）：闭符跳出门控
* `with_del`（`Funcref(ctx) -> Bool` 或其列表）：空对删除门控
* `with_cr`（`Funcref(ctx) -> Bool` 或其列表）：回车展开门控

其中 `ctx` 为 `Dict`，键值如下：

* `before`(`String`）：光标左侧的当前行文本片段
* `after`(`String`）：光标右侧的当前行文本片段
* `line`（`String`）：当前整行
* `col`（`Number`）：字节列号，即 `col('.')`
* `filetype`（`String`）：即 `&filetype`，可能为空

> [!Tip]
> 优先级：`b:im_pair_rules` > `g:im_pair_rules` > 默认值

#### 内置函数一览

以下函数均返回 `Funcref(ctx) -> Bool`，用于 `with_pair` / `with_move` / `with_del` / `with_cr`。

**恒定结果：**

* `im#pair#cond#always()`：恒为真，始终放行
* `im#pair#cond#done()`：恒为真，与 `always()` 等价
* `im#pair#cond#never()`：恒为假，始终拦截
* `im#pair#cond#none()`：恒为假，与 `never()` 等价

**基于光标前后文本：**

* `im#pair#cond#before_text(t)`：`before` 以字符串 `t` 结尾时放行
* `im#pair#cond#not_before_text(t)`：上一条取反
* `im#pair#cond#before_regex(p)`：`before` 匹配 Vim 正则 `p` 时放行（自动补 `$` 锚尾）
* `im#pair#cond#not_before_regex(p)`：上一条取反
* `im#pair#cond#after_text(t)`：`after` 以字符串 `t` 开头时放行
* `im#pair#cond#not_after_text(t)`：上一条取反
* `im#pair#cond#after_regex(p)`：`after` 匹配 Vim 正则 `p` 时放行（自动补 `^` 锚首）
* `im#pair#cond#not_after_regex(p)`：上一条取反

**基于语法上下文：**

* `im#pair#cond#is_inside_quote()`：光标处于未转义引号内时放行
* `im#pair#cond#not_inside_quote()`：上一条取反
* `im#pair#cond#is_vim_comment()`：光标位于 vim 文件的注释行行首（该行仅有空白）时放行
* `im#pair#cond#not_vim_comment()`：上一条取反

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

#### 按键映射

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
  lnoremap <silent><expr> <bs> im#state#composing() ?
        \ "\<cmd>call im#key(g:RIME_KEYCODE.BackSpace, 0)\<CR>" :
        \ im#replace#can_restore() ? "\<cmd>call im#replace#bs()\<cr>" :
        \ im#pair#should_bs() ? im#pair#bs() : "\<bs>"

  lnoremap <silent><expr> <s-bs> im#state#composing() ?
        \ "\<cmd>call im#key(g:RIME_KEYCODE.BackSpace, g:RIME_MASK.Shift)\<CR>" :
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
  lnoremap <silent><expr> <cr> im#state#composing() ?
          \ "\<cmd>call im#key(g:RIME_KEYCODE.Return, 0)\<cr>"
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
  lnoremap <silent><expr> <space> im#state#composing() ?
        \ "\<cmd>call im#key(g:RIME_KEYCODE.Space, 0)\<CR>" : im#pair#space()
endfunction

augroup RimeGroup
  autocmd!
  autocmd User RimeKeymapSetup call RimeKeymapRemap()
  autocmd User RimePairImapSetup call RimePairImapRemap()
  autocmd User RimePairImapRestore call RimePairImapRestore()
augroup END


```

#### 事件

| 事件                  | 用途                                     |
| --------------------- | ---------------------------------------- |
| `RimePairImapSetup`   | 拦截：接管当前文件的退格 / 回车 / 空格键 |
| `RimePairImapRestore` | 还原：离开时恢复现场                     |

#### 进阶使用案例

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

### Context 自动切换

根据光标所在的高亮（语法作用域）自动切换【Rime 接管】与【原生直通】模式。

> [!note]
>
> - 仅在光标跨越高亮区域边界时才会触发切换判断
> - 进入插入模式时强制校准一次；离开插入模式后状态复位；组词过程中不会切换
> - 插入模式下用 `;;` 重启输入法时，同样会强制校准一次

#### 配置

```vim
" 上下文自动切换总开关（默认关闭）
let g:im_context_enabled = 1

" '*' 为全局默认规则，具体 filetype 的配置优先级更高
let g:im_context_config = {
      \ '*':        {'mode': 'blacklist'},
      \ 'vim':      {'mode': 'whitelist', 'ts': ['comment', 'string'], 'syntax': ['comment', 'string']},
      \ 'markdown': {'mode': 'blacklist', 'syntax': ['math', 'code']},
      \ }
```

- `mode` 为 `whitelist` 时，仅在列出的高亮区域内接管为 Rime，其余区域保持直通；为 `blacklist` 时反之。
- `ts` 对应 treesitter capture 名称。
- `syntax` 对应 vim syntax 高亮组名称。
- `ts` 与 `syntax` 之间为「或」的关系，命中任一即生效；两者同时配置时 `ts` 优先级更高。

#### 事件

状态变化时会触发以下 `autocmd`，可用于联动第三方插件（如补全、AI 续写等）：

| 事件                 | 触发时机                                          |
| -------------------- | ------------------------------------------------- |
| `RimeContextChinese` | 进入【Rime 接管】模式时触发，常用于关闭第三方补全 |
| `RimeContextEnglish` | 回到【原生直通】模式时触发，常用于恢复第三方补全  |
| `RimeContextChanged` | 接管状态发生变化时触发（不区分方向）              |

```vim
function! im#hooks#suppress_completion() abort
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

function! im#hooks#restore_completion() abort
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
  autocmd User RimeContextChinese  call im#hooks#suppress_completion()
  autocmd User RimeContextEnglish call im#hooks#restore_completion()
augroup END
```

#### 快捷键

手动切换【Rime 接管】与【原生直通】模式：

```vim
inoremap <silent> ;u <cmd>call im#context#set('chinese')<cr>
inoremap <silent> ;n <cmd>call im#context#set('english')<cr>
inoremap <silent> <c-;> <cmd>im#context#toggle()<cr>
```

开关整个自动切换功能：

```vim
nnoremap <silent> ;c <cmd>call im#context#auto_toggle()<cr>
inoremap <silent> ;c <cmd>call im#context#auto_toggle()<cr>
```

### Typeset 自动排版

遵循 [中文文案排版指北](https://github.com/sparanoid/chinese-copywriting-guidelines)，自动规范中英文混排文本：中英文、数字之间自动补空格，全角 / 半角标点与字母数字自动归一，清理零宽字符与行尾空白，合并连续重复的标点符号。

* **触发方式**：
  - 手动执行 `:IMTypeset`
  - 离开插入模式时自动触发（受 `g:im_typeset_insert_leave` 控制）
  - 回车换行时格式化上一行（映射 `<Plug>(im-typeset-line)`）

> [!Tip]
> 本插件仅提供轻量、启发式的行内排版，不保证高精度结果；如需高精度排版推荐使用 [autocorrect](https://github.com/huacnlee/autocorrect)。

#### 配置

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

#### 命令

| 命令                | 说明             |
| ------------------- | ---------------- |
| `:IMTypeset`        | 格式化当前行     |
| `:{range}IMTypeset` | 格式化指定行范围 |

#### 按键映射

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

### Surround 包围编辑

为选区、文本对象或整行**添加、删除、替换**成对分隔符（括号、引号、HTML 标签、函数调用等），并额外支持全角符号。

默认按键映射（均可用对应的 `g:im_surround_*_key` 定制）：

| 按键                        | 模式   | 说明                               |
| --------------------------- | ------ | ---------------------------------- |
| `[count]ys{motion}{char}`   | normal | 为 motion 选中的内容添加分隔符     |
| `[count]yS{motion}{char}`   | normal | 同上，但分隔符独占首尾新行         |
| `[count]yss` / `[count]ySS` | normal | 为整行添加分隔符（`ySS` 独占新行） |
| `[count]ds{char}`           | normal | 删除光标处最近的分隔符             |
| `[count]cs{old}{new}`       | normal | 将旧分隔符替换为新分隔符           |
| `[count]cS{old}{new}`       | normal | 同上，新分隔符独占首尾新行         |
| `S` / `gS`                  | visual | 为选区添加分隔符（`gS` 独占新行）  |
| `<c-g>s` / `<c-g>S`         | insert | 插入一对分隔符并将光标置于中间     |

常见用法示例（`*` 为光标位置）：

| 旧文本                       | 按键     | 新文本                 |
| :--------------------------- | :------- | :--------------------- |
| `surr*ound_words`            | `ysiw)`  | `(surr*ound_words)`    |
| `surr*ound_words`            | `ysiw(`  | `( surr*ound_words )`  |
| `*make strings`              | `ys$"`   | `"*make strings"`      |
| `[delete ar*ound me!]`       | `ds]`    | `delete ar*ound me!`   |
| `remove \<b>HTML t*ags\</b>` | `dst`    | `remove HTML t*ags`    |
| `'change quot*es'`           | `cs'"`   | `"change quot*es"`     |
| `delete(functi*on calls)`    | `dsf`    | `functi*on calls`      |
| `surr*ound_words`            | `2ysiw)` | `((surr*ound_words))`  |
| `((delete ar*ound me!))`     | `2ds)`   | `(delete ar*ound me!)` |

**前置计数**：在 `ys / yss / ds / cs` 前加数字。`ys` 系一次套多层，如 `2ysiw)` 得到 `((word))`；`ds / cs` 系操作由内向外第 N 层，如嵌套括号内 `2ds)` 删外层、`2cs)]` 换外层。

**点重复**：`ys / yss / ds / cs` 做完后按 `.` 可在别处重复上一次操作，不用重输符号，如 `ysiw)` 后移动光标按 `.` 直接套同种括号。`S / gS` 可视包裹和 `insert` 的 `<C-g>s / <C-g>S` 不支持 `.`。

#### 配置

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

#### g:im_surround_surrounds

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

#### g:im_surround_aliases

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

#### 内置函数一览

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

#### 进阶使用案例

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

### Extend 外部集成

如果你安装了 [ultisnips](https://github.com/SirVer/ultisnips) 和 [bullets.vim](https://github.com/bullets-vim/bullets.vim)，可以这样配置：

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

如果你安装了 [jieba.vim](https://github.com/kkew3/jieba.vim)，还可以对 `<c-w>` 进行增强：

```vim
function RimeKeymapRemap()
  lnoremap <silent><expr> <c-w> im#state#composing() ?
        \ "\<cmd>call im#key(g:RIME_KEYCODE.BackSpace, g:RIME_MASK.Shift)\<CR>" :
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

### Tmux 弹窗输入

在 tmux 中通过 `display-popup` 弹窗使用 Rime 输入法，复用同一个 `rime-query` daemon。

![tmux](https://github.com/user-attachments/assets/fb715949-57d0-4337-870a-5273e3bc1d6c)

#### 要求

- tmux >= 3.3
- Python 3
- rime-query 可执行文件（见 [编译后端](#编译后端)）

#### 安装

使用 [TPM](https://github.com/tmux-plugins/tpm)：

```tmux
set -g @plugin 'TSalmon3/rime.vim'
```

或手动在 `.tmux.conf` 中添加：

```tmux
run-shell '/path/to/rime.vim/rime.tmux'
```

安装后按 `prefix + ;` 即可弹出 Rime 输入窗口。

#### 按键

| 按键                | 功能                |
| ------------------- | ------------------- |
| `prefix + ;`        | 打开 / 关闭弹窗     |
| `Space`             | 选择候选            |
| `Enter`             | 拼音上屏            |
| `Number` (1-5)      | 选择对应候选        |
| `Up` / `Down`       | 上 / 下一个候选     |
| `PageUp`/`PageDown` | 上 / 下一页         |
| `Tab` / `S-Tab`     | 下 / 上一个音节     |
| `Backspace`         | 删除一个字符        |
| `Ctrl-u`            | 清空拼音            |
| `Ctrl-w`            | 删除一个音节        |
| `Ctrl-d`            | 删除自造词          |
| `Ctrl-a` / `Ctrl-e` | 光标到拼音首 / 尾   |
| `Ctrl+p`            | 切换半角/全角标点   |
| `Ctrl+f`            | 切换简体/繁体       |
| `Esc`               | 取消组合 / 关闭弹窗 |
| `Ctrl-c`            | 退出弹窗            |

#### 配置

通过 tmux 选项设置（在 `.tmux.conf` 中 `run-shell` 之前）：

| 选项                       | 默认值       | 说明                           |
| -------------------------- | ------------ | ------------------------------ |
| `@rime_key`                | `;`          | 绑定的前缀键                   |
| `@rime_bin`                | `rime-query` | `rime-query` 可执行文件路径    |
| `@rime_socket`             | 空           | Unix socket 路径，留空自动检测 |
| `@rime_popup`              | 空           | 自定义 `display-popup` 参数    |
| `@rime_option_ascii_punct` | 空           | 初始标点状态（0=全角，1=半角） |
| `@rime_option_traditional` | 空           | 初始简繁状态（0=简体，1=繁体） |

```tmux
set -g @rime_key ";"
set -g @rime_bin "rime-query"
```

自定义 `@rime_popup` 会覆盖默认的弹窗尺寸与位置：

```tmux
set -g @rime_popup "-w80% -h10 -xC -yC -E -T ㄓ"
```

设置初始状态：

```tmux
set -g @rime_option_ascii_punct 1      # 初始半角标点
set -g @rime_option_traditional 0      # 初始简体
```

#### 环境变量

tmux 弹窗会自动从全局环境导入以下三个变量：

```
RIME_USER_DATA_DIR   # 用户数据目录
RIME_SHARED_DATA_DIR # 共享数据目录
RIME_LOG             # 后端日志路径
RIME_TMUX_LOG        # tmux 前端日志路径
```

也可以在 `.tmux.conf` 中通过 `set-environment -g` 设置：

```
set-environment -g RIME_USER_DATA_DIR "/path/to/rime"
set-environment -g RIME_SHARED_DATA_DIR "/usr/share/rime-data"
set-environment -g RIME_LOG "$HOME/.local/state/log/vim/rime.log"
set-environment -g RIME_TMUX_LOG "$HOME/.local/state/log/tmux/rime.log"
```

### 其他搭配插件

- [jieba.vim](https://github.com/kkew3/jieba.vim) — jieba 的 Vim/Nvim 按词跳转插件
- [pangu.vim](https://github.com/hotoo/pangu.vim) — 中文排版自动规范化的 Vim 插件

## 致谢

- [ZFVimIM](https://github.com/ZSaberLv0/ZFVimIM) — vim 输入法 / Vim Input Method by pure vim script, support: user word, dynamic word priority, cloud db files
- [rime-ls](https://github.com/wlh320/rime-ls) — A language server that provides input method functionality using librime，通过 LSP 代码补全使用 Rime 输入法
- [rime.nvim](https://github.com/rimeinn/rime.nvim) — ㄓ rime for neovim
- [clever-f.vim](https://github.com/rhysd/clever-f.vim) - Extended f, F, t and T key mappings for Vim.
- [vim-easymotion-zh](https://github.com/zzhirong/vim-easymotion-zh) — 基于小鹤双拼让 EasyMotion 识别中文
- [nvim-autopair](https://github.com/windwp/nvim-autopairs) - autopairs for neovim written in lua
- [delimitMate](https://github.com/Raimondi/delimitMate) - Vim plugin, provides insert mode auto-completion for quotes, parens, brackets, etc.
- [nvim-surround](https://github.com/kylechui/nvim-surround) - Add/change/delete surrounding delimiter pairs with ease. Written with ❤️ in Lua.
- [vim-surround](https://github.com/tpope/vim-surround) - surround.vim: Delete/change/add parentheses/quotes/XML-tags/much more with ease
- [vim-sandwich](https://github.com/machakann/vim-sandwich) - Set of operators and textobjects to search/select/edit sandwiched texts.
- [pangu.vim](https://github.com/hotoo/pangu.vim) — 中文排版自动规范化的 Vim 插件
- [autocorrect](https://github.com/huacnlee/autocorrect) - A linter and formatter to help you to improve copywriting, correct spaces, words, and punctuations between CJK (Chinese, Japanese, Korean).
- [tmux-rime](https://github.com/rimeinn/tmux-rime) - ㄓ rime for tmux

## License

MIT
