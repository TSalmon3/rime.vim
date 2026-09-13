---
title: Tmux 弹窗输入
description: tmux display-popup 输入方案
---

<!-- 本页内容由 README.zh.md 切分生成，与 README.zh.md 同步维护 -->

# Tmux 弹窗输入

在 tmux 中通过 `display-popup` 弹窗使用 Rime 输入法，复用同一个 `rime-query` daemon。

![tmux](https://github.com/user-attachments/assets/fb715949-57d0-4337-870a-5273e3bc1d6c)

## 要求

- tmux >= 3.3
- Python 3
- rime-query 可执行文件（见 [编译后端](/getting-started#编译后端)）

## 安装

使用 [TPM](https://github.com/tmux-plugins/tpm)：

```txt
set -g @plugin 'TSalmon3/rime.vim'
```

或手动在 `.tmux.conf` 中添加：

```txt
run-shell '/path/to/rime.vim/rime.tmux'
```

安装后按 `prefix + ;` 即可弹出 Rime 输入窗口。

## 按键

| 按键                | 功能                |
|---------------------|---------------------|
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
| `Ctrl+p`            | 切换半角/全角标点    |
| `Ctrl+f`            | 切换简体/繁体       |
| `Esc`               | 取消组合 / 关闭弹窗 |
| `Ctrl-c`            | 退出弹窗            |

## 配置

通过 tmux 选项设置（在 `.tmux.conf` 中 `run-shell` 之前）：

| 选项                        | 默认值       | 说明                               |
| --------------------------- | ------------ | ---------------------------------- |
| `@rime_key`                 | `;`          | 绑定的前缀键                       |
| `@rime_bin`                 | `rime-query` | `rime-query` 可执行文件路径        |
| `@rime_socket`              | 空           | Unix socket 路径，留空自动检测     |
| `@rime_popup`               | 空           | 自定义 `display-popup` 参数        |
| `@rime_option_ascii_punct`  | 空           | 初始标点状态（0=全角，1=半角）     |
| `@rime_option_traditional`  | 空           | 初始简繁状态（0=简体，1=繁体）     |

```txt
set -g @rime_key ";"
set -g @rime_bin "rime-query"
```

自定义 `@rime_popup` 会覆盖默认的弹窗尺寸与位置：

```txt
set -g @rime_popup "-w80% -h10 -xC -yC -E -T ㄓ"
```

设置初始状态：

```txt
set -g @rime_option_ascii_punct 1      # 初始半角标点
set -g @rime_option_traditional 0      # 初始简体
```

## 环境变量

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
