import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';
import type {PluginOptions as SearchPluginOptions} from '@easyops-cn/docusaurus-search-local';

function normalizeBaseUrl(raw?: string): string {
  if (!raw || raw.trim() === '') {
    return '/syrius/';
  }
  const trimmed = raw.trim();
  const withLeading = trimmed.startsWith('/') ? trimmed : `/${trimmed}`;
  return withLeading.endsWith('/') ? withLeading : `${withLeading}/`;
}

const docsUrl = (
  process.env.DOCS_URL || 'https://zenon-network.github.io'
).replace(/\/+$/, '');
const docsBaseUrl = normalizeBaseUrl(process.env.DOCS_BASE_URL);

const config: Config = {
  title: 'Syrius Docs',
  tagline: 'Official User & Developer Documentation for the Syrius Zenon Wallet',
  favicon: 'img/favicon.svg',

  future: {
    v4: true,
  },

  url: docsUrl,
  baseUrl: docsBaseUrl,

  organizationName: 'zenon-network',
  projectName: 'syrius',
  trailingSlash: false,

  onBrokenLinks: 'throw',

  markdown: {
    mermaid: true,
    hooks: {
      onBrokenMarkdownLinks: 'throw',
    },
  },

  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  themes: [
    '@docusaurus/theme-mermaid',
    [
      '@easyops-cn/docusaurus-search-local',
      {
        hashed: true,
        indexDocs: true,
        indexBlog: false,
        indexPages: true,
        docsRouteBasePath: '/docs',
        highlightSearchTermsOnTargetPage: true,
        explicitSearchResultPath: true,
        searchBarPosition: 'right',
        searchBarShortcutKeymap: 'mod+k',
      } satisfies SearchPluginOptions,
    ],
  ],

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',
          editUrl:
            'https://github.com/zenon-network/syrius/edit/develop/website/',
        },
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    image: 'img/syrius-icon.png',
    colorMode: {
      defaultMode: 'dark',
      disableSwitch: false,
      respectPrefersColorScheme: true,
    },
    announcementBar: {
      id: 'non_custodial_security_notice',
      content: `<span class="syrius-announcement-dot" aria-hidden="true"></span><strong>Security Reminder:</strong> Syrius is non-custodial and never asks for your seed phrase or keystore password. <a href="${docsBaseUrl}docs/user-guide/security-and-support/security-and-backups">Read security best practices</a>`,
      backgroundColor: '#202120',
      textColor: '#f0f2f0',
      isCloseable: true,
    },
    docs: {
      sidebar: {
        hideable: true,
        autoCollapseCategories: false,
      },
    },
    navbar: {
      title: 'SYRIUS',
      logo: {
        alt: 'Syrius Wallet Logo',
        src: 'img/syrius-logo.svg',
        width: 28,
        height: 28,
      },
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'userGuideSidebar',
          position: 'left',
          label: 'User Guide',
        },
        {
          type: 'docSidebar',
          sidebarId: 'developersSidebar',
          position: 'left',
          label: 'Developers',
        },
        {
          to: '/docs/user-guide/security-and-support/troubleshooting-and-faq',
          label: 'FAQ',
          position: 'left',
        },
        {
          href: 'https://github.com/zenon-network/syrius/releases',
          label: 'Releases',
          position: 'right',
        },
        {
          href: 'https://github.com/zenon-network/syrius',
          label: 'GitHub',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'User Guide',
          items: [
            {
              label: 'Overview',
              to: '/docs/user-guide/intro',
            },
            {
              label: 'Installation',
              to: '/docs/user-guide/getting-started/installation',
            },
            {
              label: 'Create or Restore Wallet',
              to: '/docs/user-guide/getting-started/create-or-restore-wallet',
            },
            {
              label: 'Ledger Hardware Wallet',
              to: '/docs/user-guide/hardware-and-nodes/ledger-hardware-wallet',
            },
            {
              label: 'Node Modes',
              to: '/docs/user-guide/hardware-and-nodes/node-modes',
            },
            {
              label: 'Troubleshooting & FAQ',
              to: '/docs/user-guide/security-and-support/troubleshooting-and-faq',
            },
          ],
        },
        {
          title: 'Developers',
          items: [
            {
              label: 'Developer Overview',
              to: '/docs/developers/intro',
            },
            {
              label: 'Environment Setup',
              to: '/docs/developers/getting-started/environment-setup',
            },
            {
              label: 'Architecture Overview',
              to: '/docs/developers/architecture/overview',
            },
            {
              label: 'BLoC Rearchitecture',
              to: '/docs/developers/architecture/bloc-rearchitecture',
            },
            {
              label: 'Blockchain Integration Tests',
              to: '/docs/developers/testing/blockchain-integration-tests',
            },
            {
              label: 'Contributing Guide',
              to: '/docs/developers/contributing/contributing-guide',
            },
          ],
        },
        {
          title: 'Ecosystem & Resources',
          items: [
            {
              label: 'Zenon Network',
              href: 'https://zenon.network',
            },
            {
              label: 'Syrius GitHub',
              href: 'https://github.com/zenon-network/syrius',
            },
            {
              label: 'Releases',
              href: 'https://github.com/zenon-network/syrius/releases',
            },
            {
              label: 'Security & Backups',
              to: '/docs/user-guide/security-and-support/security-and-backups',
            },
            {
              label: 'Zenon Dart SDK',
              href: 'https://github.com/zenon-network/znn_sdk_dart',
            },
            {
              label: 'Go-Zenon Full Node',
              href: 'https://github.com/zenon-network/go-zenon',
            },
          ],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} Zenon Network Community · Syrius Wallet (MIT License).`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.oneDark,
      additionalLanguages: ['dart', 'bash', 'yaml', 'json', 'gherkin'],
    },
    mermaid: {
      theme: {
        light: 'neutral',
        dark: 'dark',
      },
      options: {
        fontFamily:
          "Inter, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif",
        flowchart: {
          curve: 'basis',
          padding: 16,
        },
        themeVariables: {
          fontFamily:
            "Inter, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif",
          fontSize: '14px',
        },
      },
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
