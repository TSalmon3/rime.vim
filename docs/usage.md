---
title: 使用
description: 命令与按键映射
---

<!-- 本页内容由 README.zh.md 切分生成，与 README.zh.md 同步维护 -->

# 使用

## 命令

| 命令                           | 说明                                                  |
|--------------------------------|-------------------------------------------------------|
| `:IMStart`                     | 启动/重启输入法（连接或拉起共享 `rime-query` daemon） |
| `:IMStop`                      | 停止输入法（只断开本编辑器的连接）                    |
| `:IMToggle`                    | 切换输入法开关                                        |
| `:IMDeploy`                    | 重新部署 Rime（改配置后生效）                         |
| `:IMSync`                      | 同步用户词库并重新部署                                |
| `:IMShutdown`                  | 关停共享 daemon（所有编辑器断开）                     |
| `:IMSchemeDownload <git-url>`  | 下载输入方案到 `g:im_scheme_dir`                      |

### 重新部署

修改用户数据目录中的配置（如 `default.custom.yaml` 的 `schema_list` / `page_size`）后，需执行 `:IMDeploy` 使改动生效。部署期间编辑器会短暂阻塞，超时时间可用 `g:im_deploy_timeout`（毫秒）调整。

### 同步词库

`:IMSync` 会先将用户词库（`*.userdb/`）与 `sync/<installation_id>/*.userdb.txt` 备份双向合并，再重新部署，便于跨设备、跨平台同步个人词频。多台设备之间建议将 `installation.yaml` 中的 `installation_id` 设为同一值，否则合并可能失败。

### 下载方案

`:IMSchemeDownload <git-url>` 会用 `git clone --depth 1` 把输入方案下载到 `g:im_scheme_dir`（默认 `~/.local/share/rime-schemes`），目录名取自 URL 最后一段（自动去掉 `.git` 后缀）。若目标目录已存在则跳过，不会覆盖。

## 按键映射

默认按键映射（可设 `g:im_no_default_mappings=1` 关闭，用对应的 `g:im_*_key` 修改）：

| 按键    | 模式                                 | 功能                    |
|---------|--------------------------------------|-------------------------|
| `;;`    | normal / insert / command / terminal | 切换输入法开关          |
| `;,`    | normal / insert                      | 切换中/英模式           |
| `;a`    | normal / insert                      | 切换中英文标点          |
| `;f`    | normal / insert                      | 切换简/繁体             |
| `;e`    | normal / insert                      | 切换 emoji              |

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
