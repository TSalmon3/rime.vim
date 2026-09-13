---
layout: home

hero:
  name: rime.vim
  text: Vim/Neovim 的 Rime 输入法集成
  tagline: 插入模式直输拼音，浮窗选词、多实例共享词频
  image:
    src: /icon.png
    alt: rime.vim Logo
  actions:
    - theme: brand
      text: 快速开始
      link: /getting-started
    - theme: alt
      text: 在 GitHub 上查看
      link: https://github.com/TSalmon3/rime.vim

features:
  - title: 支持多种输入方案
    details: 全拼、双拼、九宫格开箱即用，简繁、标点、emoji 一键切换
    link: /advanced/rime-ice
  - title: 原生级输入体验
    details: 候选词浮窗、下划线渲染，状态栏实时显示输入状态
    link: /usage
  - title: 中英智能切换
    details: 按语法作用域自动切换中英
    link: /advanced/context
  - title: 多实例共享词频
    details: 共享 rime-query daemon，多开共学词频，Vim / Neovim 可混用
    link: /integration
  - title: 多场景支持
    details: 覆盖插入、替换、命令行、终端等场景，另有 tmux 弹窗输入方案
    link: /advanced/tmux
  - title: 中文编辑增强
    details: Replace 覆盖改写、Auto Pair 括号自动补全、Surround 包围编辑，让中文编辑更丝滑
    link: /advanced/replace-mode
---

## 简介

Rime（中州韵）在 Vim / Neovim 中的集成方案，同时支持 Vim（>= 8.2.1978）与 Neovim。

**用法**：进入插入模式后直接键入拼音，即可弹出候选词浮窗；用数字键或 `Up` / `Down` 选择候选，`Enter` / `Space` 上屏，`Esc` 取消本次输入。


## 效果预览

![demo](https://github.com/user-attachments/assets/20978d66-c198-426f-97f1-0ba7322cf656)
![demo2](https://github.com/user-attachments/assets/820db16b-b76b-4b15-a5f4-a8a6a58306bd)
![demo3](https://github.com/user-attachments/assets/f2fba3e1-d7dc-4b1c-bd5a-779b4e725a45)

