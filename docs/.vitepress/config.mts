import { defineConfig } from 'vitepress'

export default defineConfig({
  lang: 'zh-CN',
  title: 'rime.vim',
  description: 'Vim/Neovim 的 Rime 输入法集成',
  base: '/rime.vim/',

  themeConfig: {
    siteTitle: 'rime.vim',

    nav: [
      { text: '首页', link: '/' },
      { text: '快速开始', link: '/getting-started' },
      { text: '配置', link: '/configuration' },
      { text: '使用', link: '/usage' },
      { text: '高级主题', link: '/advanced/rime-ice' },
    ],

    sidebar: [
      {
        text: '指南',
        items: [
          { text: '快速开始', link: '/getting-started' },
          { text: '配置', link: '/configuration' },
          { text: '使用', link: '/usage' },
          { text: '集成', link: '/integration' },
        ],
      },
      {
        text: '高级主题',
        collapsed: false,
        items: [
          { text: 'rime-ice 配置示例', link: '/advanced/rime-ice' },
          { text: '让中文编辑更加丝滑', link: '/advanced/smooth-editing' },
          { text: '定制中英切换与方案选单', link: '/advanced/toggle-scheme' },
          { text: 'Replace Mode 替换模式', link: '/advanced/replace-mode' },
          { text: 'Auto Pair 自动成对', link: '/advanced/auto-pair' },
          { text: 'Surround 包围编辑', link: '/advanced/surround' },
          { text: 'Context 自动切换', link: '/advanced/context' },
          { text: 'Tmux 弹窗输入', link: '/advanced/tmux' },
        ],
      },
      {
        text: '附录',
        items: [{ text: '搭配与致谢', link: '/complementary' }],
      },
    ],

    search: {
      provider: 'local',
      options: {
        locales: {
          root: {
            translations: {
              button: { buttonText: '搜索文档', buttonAriaLabel: '搜索文档' },
              modal: {
                noResultsText: '无法找到相关结果',
                resetButtonTitle: '清除查询条件',
                footer: { selectText: '选择', navigateText: '切换' },
              },
            },
          },
        },
      },
    },

    socialLinks: [{ icon: 'github', link: 'https://github.com/TSalmon3/rime.vim' }],
    editLink: {
      pattern: 'https://github.com/TSalmon3/rime.vim/edit/main/docs/:path',
      text: '在 GitHub 上编辑此页',
    },
    lastUpdated: { text: '最后更新于', formatOptions: { dateStyle: 'short', timeStyle: 'short' } },
    outline: 'deep',
    docFooter: { prev: '上一页', next: '下一页' },
    darkModeSwitchLabel: '主题',
    sidebarMenuLabel: '菜单',
    returnToTopLabel: '回到顶部',

    footer: {
      message: '基于 MIT 许可发布',
      copyright: 'rime.vim 文档（内容与 README.zh.md 同步维护）',
    },
  },
})
