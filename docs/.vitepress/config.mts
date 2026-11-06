import { defineConfig } from 'vitepress'

// GitHub Pages serves a project site under /<repository>/; the deploy workflow
// sets DOCS_BASE from the repository name. Locally the site lives at /.
const base = process.env.DOCS_BASE || '/'
const repo = 'https://github.com/miercolesv/mt7981-cudy-overclock'

export default defineConfig({
  base,
  title: 'MT7981 overclock',
  description:
    'Overclock the MediaTek MT7981B (Filogic 820) in Cudy routers running OpenWrt ubootmod, from 1.3 GHz up to 1.4–1.7 GHz.',
  lang: 'en',
  cleanUrls: true,
  srcExclude: ['**/node_modules/**'],
  markdown: { languageAlias: { dts: 'c' } },
  head: [
    ['link', { rel: 'icon', type: 'image/svg+xml', href: `${base}logo.svg` }],
    ['meta', { name: 'theme-color', content: '#ff7a45' }],
  ],
  themeConfig: {
    logo: '/logo.svg',
    nav: [
      { text: 'Guide', link: '/guide/getting-started', activeMatch: '/guide/' },
      { text: 'Runtime module', link: '/runtime-module' },
      { text: 'Flashing', link: '/bl2-flashing' },
      { text: 'Reference', link: '/reference/commands', activeMatch: '/reference/' },
      { text: 'Releases', link: `${repo}/releases` },
    ],
    sidebar: [
      {
        text: 'Guide',
        items: [
          { text: 'Getting started', link: '/guide/getting-started' },
          { text: 'Supported devices', link: '/guide/supported-devices' },
          { text: 'How it works', link: '/guide/how-it-works' },
        ],
      },
      {
        text: 'Overclocking',
        items: [
          { text: '1. Runtime module', link: '/runtime-module' },
          { text: '2. Flashing the preloader', link: '/bl2-flashing' },
          { text: 'Results', link: '/results' },
        ],
      },
      {
        text: 'When things go wrong',
        items: [
          { text: 'Recovery', link: '/recovery' },
          { text: 'Known issues', link: '/guide/known-issues' },
        ],
      },
      {
        text: 'Building',
        items: [
          { text: 'Building from source', link: '/building' },
          { text: 'Automated builds', link: '/automation' },
        ],
      },
      {
        text: 'Reference',
        items: [
          { text: 'Commands', link: '/reference/commands' },
          { text: 'References and credits', link: '/reference/references' },
        ],
      },
    ],
    socialLinks: [{ icon: 'github', link: repo }],
    editLink: { pattern: `${repo}/edit/main/docs/:path`, text: 'Edit this page on GitHub' },
    search: { provider: 'local' },
    outline: { level: [2, 3], label: 'On this page' },
    footer: {
      message: 'No warranty. Not affiliated with Cudy, MediaTek or OpenWrt.',
    },
  },
})
