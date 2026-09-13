---
title: 配置
description: 选项变量与环境变量
---

<!-- 本页内容由 README.zh.md 切分生成，与 README.zh.md 同步维护 -->

# 配置

## 选项

::: tip
以雾凇拼音（rime-ice）为例，如果你的系统中已安装了「鼠须管」或「小狼毫」，建议新建一个用户数据目录，避免产生冲突。
:::

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

::: info
Windows 上 daemon 只监听单条 TCP 通道（Vim 与 Neovim 共用）。
如自定义了 `g:im_tcp_addr`，vimrc 与 Neovim 配置需保持一致。
:::

## 环境变量

插件通过三个环境变量获取数据目录与日志路径，两种设置方式任选其一：

### 在 Vim 中设置

在 vimrc 中、插件加载前设置：

```vim
" RIME_LOG — 后端日志路径
let $RIME_LOG = expand("~/.local/state/log/vim/rime.log")

" RIME_USER_DATA_DIR — 用户数据目录
let $RIME_USER_DATA_DIR = "/path/to/rime"

" RIME_SHARED_DATA_DIR — 共享数据目录
let $RIME_SHARED_DATA_DIR = "/usr/share/rime-data"
```

### 在终端中设置

如果希望这些目录对所有程序生效，可在 shell 配置（如 `~/.zshrc`）中导出：

```sh
export RIME_LOG="$HOME/.local/state/log/vim/rime.log"
export RIME_USER_DATA_DIR="$HOME/.local/share/rime-ice"
export RIME_SHARED_DATA_DIR="/usr/share/rime-data"
```

Windows 下还可通过 `RIME_QUERY_TCP` 覆盖后端 TCP 监听端点（默认 `127.0.0.1:18666`；
与 `g:im_tcp_addr` 同义，二者同时设置时以 `g:im_tcp_addr` 优先）。

> 注意：在 Vim 中设置 `g:im_user_data_dir` / `g:im_shared_data_dir` / `g:im_log_file` 会覆盖同名环境变量。
