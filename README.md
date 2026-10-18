> [!WARNING]
> **v2.0.0** 含后端协议变更与 API breaking。**rime-query** 需重新编译。API 变更见 **CHANGELOG**。回退稳定版本 Tag 为 **v1.24.0**

<p align="center">
  <img alt="Logo" src="./icon.png" height="200" />
  <p align="center">Rime input method support for Vim/Neovim</p>
  <p align="center">
    <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square"></a>
    <a href="https://www.vim.org"><img alt="Vim" src="https://img.shields.io/badge/Vim-8.2+-green.svg?style=flat-square&logo=vim"></a>
    <a href="https://neovim.io"><img alt="NeoVim" src="https://img.shields.io/badge/NeoVim-0.10+-green.svg?style=flat-square&logo=neovim"></a>
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

## V2.0.0

**Changed**

| 旧 API                       | 新 API                              |
| ---------------------------- | ----------------------------------- |
| `im#keymap#r()`              | `im#replace#r()`                    |
| `im#key(keycode, mask, ...)` | `im#engine#key(keycode, mask, ...)` |

| 移除                           |
| ------------------------------ |
| `g:im_toggle_traditional_key`  |
| `g:im_toggle_emoji_key`        |
| `g:im_status_simplified_text`  |
| `g:im_status_traditional_text` |
| `g:im_option_traditional`      |
| `g:im_option_emoji`            |

- 不再支持快捷键简繁体切换
- 不再支持快捷键 emoji 切换
- 内置 `im#status` 不再显示繁体切换部分

旧名无别名保留。

## v1.15.0

**Changed**

| 旧 API                           | 新 API                               |
| -------------------------------- | ------------------------------------ |
| `g:im_surround_add_line_key`     | `g:im_surround_add_linewise_key`     |
| `g:im_surround_add_cur_line_key` | `g:im_surround_add_cur_linewise_key` |
| `g:im_surround_change_line_key`  | `g:im_surround_change_linewise_key`  |
| `g:im_surround_visual_line_key`  | `g:im_surround_visual_linewise_key`  |
| `g:im_surround_insert_line_key`  | `g:im_surround_insert_linewise_key`  |

旧名无别名保留；默认按键不变。

## v1.14.0

**Changed**

| 旧 API                     | 新 API                |
| -------------------------- | --------------------- |
| `im#pair#should_bs_pair()` | `im#pair#should_bs()` |

旧名无别名保留。

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
- [高级主题](#高级主题)
  - [定制方案](#定制方案)
  - [定制快捷键](#定制快捷键)
  - [定制状态栏](#定制状态栏)
  - [Replace 替换模式](#replace-替换模式)
  - [Motion 行内跳转](#motion-行内跳转)
  - [Jump 全屏跳转](#jump-全屏跳转)
  - [AutoPair 自动成对](#autopair-自动成对)
  - [Snippet 片段补全](#snippet-片段补全)
  - [Context 自动切换](#context-自动切换)
  - [Typeset 自动排版](#typeset-自动排版)
  - [Surround 包围编辑](#surround-包围编辑)
  - [Tips 小技巧](#tips-小技巧)
  - [其他搭配插件](#其他搭配插件)
  - [Tmux 弹窗输入](#tmux-弹窗输入)
- [附录](#附录)
- [致谢](#致谢)
- [License](#license)

## 简介

Rime（中州韵）输入法在 Vim / Neovim 中的集成方案，同时支持 Vim（>= 8.2.1978）与 Neovim。

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

- Vim >= 8.2.1978 或 Neovim >= 0.10
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
" 在 Vim 启动完成（VimEnter）后自动拉起输入法 daemon 进程
let g:im_daemon_autostart           = 1


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
" :IMDeploy / :IMSync 等待后端响应的超时时长（毫秒）
let g:im_deploy_timeout            = 60000
" :IMSchemeDownload 方案下载的根目录
let g:im_scheme_dir                = '~/.local/share/rime-schemes'
" 状态栏输入法图标
let g:im_status_text               = 'ㄓ'
" 中文模式状态文本
let g:im_status_chinese_text       = '中'
" 英文模式状态文本
let g:im_status_english_text       = 'A'
" 半角标点状态文本
let g:im_status_half_text          = '$'
" 全角标点状态文本
let g:im_status_full_text          = '¥'
" Rime 接管输入时的指示文本
let g:im_status_lmap_text          = 'L'
" 原生直通（未接管）时的指示文本
let g:im_status_imap_text          = 'I'
" 输入法断开连接时的状态文本
let g:im_status_disconnect         = '断'
" 标点初始状态（1 表示启动时为半角标点）
let g:im_option_ascii_punct        = 0
" 中英文初始状态（1 表示启动时为英文模式）
let g:im_option_ascii_mode         = 0


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

插件通过四个环境变量获取数据目录、日志路径与调试开关，两种设置方式任选其一：

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

排查问题时可设 `RIME_QUERY_DEBUG=1` 开启后端 debug 日志（默认只记 info，免每键磁盘 flush 拖慢打字；
改完需 `:IMShutdown` 后重启 daemon 才生效）：

```sh
export RIME_QUERY_DEBUG=1
```

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

组词过程中的按键和组合键基本兼容系统级输入法：

| 按键         | 功能               |
| ------------ | ------------------ |
| `<cr>`       | 拼音上屏           |
| `<space>`    | 选择               |
| `<left>`     | 光标左移           |
| `<right>`    | 光标右移           |
| `<c-b>`      | 光标左移           |
| `<c-f>`      | 光标右移           |
| `<up>`       | 上一个候选         |
| `<down>`     | 下一个候选         |
| `<c-k>`      | 上一个候选         |
| `<c-j>`      | 下一个候选         |
| `<c-p>`      | 上一个候选         |
| `<c-n>`      | 下一个候选         |
| `<pageup>`   | 上一页             |
| `<pagedown>` | 下一页             |
| `-`          | 上一页             |
| `=`          | 下一页             |
| `<bs>`       | 删除一个字符       |
| `<s-bs>`     | 删除一个音节       |
| `<c-h>`      | 删除左边字符       |
| `<c-d>`      | 删除右边字符       |
| `<tab>`      | 下一个音节结尾     |
| `<s-tab>`    | 下一个音节开头     |
| `<c-u>`      | 清空拼音           |
| `<esc>`      | 清空拼音           |
| `<c-w>`      | 删除一个音节       |
| `<c-l>`      | 删除自造词         |
| `<c-a>`      | 光标移动到拼音开头 |
| `<c-e>`      | 光标移动到拼音结尾 |

如果你不喜欢内置的 `<esc>` 的行为，可以采用以下方式取消映射。

```vim
function RimeKeymapRemap()
  lnoremap <silent><buffer> <esc> <esc>
endfunction

function RimeKeymapClear()
endfunction

augroup RimeGroup
  autocmd!
  autocmd User RimeKeymapSetup call RimeKeymapRemap()
  autocmd User RimeKeymapClear call RimeKeymapClear()
augroup END
```

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

## 高级主题

### 定制方案

推荐阅读：

- [YAML 入门教程](https://www.runoob.com/w3cnote/yaml-intro.html)
- [Rime 设计逻辑与配置思路](https://amzxyz.github.io/rime-wanxiang/doc/Rime%E8%AE%BE%E8%AE%A1%E9%80%BB%E8%BE%91%E4%B8%8E%E9%85%8D%E7%BD%AE%E5%93%B2%E5%AD%A6.html)
- [Rime 配置：雾凇拼音](https://dvel.me/posts/rime-ice)

#### 雾凇 rime-ice 配置示例

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
  # 1}}}
```

---

### 定制快捷键

定制映射主要用到两个 API:

- `im#state#composing()`: 判断当前是否处于一次尚未上屏的组词过程中。在 `<expr>` 映射里可用它区分"组词中"和"空闲"两种状态，按需返回不同的行为。
- `im#engine#key(keycode, mask[, fallback])`: 发送按键给 Rime：
  - `keycode`：键码，取 `g:RIME_KEYCODE.*`；
  - `mask`：修饰键掩码，取 `g:RIME_MASK.*`，无修饰键时填 `0`；
  - `fallback`（可选）：Rime 拒收该键时的回退输入，缺省情况下内部会根据键码和修饰码进行反推。

> [!Note]
> `fallback` 基本只有**符号键**在半角情况下才会走这一分支，所以绝大多数情况下基本不会用到这个参数。

```vim
lnoremap <buffer><expr> <xxx> im#state#composing() ?
      \ "\<cmd>call im#engine#key(g:RIME_KEYCODE.Xxx, 0)\<cr>" : "\<xxx>"
```

键码与修饰键常量 `g:RIME_KEYCODE` / `g:RIME_MASK` 见[附录](#附录)。

定制方式是在内置映射建立之后覆盖它。

- `User RimeKeymapSetup`: 在内置映射建立后触发。在回调里用相同的 LHS 再次 `lnoremap` ，即可覆盖内置映射。
- `User RimeKeymapClear`: 在映射清除后触发。在回调里用 `lunmap` 拆除自己添加的映射。

通用骨架：

```vim
function RimeKeymapRemap()
  lnoremap <silent><buffer><expr> <c-h> im#state#composing() ?
        \ "\<cmd>call im#engine#key(g:RIME_KEYCODE.Left, 0)\<cr>" : "\<left>"
  lnoremap <silent><buffer><expr> <c-l> im#state#composing() ?
        \ "\<cmd>call im#engine#key(g:RIME_KEYCODE.Right, 0)\<cr>" : "\<right>"
  lnoremap <silent><buffer><expr> <c-j> im#state#composing() ?
        \ "\<cmd>call im#engine#key(g:RIME_KEYCODE.Down, 0)\<cr>" : "\<down>"
  lnoremap <silent><buffer><expr> <c-k> im#state#composing() ?
        \ "\<cmd>call im#engine#key(g:RIME_KEYCODE.Up, 0)\<cr>" : "\<up>"
  ...
  lnoremap <buffer><expr> <xxx> ...
endfunction

function RimeKeymapClear()
  silent! lunmap <buffer> <xxx>
  ...
endfunction

augroup RimeGroup
  autocmd!
  autocmd User RimeKeymapSetup call RimeKeymapRemap()
  autocmd User RimeKeymapClear call RimeKeymapClear()
augroup END
```

#### 自定义编辑键

Emacs 风格

```vim
lnoremap <silent><buffer><expr> <c-a> im#state#composing() ?
      \ "\<cmd>call im#engine#key(g:RIME_KEYCODE.Home, 0)\<cr>" : "\<home>"
lnoremap <silent><buffer><expr> <c-e> im#state#composing() ?
      \ "\<cmd>call im#engine#key(g:RIME_KEYCODE.End, 0)\<cr>" : "\<end>"

lnoremap <silent><buffer><expr> <c-k> im#state#composing() ?
      \ "\<cmd>call im#engine#key(g:RIME_KEYCODE.Up, 0)\<cr>" : "\<up>"
lnoremap <silent><buffer><expr> <c-j> im#state#composing() ?
      \ "\<cmd>call im#engine#key(g:RIME_KEYCODE.Down, 0)\<cr>" : "\<down>"

lnoremap <silent><buffer><expr> <c-b> im#state#composing() ?
      \ "\<cmd>call im#engine#key(g:RIME_KEYCODE.Left, 0)\<cr>" : "\<left>"
lnoremap <silent><buffer><expr> <c-f> im#state#composing() ?
      \ "\<cmd>call im#engine#key(g:RIME_KEYCODE.Right, 0)\<cr>" : "\<right>"

lnoremap <silent><buffer><expr> <c-h> im#state#composing() ?
      \ "\<cmd>call im#engine#key(g:RIME_KEYCODE.BackSpace, 0)\<cr>" : "\<bs>"
lnoremap <silent><buffer><expr> <c-d> im#state#composing() ?
      \ "\<cmd>call im#engine#key(g:RIME_KEYCODE.Delete, 0)\<cr>" : "\<del>"

lnoremap <silent><buffer><expr> <c-l> im#state#composing() ?
      \ "\<cmd>call im#engine#key(g:RIME_KEYCODE.Delete, g:RIME_MASK.Shift)\<cr>" : "\<del>"
```

HJKL 风格

```vim
lnoremap <silent><buffer><expr> <c-h> im#state#composing() ?
      \ "\<cmd>call im#engine#key(g:RIME_KEYCODE.Left, 0)\<cr>" : "\<left>"
lnoremap <silent><buffer><expr> <c-j> im#state#composing() ?
      \ "\<cmd>call im#engine#key(g:RIME_KEYCODE.Down, 0)\<cr>" : "\<down>"
lnoremap <silent><buffer><expr> <c-k> im#state#composing() ?
      \ "\<cmd>call im#engine#key(g:RIME_KEYCODE.Up, 0)\<cr>" : "\<up>"
lnoremap <silent><buffer><expr> <c-l> im#state#composing() ?
      \ "\<cmd>call im#engine#key(g:RIME_KEYCODE.Right, 0)\<cr>" : "\<right>"

lnoremap <silent><buffer><expr> <c-a> im#state#composing() ?
      \ "\<cmd>call im#engine#key(g:RIME_KEYCODE.Home, 0)\<cr>" : "\<home>"
lnoremap <silent><buffer><expr> <c-e> im#state#composing() ?
      \ "\<cmd>call im#engine#key(g:RIME_KEYCODE.End, 0)\<cr>" : "\<end>"

lnoremap <silent><buffer><expr> <c-d> im#state#composing() ?
      \ "\<cmd>call im#engine#key(g:RIME_KEYCODE.Delete, g:RIME_MASK.Shift)\<cr>" : "\<c-d>"
```

#### 自定义退出键

上屏 `commit_code` 同时回到 `normal` 模式

```vim
function RimeKeymapRemap()
  lnoremap <silent><buffer> <esc> <esc>
endfunction

function RimeKeymapClear()
endfunction

augroup RimeGroup
  autocmd!
  autocmd User RimeKeymapSetup call RimeKeymapRemap()
  autocmd User RimeKeymapClear call RimeKeymapClear()
augroup END
```

清空编辑区

```vim
lnoremap <silent><expr> <esc> im#state#composing() ?
      \ "\<cmd>call im#engine#key(g:RIME_KEYCODE.Escape, 0)\<cr>" : "\<esc>"
```

清空编辑区，并回到 `normal` 模式

```vim
lnoremap <silent><expr> <esc> im#state#composing() ?
      \ "\<cmd>call im#engine#key(g:RIME_KEYCODE.Escape, 0)\<cr>\<esc>" : "\<esc>"
```

#### 方案选单

`im#keymap#toggle_scheme()` 会向 Rime 发送 `` Ctrl+` ``，打开内置的「方案选单」，与系统输入法行为一致：

- 选单内容来自用户数据目录里 `default.custom.yaml` 的 `schema_list`，以及 switcher 中的开关项（简繁、中英标点、emoji 等）
- 切换后状态栏会立即刷新

#### 中英切换

`im#keymap#toggle_ascii_mode()` 不带参数时等价于 `'commit_code'`（拼音字母原样上屏，再切换）；不再跟随 Rime 配置里的 `ascii_composer/switch_key`。

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
  lnoremap <buffer><silent><expr> ;` im#keymap#toggle_scheme()
  lnoremap <buffer><nowait><expr> ;: im#keymap#toggle_ascii_mode()
  lnoremap <buffer><nowait><expr> ;1 im#keymap#toggle_ascii_mode('commit_code')
  lnoremap <buffer><nowait><expr> ;2 im#keymap#toggle_ascii_mode('commit_text')
  lnoremap <buffer><nowait><expr> ;3 im#keymap#toggle_ascii_mode('clear')
  lnoremap <buffer><nowait><expr> ;4 im#keymap#toggle_ascii_mode('inline_ascii')
  lnoremap <buffer><nowait><expr> ;5 im#keymap#toggle_ascii_mode('set_ascii_mode')
  lnoremap <buffer><nowait><expr> ;6 im#keymap#toggle_ascii_mode('unset_ascii_mode')
endfunction

function RimeKeymapClear()
  silent! lunmap <buffer> ;`
  silent! lunmap <buffer> ;:
  silent! lunmap <buffer> ;1
  silent! lunmap <buffer> ;2
  silent! lunmap <buffer> ;3
  silent! lunmap <buffer> ;4
  silent! lunmap <buffer> ;5
  silent! lunmap <buffer> ;6
endfunction

augroup RimeGroup
  autocmd!
  autocmd User RimeKeymapSetup call RimeKeymapRemap()
  autocmd User RimeKeymapClear call RimeKeymapClear()
augroup END
```

---

### 定制状态栏

最简单的方式是在你的 `'statusline'` 选项中加入 `%{IM_Status()}`。开启时显示
`[ㄓ]中|半|L`（图标 / 中英 / 标点 / 接管，文本均可用对应的 `g:im_status_*` 定制），关闭时返回空串。

```vim
let statusline^=%{IM_Status()}
```

#### g:im_option_names

启动（以及每次 `:IMDeploy` / `:IMSync`）时批量取回的开关名单，存后端原名：

```vim
let g:im_option_names = ['ascii_mode', 'ascii_punct', 'traditionalization', 'emoji', 'full_shape']
```

上例即默认值（以 rime-ice 雾凇拼音为例）。换方案后若有新增开关（如 `chinese_english`），把它追加进名单即可。

具体的 option 名以各自 `schema.yaml` 的 `switches:` 列表为准（注：`switches:` 有 `- name: X` 与 `- options: [a, b, …]` 两种形态，这里只支持前者）。

```vim
function! IMToggleTraditional() abort
  let state = im#state#get()
  if !state.started
    return
  endif
  let value = im#rime#toggle_option('traditionalization')
  if value is v:null
    echohl WarningMsg
    echom 'failed to toggle traditionalization (backend not responding?)'
    echohl None
    return
  endif
  let state.switches['traditionalization'] = value ? 1 : 0
  redrawstatus
endfunction

nnoremap <silent> ;f <cmd>call IMToggleTraditional()<cr>
inoremap <silent> ;f <cmd>call IMToggleTraditional()<cr>

function! IMToggleEmoji() abort
  let state = im#state#get()
  if !state.started
    return
  endif
  let value = im#rime#toggle_option('emoji')
  if value is v:null
    echohl WarningMsg
    echom 'failed to toggle emoji (backend not responding?)'
    echohl None
    return
  endif
  let state.switches['emoji'] = value ? 1 : 0
  redrawstatus
endfunction

nnoremap <silent> ;e <cmd>call IMToggleEmoji()<cr>
inoremap <silent> ;e <cmd>call IMToggleEmoji()<cr>
```

#### 显示内容与定制变量

`IM_Status()` 的格式为 `[图标]中英|标点|接管`，各段文本可用变量定制（未设置则使用默认值）：

```vim
let g:im_status_text         = 'ㄓ' " 输入法图标
let g:im_status_chinese_text = '中' " 中文模式状态文本
let g:im_status_english_text = 'A'  " 英文模式状态文本
let g:im_status_half_text    = '$'  " 半角标点状态文本
let g:im_status_full_text    = '¥'  " 全角标点状态文本
let g:im_status_lmap_text    = 'L'  " Rime 接管输入时的指示文本
let g:im_status_imap_text    = 'I'  " 原生直通（未接管）时的指示文本
let g:im_status_disconnect   = '断' " 输入法断开连接时的状态文本
```

内置只显示中英与标点两段；如要加自己的段（如简繁、emoji 等），需自定义。开关量变化时状态栏会自动重刷：

```vim
function! IMCustomStatus() abort
  let state = im#state#get()
  let icon = get(g:, 'im_status_text', 'ㄓ')
  let icon_half = get(g:, 'im_status_half_text', '半')
  let icon_full = get(g:, 'im_status_full_text', '全')
  let icon_simplified = get(g:, 'im_status_simplified_text', '简')
  let icon_traditional = get(g:, 'im_status_traditional_text', '繁')
  let icon_chinese = get(g:, 'im_status_chinese_text', '中')
  let icon_english = get(g:, 'im_status_english_text', '英')
  let icon_lmap = get(g:, 'im_status_lmap_text', 'L')
  let icon_imap = get(g:, 'im_status_imap_text', 'I')
  let icon_disconnect = get(g:, 'im_status_disconnect', '断')

  let mode = get(state.switches, 'ascii_mode', 0) ? icon_english : icon_chinese
  let punct = get(state.switches, 'ascii_punct', 0) ? icon_half : icon_full
  let trad = get(state.switches,  'traditionalization', 0) ? icon_traditional : icon_simplified
  let lang = &iminsert ? icon_lmap : icon_imap
  let connect = state.ready ? "" : icon_disconnect
  return state.started ? connect . "[" . icon . "]" . mode . '|' . punct . '|' . trad . '|' . lang : ''
endfunction

let &statusline ..= '%{IMCustomStatus()}'
```

#### 事件

| 事件             | 用途              |
| ---------------- | ----------------- |
| `RimeOptionInit` | 用于初始化 Option |

```vim
function! IMOptionInit() abort
  call im#rime#set_option('emoji', 0)
  call im#rime#set_option('traditionalization', 0)
endfunction

augroup RimeGroup
  autocmd!
  autocmd User RimeOptionInit call IMOptionInit()
augroup END
```

---

### Replace 替换模式

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
nnoremap r <Cmd>call im#replace#r()<CR>
```

---

### Motion 行内跳转

替代原生 `f / F / t / T` 的行内跳转，支持 `normal / visual / operator-pending`，行为参考 [clever-f.vim](https://github.com/rhysd/clever-f.vim)：键入一个 ASCII 字符，即可跳到该字符、拼音以它开头的汉字或对应的全角符号上。

| 按键                 | 说明                                                                                 |
| -------------------- | ------------------------------------------------------------------------------------ |
| `f{char}`            | 向右跳到 `{char}` 上                                                                 |
| `F{char}`            | 向左跳到 `{char}` 上                                                                 |
| `t{char}`            | 向右跳到 `{char}` 之前                                                               |
| `T{char}`            | 向左跳到 `{char}` 之后                                                               |
| `[count]` 前缀       | 如 `2fa` 跳到第 2 个匹配（对 `;` / `,` 同样有效）                                    |
| 复按 `f / F / t / T` | 在落点原地再按一次，沿用上次的字符：`f / t` 向右，`F / T` 向左（仅 normal / visual） |
| `;` / `,`            | 沿上次方向重复 / 反向重复（字符记忆跨模式共享）                                      |

> 注：operator-pending 下 `f / F / t / T` 不支持复按，每次都会读取新键；需要连续重复请使用 `;` / `,`。

**拼音匹配与限制：**

- 字母键：同时匹配该字母本身与拼音以它开头的汉字。
- 符号键：同时匹配半角与全角形式。
- 拼音方案：
  - `quanpin`（默认）：`c` 兼匹配 `ch` 开头的汉字，`s` 兼匹配 `sh`，`z` 兼匹配 `zh`。
  - `flypy`：按键与拼音严格一一对应。
- 区分大小写（可用 `g:im_motion_ignore_case` / `g:im_motion_smart_case` 放宽）。
- 仅搜索当前行，不回绕；找不到匹配时光标不动

**记忆规则：**

- 位置记忆（`f / F / t / T` 复按，仅 normal/visual）：按模式隔离，与光标位置绑定，光标一旦移动即失效，下次重新读取按键；operator 下不复按，每次重新读键。
- 字符记忆：全局跨模式共享；移动、超时都不失效；仅手动清除或下次执行 `f / F / t / T`（任意模式）时覆盖。
- `g:im_motion_timeout_ms > 0` 时，位置记忆会在超时后过期；字符记忆不受超时限制；设为 `0` 则位置记忆永不过期。
- 手动清除：`<leader><esc>`（即 `im#motion#reset`）可同时清除位置记忆、字符记忆。

#### 配置

```vim
" 等待按键时是否压暗（shade）整行，以突出目标字（1 开启，0 关闭）
let g:im_motion_shade = 1

" 跳转后是否高亮当前行的目标字（1 开启，0 关闭）
let g:im_motion_mark = 1

" 高亮持续时间，单位毫秒（默认 0）
" 0 表示不设定时，仅在光标移动后清除；大于 0 时，除移动清除外，到时也会自动清除
let g:im_motion_mark_ms = 0

" 复按 f / F / t / T 的位置记忆过期时间，单位为毫秒（默认 0）
" 0 表示永不过期；大于 0 时，超时后复按会重新读取键
let g:im_motion_timeout_ms = 0

" 拼音模式：'quanpin'（默认，全拼）或 'flypy'（小鹤双拼）
let g:im_motion_mode = 'quanpin'

" 忽略大小写（默认 0，区分大小写；设为 1 后，fa 也可以跳转到 A）
let g:im_motion_ignore_case = 0

" 智能大小写（默认 0；设为 1 后，输入小写字母时忽略大小写，输入大写字母时精确匹配；可独立于 ignore_case 生效）
let g:im_motion_smart_case = 0
```

#### 快捷键

```vim
nnoremap <leader><esc> <cmd>call im#motion#reset()<cr>

nnoremap f <Cmd>call im#motion#f()<CR>
nnoremap F <Cmd>call im#motion#F()<CR>
nnoremap t <Cmd>call im#motion#t()<CR>
nnoremap T <Cmd>call im#motion#T()<CR>
nnoremap <leader>; <Cmd>call im#motion#repeat()<CR>
nnoremap <leader>, <Cmd>call im#motion#repeat_back()<CR>

xnoremap f <Cmd>call im#motion#f()<CR>
xnoremap F <Cmd>call im#motion#F()<CR>
xnoremap t <Cmd>call im#motion#t()<CR>
xnoremap T <Cmd>call im#motion#T()<CR>
xnoremap <leader>; <Cmd>call im#motion#repeat()<CR>
xnoremap <leader>, <Cmd>call im#motion#repeat_back()<CR>

onoremap <silent><expr> f im#motion#omap_f()
onoremap <silent><expr> F im#motion#omap_F()
onoremap <silent><expr> t im#motion#omap_t()
onoremap <silent><expr> T im#motion#omap_T()
onoremap <silent><expr> ; im#motion#omap_repeat()
onoremap <silent><expr> , im#motion#omap_repeat_back()
```

#### 高亮

```vim
highlight link ImMotionShade Comment
highlight link ImMotionTarget Search
```

---

### Jump 全屏跳转

![demo5](https://github.com/user-attachments/assets/64188ef1-1c65-4130-9098-91bb005d0bd3)

| 按键               | 说明                                                                         |
| ------------------ | ---------------------------------------------------------------------------- |
| `s{首字母}…{标签}` | 例如 `szja`：`s` 进入搜索，`zj` 将范围收窄到「计算」，`a` 是标签，按下即跳转 |
| `<BS>`             | 删除最后输入的一个字母；输入为空时再按一次则退出                             |
| `<CR>`             | 跳转到第一个候选                                                             |
| `<Esc>` / `<C-c>`  | 取消，光标保持不动                                                           |
| 配合操作符         | 例如 `ds{首字母}…{标签}`：删除从光标到目标位置的内容                         |

#### 配置

```vim
" label 字符集（默认 52 个；候选超数时多出的不显示 label，继续打首字母收窄）
let g:im_jump_labels = 'asdfghjklqwertyuiopzxcvbnmASDFGHJKLQWERTYUIOPZXCVBNM'

" label 位置：'end'（默认，尾字母上）或 'start'（首字母上）或 'after'（尾字母后一字）；
let g:im_jump_label_pos = 'end'

" 单轮最多显示的候选数（默认 60，超出截断）
let g:im_jump_max_matches = 60

" 等待按键时是否压暗有效范围（1 开，0 关）
let g:im_jump_shade = 1

" 等待按键时是否在命令行回显 `> pattern (n)`（1 开，0 关）
let g:im_jump_echo = 1

" pattern 长度上限（默认 0；<=0 不限；超长后多按的键留给下一次操作）
let g:im_jump_max_length = 0

" 拼音模式：'quanpin'（默认）或 'flypy'（小鹤双拼）
let g:im_jump_mode = 'quanpin'

" 忽略大小写（默认 0，区分大小写）
let g:im_jump_ignore_case = 0
```

#### 快捷键

```vim
call im#jump#s([{options}])                       " normal / visual 模式使用
call im#jump#repeat()                             " normal / visual 模式下重放上一次的 pattern
call im#jump#reset()                              " 清除重放记忆
onoremap <expr> {lhs} im#jump#omap([{options}])   " operator-pending 模式使用
```

跳转成功返回 1；用户取消或没有匹配项时返回 0。可选参数 `{options}` 为字典，支持以下键：

> **注意：** 不支持 macro。录制包含 jump 的 macro 可以正常进行，但回放时会跳过 jump 步骤（空操作，光标不动）。

| 键             | 默认值                | 说明                                                                                                                |
| -------------- | --------------------- | ------------------------------------------------------------------------------------------------------------------- |
| `wrap`         | `1`                   | `1`：在整个可见区域内搜索，并按到光标的距离排序；`0`：只向一个方向搜索，按位置顺序排序                              |
| `forward`      | `1`                   | 仅 `wrap` 为 `0` 时有效：`1` 向后（光标之后），`0` 向前（光标之前）                                                 |
| `multi_window` | `0`                   | 是否同时在当前标签页的其他窗口中搜索。只在普通模式且 `wrap` 为 `1` 时生效；预览窗口、浮动窗口、不可聚焦窗口会被忽略 |
| `jump_pos`     | `'start'`             | 跳转后光标落点：`'start'` 匹配首字，`'end'` 匹配末字                                                                |
| `inclusive`    | `1`                   | 在 operator-pending 模式下，`0` 表示光标落在目标前（朝光标原位置方向）一个字符，用于实现「到目标之前」的语义        |
| `label_pos`    | `g:im_jump_label_pos` | 覆盖全局标签位置配置                                                                                                |

```vim
nnoremap ms <Cmd>call im#jump#s({'forward': 1, 'wrap': 1, 'multi_window': 1})<CR>
xnoremap ms <Cmd>call im#jump#s({'forward': 1, 'wrap': 1, 'multi_window': 0})<CR>
nnoremap <leader>. <Cmd>call im#jump#repeat()<CR>
xnoremap <leader>. <Cmd>call im#jump#repeat()<CR>

nnoremap m/ <Cmd>call im#jump#s({'forward': 1, 'wrap': 0, 'multi_window': 0})<CR>
nnoremap m? <Cmd>call im#jump#s({'forward': 0, 'wrap': 0, 'multi_window': 0})<CR>
xnoremap m/ <Cmd>call im#jump#s({'forward': 1, 'wrap': 0, 'multi_window': 0})<CR>
xnoremap m? <Cmd>call im#jump#s({'forward': 0, 'wrap': 0, 'multi_window': 0})<CR>

onoremap <silent><expr> ms im#jump#omap({'forward': 1, 'wrap': 1, 'jump_pos': 'start', 'inclusive': 1})
onoremap <silent><expr> m/ im#jump#omap({'forward': 1, 'wrap': 0, 'jump_pos': 'start', 'inclusive': 1})
onoremap <silent><expr> m? im#jump#omap({'forward': 0, 'wrap': 0, 'jump_pos': 'start', 'inclusive': 1})
onoremap <silent><expr> mt im#jump#omap({'forward': 1, 'wrap': 0, 'jump_pos': 'start', 'inclusive': 0})
onoremap <silent><expr> me im#jump#omap({'forward': 1, 'wrap': 1, 'jump_pos': 'end', 'inclusive': 1})
```

或者

```vim
nnoremap s <Cmd>call im#jump#s({'forward': 1, 'wrap': 1, 'multi_window': 1})<CR>
xnoremap s <Cmd>call im#jump#s({'forward': 1, 'wrap': 1, 'multi_window': 0})<CR>
nnoremap <leader>. <Cmd>call im#jump#repeat()<CR>
xnoremap <leader>. <Cmd>call im#jump#repeat()<CR>

nnoremap / <Cmd>call im#jump#s({'forward': 1, 'wrap': 0, 'multi_window': 0})<CR>
nnoremap ? <Cmd>call im#jump#s({'forward': 0, 'wrap': 0, 'multi_window': 0})<CR>
xnoremap / <Cmd>call im#jump#s({'forward': 1, 'wrap': 0, 'multi_window': 0})<CR>
xnoremap ? <Cmd>call im#jump#s({'forward': 0, 'wrap': 0, 'multi_window': 0})<CR>

onoremap <silent><expr> s im#jump#omap({'forward': 1, 'wrap': 1, 'jump_pos': 'start', 'inclusive': 1})
onoremap <silent><expr> / im#jump#omap({'forward': 1, 'wrap': 0, 'jump_pos': 'start', 'inclusive': 1})
onoremap <silent><expr> ? im#jump#omap({'forward': 0, 'wrap': 0, 'jump_pos': 'start', 'inclusive': 1})
onoremap <silent><expr> t im#jump#omap({'forward': 1, 'wrap': 0, 'jump_pos': 'start', 'inclusive': 0})
onoremap <silent><expr> e im#jump#omap({'forward': 1, 'wrap': 1, 'jump_pos': 'end', 'inclusive': 1})
```

#### 高亮

```vim
highlight link ImJumpShade Comment
highlight link ImJumpMatch Search
highlight link ImJumpLabel Substitute
highlight link ImJumpPrompt Question
```

---

### AutoPair 自动成对

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

- `disabled`（`Number`）：为 `1` 时该 `filetype` 完全停用
- `syntax`（`List`）：高亮组命中即暂停
- `ts`（`List`）：treesitter capture 命中即暂停

> [!Tip]
>
> - `syntax` / `ts` 命中时，仅暂停**改字类动作**（自动补全、成对删除、回车 / 空格展开），**跳出动作不受影响**：光标右侧已有闭符时仍可自动跳出，`im#pair#jump_any()` / `im#pair#jump_many()` 照常可用（例如字符串 `"foo|"` 处按 `"` 会直接跳到引号外）
> - 只有 `disabled: 1` 才会完全停用（含跳出动作），且此时会忽略同条目下的 `syntax` / `ts` 配置
> - `ts` 与 `syntax` 为“或”关系，命中任一即暂停；两者同时配置时优先判定 `ts`；两者均为空时不生效；匹配均不区分大小写

#### `g:im_pair_rules`

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

> [!Tip]
> 优先级：`b:im_pair_rules` > `g:im_pair_rules` > 默认值

#### 内置函数一览

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
  lnoremap <buffer><silent><expr> <bs> im#state#composing() ?
        \ "\<cmd>call im#engine#key(g:RIME_KEYCODE.BackSpace, 0)\<CR>" :
        \ im#replace#can_restore() ? "\<cmd>call im#replace#bs()\<cr>" :
        \ im#pair#should_bs() ? im#pair#bs() : "\<bs>"

  lnoremap <buffer><silent><expr> <s-bs> im#state#composing() ?
        \ "\<cmd>call im#engine#key(g:RIME_KEYCODE.BackSpace, g:RIME_MASK.Shift)\<CR>" :
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
          \ "\<cmd>call im#engine#key(g:RIME_KEYCODE.Return, 0)\<cr>"
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
        \ "\<cmd>call im#engine#key(g:RIME_KEYCODE.space, 0)\<CR>" : im#pair#space()
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

---

### Snippet 片段补全

在组词输入区以 `S` 开头输入字母串，即可触发 snippet 引擎（luasnip / UltiSnips）的片段补全。候选浮窗会实时列出 trigger 匹配的片段，选中后按 `<cr>` 即可展开为代码片段。

#### 按键

| 按键                            | 效果                                   |
| ------------------------------- | -------------------------------------- |
| `<up>` `<down>` `<c-k>` `<c-j>` | 移动选择                               |
| `<pageup>` `<pagedown>`         | 翻页                                   |
| `<cr>`                          | 展开选中的片段；未选中时将输入原样上屏 |
| `<esc>`                         | 取消输入                               |

#### 触发与匹配

- **触发条件**：输入区内容以 `S`（由 `g:im_snip_prefix` 指定）开头。
- **匹配方式**：按 trigger 前缀匹配，随输入逐字收窄。例如输入 `Scodeb` 会匹配 trigger 以 `codeb` 开头的片段（如 `codeblocks`）。
- **无匹配时**：静默回退到普通输入流程。

#### 配置

```vim
" 片段补全开关（默认 0）
let g:im_snip_enabled = 0
" 触发前缀（默认 'S'）
let g:im_snip_prefix = 'S'
" snippet 引擎：'luasnip' 或 'ultisnips'（默认 'luasnip'，其他值视为关闭）
let g:im_snip_preset = 'luasnip'
" 候选右列是否显示描述（默认 1）
let g:im_snip_show_desc = 1
" 候选右列（[S] 描述）的最大显示宽度（默认 24；CJK 字符占 2 格，超出部分截断为 …）
let g:im_snip_desc_max_width = 24
```

#### 快捷键

```vim
im#snip#active()    " 处于 snip 候选状态时返回 1，可作为 <expr> 映射的判断条件
call im#snip#cr()   " snip 候选状态下的回车：若有选中项则展开，否则将已输入内容原样上屏
```

```vim
function RimeKeymapRemap()
   lnoremap <silent><buffer><expr> <c-k> im#state#composing() ?
         \ im#snip#active() ? "\<up>" :
         \ "\<cmd>call im#engine#key(g:RIME_KEYCODE.Up, 0)\<cr>" : "\<up>"
   lnoremap <silent><buffer><expr> <c-j> im#state#composing() ?
         \ im#snip#active() ? "\<down>" :
         \ "\<cmd>call im#engine#key(g:RIME_KEYCODE.Down, 0)\<cr>" : "\<down>"

   lnoremap <silent><buffer><expr> <cr> im#state#composing() ?
         \ im#snip#active() ? "\<cmd>call im#snip#cr()\<cr>"
         \ : "\<cmd>call im#engine#key(g:RIME_KEYCODE.Return, 0)\<cr>"
         \ : im#pair#should_cr() ? im#pair#cr() : "\<cr>"

   lnoremap <silent><buffer><expr> <tab> im#state#composing() ?
        \ "\<cmd>call im#engine#key(g:RIME_KEYCODE.Right, g:RIME_MASK.Shift)\<CR>" :
        \ luasnip#expandable() ?
        \ "<cmd>lua require'luasnip'.expand()<Cr>" : luasnip#jumpable(1) ?
        \ "<cmd>lua require'luasnip'.jump(1)<Cr>" : "\<tab>"

  lnoremap <silent><buffer><expr> <s-tab> im#state#composing() ?
        \ "\<cmd>call im#engine#key(g:RIME_KEYCODE.Left, g:RIME_MASK.Shift)\<CR>" :
        \ luasnip#jumpable(-1) ?
        \ "<cmd>lua require'luasnip'.jump(-1)<Cr>" : "\<s-tab>"
endfunction

function RimeKeymapClear()

endfunction

augroup RimeGroup
  autocmd!
  autocmd User RimeKeymapSetup call RimeKeymapRemap()
  autocmd User RimeKeymapClear call RimeKeymapClear()
augroup END
```

---

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
- `ts` 对应 treesitter highlight capture 名称（大小写不敏感子串匹配，如 `comment` 可命中 `@comment`，`markup.raw` 可命中 `@markup.raw.block`）
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

---

### Typeset 自动排版

遵循 [中文文案排版指北](https://github.com/sparanoid/chinese-copywriting-guidelines)，自动规范中英文混排文本：中英文、数字之间自动补空格，全角 / 半角标点与字母数字自动归一，清理零宽字符与行尾空白，合并连续重复的标点符号。

- **触发方式**：
  - 手动执行 `:IMTypeset`（不受总开关影响）
  - 离开插入模式时自动触发（受 `g:im_typeset_enabled` 总开关与 `g:im_typeset_insert_leave` 控制）
  - 回车换行时格式化上一行（映射 `<Plug>(im-typeset-line)`，受总开关控制）

> [!Tip]
> 本插件仅提供轻量、启发式的行内排版，不保证高精度结果；如需高精度排版推荐使用 [autocorrect](https://github.com/huacnlee/autocorrect)。

#### 配置

```vim
" 自动排版总开关，默认关闭（0）；门控自动触发及回车映射，
" 只有手动 :IMTypeset 不受影响
let g:im_typeset_enabled = 1

" 退出插入模式时自动格式化当前行，默认关闭（0）
let g:im_typeset_insert_leave = 1

let g:im_typeset_config = {
      \ 'markdown': {
      \   'ts': ['markup'],
      \   'syntax': ['link', 'code', 'math', 'table', 'bold', 'italic'],
      \   'rules': im#typeset#rule#default_rules()
      \     + [function('im#typeset#rule#markdown_space_at_bounds')]},
      \ }

" 例外词表：产品名等专有名词内部不受排版影响（默认为空）；保护机制详见下文 Note
let g:im_typeset_ignore_words = ['豆瓣FM']
```

**配置字段：**

- **`ts`**（`List`）：treesitter highlight capture 子串（大小写不敏感），命中即视为保护区域
- **`syntax`**（`List`）：高亮组名子串（大小写不敏感），命中即视为保护区域
- **`rules`**(`List`）：格式化规则链，类型为 `Funcref(ctx, in) -> out`，按数组顺序依次执行
  - **`ctx`**（`Dict`）：上下文信息，包含以下字段
    - `filetype`：当前 buffer 的文件类型（`&filetype`）
    - `bufnr`：当前 buffer 编号（`bufnr()`）
    - `bufname`：当前 buffer 文件名（`bufname()`）
    - `lnum`：当前行号
    - `left_char`：当前片段左边界外的一个字符；若片段位于行首，则为 `''`
    - `right_char`：当前片段右边界外的一个字符；若片段位于行尾，则为 `''`
  - **`in`**(`String`）：待处理的文本片段，同时是上一条规则的输出。
  - **`out`**(`String`)：已处理的文本片段，同时是下一条规则的输入

**内置规则 API**（完整函数名为 `im#typeset#rule#<规则名>(ctx, s)`，下面只列出 `<规则名>` 部分）：

- **`invisible_spaces`**：删零宽字符；行尾空白清理
- **`halfwidth_word`**：全角字母数字 → 半角（含全角空格、数字间时间冒号）
- **`fullwidth_punctuation`**：CJK 旁半角标点 → 全角（括号/书名号；`html` 跳过书名号）
- **`halfwidth_punctuation`**：纯英文段全角标点 → 半角（`,;:!?` 后补空格；含 CJK 整段跳过）
- **`no_space_fullwidth`**：宽字符之间删空格（含 ASCII 侧、全角引号；缩进保留）
- **`space_word`**：段内 CJK ↔ 字母数字间补空格（含 `±n` 双向、`n%`、`C++`/`+`/`#` 后缀；`%s`/`$1`/`\d` 占位符不碰）
- **`space_bracket`**：段内 CJK ↔ 半角 `[]()` 间补空格（拉丁侧不动；`{}` 不管）
- **`space_punctuation`**：`!` + CJK 间补空格
- **`space_pipe_plus`**：段内 CJK/引号旁 `|`/`+` 两侧补空格（`3+5`/`C++`/行首 `+` 不动）
- **`space_backticks`**：段内 CJK ↔ 整对行内代码补空格（孤反引号/围栏不动；跨保护区接缝由 `markdown_space_at_bounds` 处理）
- **`space_dash`**：段内 CJK/引号/括号间 `-` 两侧补空格（`3-5` / `e-mail` 等不动）
- **`space_dollar`**：段内 CJK 旁 `$` 两侧补空格
- **`repeated_punct`**：叠标归一（`。。。` → `······`，`！？` 至多连 3）
- **`markdown_space_at_bounds`**：仅 markdown，正文与行内代码/公式/链接接缝处补空格

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

" 切换自动排版功能
nnoremap <silent> ;T <cmd>call im#typeset#toggle()<cr>
inoremap <silent> ;T <cmd>call im#typeset#toggle()<cr>
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
  lnoremap <buffer><silent><expr> <cr> im#state#composing() ?
          \ "\<cmd>call im#engine#key(g:RIME_KEYCODE.Return, 0)\<cr>"
          \ : im#pair#should_cr() ? im#pair#cr() : "\<Plug>(im-typeset-line)\<cr>"

endfunction

augroup RimeGroup
  autocmd!
  autocmd User RimeKeymapSetup call RimeKeymapRemap()
  autocmd User RimePairImapSetup call RimePairImapRemap()
  autocmd User RimePairImapRestore call RimePairImapRestore()
augroup END

```

---

### Surround 包围编辑

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

所有 g:im*surround*\* 支持 b: 局部覆盖，优先级为 b: > g: > 默认值。surrounds 与 aliases 为整体替换语义，自定义后默认全被取代，需先取默认再拼接。

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

---

### Tips 小技巧

#### 打开用户数据目录

依赖：

- [oil.nvim](https://github.com/stevearc/oil.nvim)

```vim
command! IMUserDataDirV execute 'vsplit | Oil ' . fnameescape(g:im_user_data_dir)
nnoremap ;d :IMUserDataDirV<cr>
```

---

### 其他搭配插件

- [jieba.vim](https://github.com/kkew3/jieba.vim) — jieba 的 Vim/Nvim 按词跳转插件
- [pangu.vim](https://github.com/hotoo/pangu.vim) — 中文排版自动规范化的 Vim 插件

---

### Tmux 弹窗输入

> [!CAUTION]
> 注意：该功能已不再维护，后续不再修复问题或适配新版本。

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

## 附录

`im#engine#key(keycode, mask)` 的取值对照，定义见 `plugin/im_nvim.vim` 的 `g:RIME_KEYCODE` / `g:RIME_MASK`：

```vim
call im#engine#key(g:RIME_KEYCODE.Return, 0)                  " 回车，无修饰
call im#engine#key(g:RIME_KEYCODE.Tab, g:RIME_MASK.Shift)     " Shift+Tab
call im#engine#key(g:RIME_KEYCODE.BackSpace, g:RIME_MASK.Shift) " Shift+BackSpace
```

### Mask 修饰键掩码（`g:RIME_MASK`）

| 名称      | 十六进制     | 十进制     |
| --------- | ------------ | ---------- |
| `Shift`   | `0x00000001` | 1          |
| `Lock`    | `0x00000002` | 2          |
| `Control` | `0x00000004` | 4          |
| `Alt`     | `0x00000008` | 8          |
| `Mod2`    | `0x00000010` | 16         |
| `Mod3`    | `0x00000020` | 32         |
| `Mod4`    | `0x00000040` | 64         |
| `Mod5`    | `0x00000080` | 128        |
| `Button1` | `0x00000100` | 256        |
| `Button2` | `0x00000200` | 512        |
| `Button3` | `0x00000400` | 1024       |
| `Button4` | `0x00000800` | 2048       |
| `Button5` | `0x00001000` | 4096       |
| `Handled` | `0x01000000` | 16777216   |
| `Ignored` | `0x02000000` | 33554432   |
| `Super`   | `0x04000000` | 67108864   |
| `Hyper`   | `0x08000000` | 134217728  |
| `Meta`    | `0x10000000` | 268435456  |
| `Release` | `0x40000000` | 1073741824 |

> 组合用按位或，如 Shift+Control = 1+4 = 5。

### Keycode 键码（`g:RIME_KEYCODE`）

#### ASCII 可打印字符 `0x20-0x7E`

| 名称           | 字符/按键 | 十六进制 | 十进制 |
| -------------- | --------- | -------- | ------ |
| `space`        | Space     | `0x0020` | 32     |
| `exclam`       | `!`       | `0x0021` | 33     |
| `quotedbl`     | `"`       | `0x0022` | 34     |
| `numbersign`   | `#`       | `0x0023` | 35     |
| `dollar`       | `$`       | `0x0024` | 36     |
| `percent`      | `%`       | `0x0025` | 37     |
| `ampersand`    | `&`       | `0x0026` | 38     |
| `apostrophe`   | `'`       | `0x0027` | 39     |
| `parenleft`    | `(`       | `0x0028` | 40     |
| `parenright`   | `)`       | `0x0029` | 41     |
| `asterisk`     | `*`       | `0x002a` | 42     |
| `plus`         | `+`       | `0x002b` | 43     |
| `comma`        | `,`       | `0x002c` | 44     |
| `minus`        | `-`       | `0x002d` | 45     |
| `period`       | `.`       | `0x002e` | 46     |
| `slash`        | `/`       | `0x002f` | 47     |
| `0`            | `0`       | `0x0030` | 48     |
| `1`            | `1`       | `0x0031` | 49     |
| `2`            | `2`       | `0x0032` | 50     |
| `3`            | `3`       | `0x0033` | 51     |
| `4`            | `4`       | `0x0034` | 52     |
| `5`            | `5`       | `0x0035` | 53     |
| `6`            | `6`       | `0x0036` | 54     |
| `7`            | `7`       | `0x0037` | 55     |
| `8`            | `8`       | `0x0038` | 56     |
| `9`            | `9`       | `0x0039` | 57     |
| `colon`        | `:`       | `0x003a` | 58     |
| `semicolon`    | `;`       | `0x003b` | 59     |
| `less`         | `<`       | `0x003c` | 60     |
| `equal`        | `=`       | `0x003d` | 61     |
| `greater`      | `>`       | `0x003e` | 62     |
| `question`     | `?`       | `0x003f` | 63     |
| `at`           | `@`       | `0x0040` | 64     |
| `A`            | `A`       | `0x0041` | 65     |
| `B`            | `B`       | `0x0042` | 66     |
| `C`            | `C`       | `0x0043` | 67     |
| `D`            | `D`       | `0x0044` | 68     |
| `E`            | `E`       | `0x0045` | 69     |
| `F`            | `F`       | `0x0046` | 70     |
| `G`            | `G`       | `0x0047` | 71     |
| `H`            | `H`       | `0x0048` | 72     |
| `I`            | `I`       | `0x0049` | 73     |
| `J`            | `J`       | `0x004a` | 74     |
| `K`            | `K`       | `0x004b` | 75     |
| `L`            | `L`       | `0x004c` | 76     |
| `M`            | `M`       | `0x004d` | 77     |
| `N`            | `N`       | `0x004e` | 78     |
| `O`            | `O`       | `0x004f` | 79     |
| `P`            | `P`       | `0x0050` | 80     |
| `Q`            | `Q`       | `0x0051` | 81     |
| `R`            | `R`       | `0x0052` | 82     |
| `S`            | `S`       | `0x0053` | 83     |
| `T`            | `T`       | `0x0054` | 84     |
| `U`            | `U`       | `0x0055` | 85     |
| `V`            | `V`       | `0x0056` | 86     |
| `W`            | `W`       | `0x0057` | 87     |
| `X`            | `X`       | `0x0058` | 88     |
| `Y`            | `Y`       | `0x0059` | 89     |
| `Z`            | `Z`       | `0x005a` | 90     |
| `bracketleft`  | `[`       | `0x005b` | 91     |
| `backslash`    | (反斜杠)  | `0x005c` | 92     |
| `bracketright` | `]`       | `0x005d` | 93     |
| `asciicircum`  | `^`       | `0x005e` | 94     |
| `underscore`   | `_`       | `0x005f` | 95     |
| `grave`        | (反引号)  | `0x0060` | 96     |
| `a`            | `a`       | `0x0061` | 97     |
| `b`            | `b`       | `0x0062` | 98     |
| `c`            | `c`       | `0x0063` | 99     |
| `d`            | `d`       | `0x0064` | 100    |
| `e`            | `e`       | `0x0065` | 101    |
| `f`            | `f`       | `0x0066` | 102    |
| `g`            | `g`       | `0x0067` | 103    |
| `h`            | `h`       | `0x0068` | 104    |
| `i`            | `i`       | `0x0069` | 105    |
| `j`            | `j`       | `0x006a` | 106    |
| `k`            | `k`       | `0x006b` | 107    |
| `l`            | `l`       | `0x006c` | 108    |
| `m`            | `m`       | `0x006d` | 109    |
| `n`            | `n`       | `0x006e` | 110    |
| `o`            | `o`       | `0x006f` | 111    |
| `p`            | `p`       | `0x0070` | 112    |
| `q`            | `q`       | `0x0071` | 113    |
| `r`            | `r`       | `0x0072` | 114    |
| `s`            | `s`       | `0x0073` | 115    |
| `t`            | `t`       | `0x0074` | 116    |
| `u`            | `u`       | `0x0075` | 117    |
| `v`            | `v`       | `0x0076` | 118    |
| `w`            | `w`       | `0x0077` | 119    |
| `x`            | `x`       | `0x0078` | 120    |
| `y`            | `y`       | `0x0079` | 121    |
| `z`            | `z`       | `0x007a` | 122    |
| `braceleft`    | `{`       | `0x007b` | 123    |
| `bar`          | (竖线)    | `0x007c` | 124    |
| `braceright`   | `}`       | `0x007d` | 125    |
| `asciitilde`   | `~`       | `0x007e` | 126    |

#### 功能键

| 名称           | 字符/按键 | 十六进制 | 十进制 |
| -------------- | --------- | -------- | ------ |
| `ISO_Left_Tab` |           | `0xfe20` | 65056  |
| `BackSpace`    |           | `0xff08` | 65288  |
| `Tab`          |           | `0xff09` | 65289  |
| `Linefeed`     |           | `0xff0a` | 65290  |
| `Clear`        |           | `0xff0b` | 65291  |
| `Return`       |           | `0xff0d` | 65293  |
| `Pause`        |           | `0xff13` | 65299  |
| `Scroll_Lock`  |           | `0xff14` | 65300  |
| `Escape`       |           | `0xff1b` | 65307  |

#### 导航键 `0xFF50-0xFF58`

| 名称        | 字符/按键 | 十六进制 | 十进制 |
| ----------- | --------- | -------- | ------ |
| `Home`      |           | `0xff50` | 65360  |
| `Left`      |           | `0xff51` | 65361  |
| `Up`        |           | `0xff52` | 65362  |
| `Right`     |           | `0xff53` | 65363  |
| `Down`      |           | `0xff54` | 65364  |
| `Page_Up`   |           | `0xff55` | 65365  |
| `Page_Down` |           | `0xff56` | 65366  |
| `End`       |           | `0xff57` | 65367  |
| `Begin`     |           | `0xff58` | 65368  |

#### 杂项 `0xFF60-0xFF7F`

| 名称          | 字符/按键 | 十六进制 | 十进制 |
| ------------- | --------- | -------- | ------ |
| `Select`      |           | `0xff60` | 65376  |
| `Print`       |           | `0xff61` | 65377  |
| `Execute`     |           | `0xff62` | 65378  |
| `Insert`      |           | `0xff63` | 65379  |
| `Undo`        |           | `0xff65` | 65381  |
| `Redo`        |           | `0xff66` | 65382  |
| `Menu`        |           | `0xff67` | 65383  |
| `Find`        |           | `0xff68` | 65384  |
| `Cancel`      |           | `0xff69` | 65385  |
| `Help`        |           | `0xff6a` | 65386  |
| `Break`       |           | `0xff6b` | 65387  |
| `Mode_switch` |           | `0xff7e` | 65406  |
| `Num_Lock`    |           | `0xff7f` | 65407  |

#### 小键盘 `0xFF80-0xFFBD`

| 名称           | 字符/按键 | 十六进制 | 十进制 |
| -------------- | --------- | -------- | ------ |
| `KP_Space`     |           | `0xff80` | 65408  |
| `KP_Tab`       |           | `0xff89` | 65417  |
| `KP_Enter`     |           | `0xff8d` | 65421  |
| `KP_F1`        |           | `0xff91` | 65425  |
| `KP_F2`        |           | `0xff92` | 65426  |
| `KP_F3`        |           | `0xff93` | 65427  |
| `KP_F4`        |           | `0xff94` | 65428  |
| `KP_Home`      |           | `0xff95` | 65429  |
| `KP_Left`      |           | `0xff96` | 65430  |
| `KP_Up`        |           | `0xff97` | 65431  |
| `KP_Right`     |           | `0xff98` | 65432  |
| `KP_Down`      |           | `0xff99` | 65433  |
| `KP_Page_Up`   |           | `0xff9a` | 65434  |
| `KP_Page_Down` |           | `0xff9b` | 65435  |
| `KP_End`       |           | `0xff9c` | 65436  |
| `KP_Begin`     |           | `0xff9d` | 65437  |
| `KP_Insert`    |           | `0xff9e` | 65438  |
| `KP_Delete`    |           | `0xff9f` | 65439  |
| `KP_Multiply`  |           | `0xffaa` | 65450  |
| `KP_Add`       |           | `0xffab` | 65451  |
| `KP_Separator` |           | `0xffac` | 65452  |
| `KP_Subtract`  |           | `0xffad` | 65453  |
| `KP_Decimal`   |           | `0xffae` | 65454  |
| `KP_Divide`    |           | `0xffaf` | 65455  |
| `KP_0`         |           | `0xffb0` | 65456  |
| `KP_1`         |           | `0xffb1` | 65457  |
| `KP_2`         |           | `0xffb2` | 65458  |
| `KP_3`         |           | `0xffb3` | 65459  |
| `KP_4`         |           | `0xffb4` | 65460  |
| `KP_5`         |           | `0xffb5` | 65461  |
| `KP_6`         |           | `0xffb6` | 65462  |
| `KP_7`         |           | `0xffb7` | 65463  |
| `KP_8`         |           | `0xffb8` | 65464  |
| `KP_9`         |           | `0xffb9` | 65465  |
| `KP_Equal`     |           | `0xffbd` | 65469  |

#### F1-F16 `0xFFBE-0xFFCD`

| 名称  | 字符/按键 | 十六进制 | 十进制 |
| ----- | --------- | -------- | ------ |
| `F1`  |           | `0xffbe` | 65470  |
| `F2`  |           | `0xffbf` | 65471  |
| `F3`  |           | `0xffc0` | 65472  |
| `F4`  |           | `0xffc1` | 65473  |
| `F5`  |           | `0xffc2` | 65474  |
| `F6`  |           | `0xffc3` | 65475  |
| `F7`  |           | `0xffc4` | 65476  |
| `F8`  |           | `0xffc5` | 65477  |
| `F9`  |           | `0xffc6` | 65478  |
| `F10` |           | `0xffc7` | 65479  |
| `F11` |           | `0xffc8` | 65480  |
| `F12` |           | `0xffc9` | 65481  |
| `F13` |           | `0xffca` | 65482  |
| `F14` |           | `0xffcb` | 65483  |
| `F15` |           | `0xffcc` | 65484  |
| `F16` |           | `0xffcd` | 65485  |

#### 修饰键 / 删除 `0xFFE1-0xFFFF`

| 名称        | 字符/按键 | 十六进制 | 十进制 |
| ----------- | --------- | -------- | ------ |
| `Shift_L`   |           | `0xffe1` | 65505  |
| `Shift_R`   |           | `0xffe2` | 65506  |
| `Control_L` |           | `0xffe3` | 65507  |
| `Control_R` |           | `0xffe4` | 65508  |
| `Caps_Lock` |           | `0xffe5` | 65509  |
| `Meta_L`    |           | `0xffe7` | 65511  |
| `Meta_R`    |           | `0xffe8` | 65512  |
| `Alt_L`     |           | `0xffe9` | 65513  |
| `Alt_R`     |           | `0xffea` | 65514  |
| `Super_L`   |           | `0xffeb` | 65515  |
| `Super_R`   |           | `0xffec` | 65516  |
| `Hyper_L`   |           | `0xffed` | 65517  |
| `Hyper_R`   |           | `0xffee` | 65518  |
| `Delete`    |           | `0xffff` | 65535  |

## 致谢

- [ZFVimIM](https://github.com/ZSaberLv0/ZFVimIM) — vim 输入法 / Vim Input Method by pure vim script, support: user word, dynamic word priority, cloud db files
- [rime-ls](https://github.com/wlh320/rime-ls) — A language server that provides input method functionality using librime，通过 LSP 代码补全使用 Rime 输入法
- [rime.nvim](https://github.com/rimeinn/rime.nvim) — ㄓ rime for neovim
- [clever-f.vim](https://github.com/rhysd/clever-f.vim) - Extended f, F, t and T key mappings for Vim.
- [vim-easymotion-zh](https://github.com/zzhirong/vim-easymotion-zh) — 基于小鹤双拼让 EasyMotion 识别中文
- [vim-sneak](https://github.com/justinmk/vim-sneak) - The missing motion for Vim 👟
- [hop.nvim](https://github.com/smoka7/hop.nvim) -Neovim motions on speed!
- [flash.nvim](https://github.com/folke/flash.nvim) - Navigate your code with search labels, enhanced character motions and Treesitter integration
- [nvim-autopair](https://github.com/windwp/nvim-autopairs) - autopairs for neovim written in lua
- [delimitMate](https://github.com/Raimondi/delimitMate) - Vim plugin, provides insert mode auto-completion for quotes, parens, brackets, etc.
- [nvim-surround](https://github.com/kylechui/nvim-surround) - Add/change/delete surrounding delimiter pairs with ease. Written with ❤️ in Lua.
- [vim-surround](https://github.com/tpope/vim-surround) - surround.vim: Delete/change/add parentheses/quotes/XML-tags/much more with ease
- [vim-sandwich](https://github.com/machakann/vim-sandwich) - Set of operators and textobjects to search/select/edit sandwiched texts.
- [pangu.vim](https://github.com/hotoo/pangu.vim) — 中文排版自动规范化的 Vim 插件
- [autocorrect](https://github.com/huacnlee/autocorrect) - A linter and formatter to help you to improve copywriting, correct spaces, words, and punctuations between CJK (Chinese, Japanese, Korean).
- [tmux-rime](https://github.com/rimeinn/tmux-rime) - ㄓ rime for tmux

## License

[MIT](./LICENSE)
