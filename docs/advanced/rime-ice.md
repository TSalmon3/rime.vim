---
title: rime-ice 配置示例
description: 雾凇拼音配置示例
---

<!-- 本页内容由 README.zh.md 切分生成，与 README.zh.md 同步维护 -->

# rime-ice 配置示例

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
