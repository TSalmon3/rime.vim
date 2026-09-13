<p align="center">
  <img alt="Logo" src="./icon.png" height="200" />
  <p align="center">Rime input method support for Vim/Neovim</p>
  <p align="center">
    <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square"></a>
    <a href="https://GitHub.com/Naereen/StrapDown.js/graphs/commit-activity"><img alt="Maintenance" src="https://img.shields.io/badge/Maintained%3F-yes-green.svg?style=flat-square"></a>
  </p>
</p>


![demo1](https://github.com/user-attachments/assets/20978d66-c198-426f-97f1-0ba7322cf656)
![demo2](https://github.com/user-attachments/assets/820db16b-b76b-4b15-a5f4-a8a6a58306bd)
![demo3](https://github.com/user-attachments/assets/f2fba3e1-d7dc-4b1c-bd5a-779b4e725a45)

## 功能

- 支持全拼、双拼、九宫格等输入方案
- 支持简繁、中英文标点、emoji 切换
- 候选词浮窗、下划线渲染、状态栏可显示当前输入状态
- 支持括号、引号等自动补全
- 支持中英文自动切换
- 支持替换模式
- 支持多实例共享词频学习，甚至 Vim 和 Neovim 混合多实例
- 提供命令行和终端输入解决方案


## 依赖

- Vim >= 8.2.1978 或 Neovim
- [librime](https://github.com/rime/librime)（编译后端所必需）
- Rime 共享数据目录与用户数据目录（例如 [rime-ice](https://github.com/iDvel/rime-ice)）

## 快速开始

- 文档站 Website: https://tsalmon3.github.io/rime.vim/
- 中文说明: [README.zh.md](./README.zh.md)
- 英文说明: [README.en.md](./README.en.md)

## 其他搭配插件

- [jieba.vim](https://github.com/kkew3/jieba.vim) — jieba 的 Vim/Nvim 按词跳转插件
- [pangu.vim](https://github.com/hotoo/pangu.vim) — 中文排版自动规范化的 Vim 插件
- [vim-easymotion-zh](https://github.com/zzhirong/vim-easymotion-zh) — 基于小鹤双拼让 EasyMotion 识别中文

## 致谢

- [ZFVimIM](https://github.com/ZSaberLv0/ZFVimIM) — vim 输入法 / Vim Input Method by pure vim script, support: user word, dynamic word priority, cloud db files
- [rime-ls](https://github.com/wlh320/rime-ls) — A language server that provides input method functionality using librime，通过 LSP 代码补全使用 Rime 输入法
- [rime.nvim](https://github.com/rimeinn/rime.nvim) — ㄓ rime for neovim
- [delimitMate](https://github.com/Raimondi/delimitMate) - Vim plugin, provides insert mode auto-completion for quotes, parens, brackets, etc.
- [nvim-surround](https://github.com/kylechui/nvim-surround) - Add/change/delete surrounding delimiter pairs with ease. Written with ❤️ in Lua.
- [vim-surround](https://github.com/tpope/vim-surround) - surround.vim: Delete/change/add parentheses/quotes/XML-tags/much more with ease
- [vim-sandwich](https://github.com/machakann/vim-sandwich) - Set of operators and textobjects to search/select/edit sandwiched texts.
- [tmux-rime](https://github.com/rimeinn/tmux-rime) - ㄓ rime for tmux

## License

MIT
