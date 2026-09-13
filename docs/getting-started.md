---
title: 快速开始
description: 环境要求、安装与 rime-query 后端编译
---

<!-- 本页内容由 README.zh.md 切分生成，与 README.zh.md 同步维护 -->

# 快速开始

## 环境要求

- Vim >= 8.2.1978 或 Neovim
- [librime](https://github.com/rime/librime)（编译后端所必需）
- Rime 共享数据目录与用户数据目录（例如 [rime-ice](https://github.com/iDvel/rime-ice)）

## 安装

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

## 编译后端

构建出的 `rime-query` 可执行文件需能被找到（默认查找 `PATH`，也可通过 `g:im_rime_bin` 指定路径），否则 `:IMStart` 会失败。

> 以下命令中的仓库路径 `/path/to/rime.vim` 请替换为你的实际路径。

### macOS

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

---

### Linux

需手动编译 librime，并分别指定其头文件 include 路径与动态库 lib 路径：

```bash
cd /path/to/rime.vim/cpp
clang++ -std=c++17 -I./3rd -I/path/to/librime/include -L/path/to/librime/lib -lstdc++ -lrime -o build/rime-query rime-query.cc
```

---

### Windows

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

::: info

需要 `clang++` 与 `mingw32-make` 在 `PATH` 中
:::

构建完成后，请把生成的 `rime-query` 加入 `PATH`。

---

### 在编辑器内编译

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
|------------|-----------------------------------|
| `:IMCheck` | 自检：编译器/参数/路径/是否已编译 |
| `:IMBuild` | 后台异步编译                      |
| `:IMClean` | 清理编译结果                      |

流程：配置 → `:IMCheck` 验证 → `:IMBuild`。
