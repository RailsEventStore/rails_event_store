// @ts-check
// `@type` JSDoc annotations allow editor autocompletion and type checking
// (when paired with `@ts-check`).
// There are various equivalent ways to declare your Docusaurus config.
// See: https://docusaurus.io/docs/api/docusaurus-config

import {themes as prismThemes} from 'prism-react-renderer';
import tailwindPlugin from "./plugins/tailwind-config.cjs"; // add this


/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'Rails Event Store',
  tagline: 'The open-source implementation of an Event Store for Ruby and Rails',
  favicon: 'img/favicon.ico',

  // Set the production url of your site here
  url: 'https://railseventstore.org',
  // Set the /<baseUrl>/ pathname under which your site is served
  // For GitHub pages deployment, it is often '/<projectName>/'
  baseUrl: '/',

  // GitHub pages deployment config.
  // If you aren't using GitHub pages, you don't need these.
  organizationName: 'RailsEventStore', // Usually your GitHub org/user name.
  projectName: 'rails_event_store', // Usually your repo name.

  onBrokenLinks: 'throw',
  onBrokenMarkdownLinks: 'warn',

  // Even if you don't use internationalization, you can use this field to set
  // useful metadata like html lang. For example, if your site is Chinese, you
  // may want to replace "en" with "zh-Hans".
  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: {
          sidebarPath: './sidebars.js',
          // Please change this to your repo.
          // Remove this to remove the "edit this page" links.
          editUrl:
            'https://github.com/facebook/docusaurus/tree/main/packages/create-docusaurus/templates/shared/',
        },
        blog: {
          showReadingTime: true,
          // Please change this to your repo.
          // Remove this to remove the "edit this page" links.
          editUrl:
            'https://github.com/facebook/docusaurus/tree/main/packages/create-docusaurus/templates/shared/',
        },
        theme: {
          customCss: './src/css/custom.css',
        },
      }),
    ],
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      // Replace with your project's social card
      image: 'img/docusaurus-social-card.jpg',
      navbar: {
        title: 'Rails Event Store',
        logo: {
          alt: 'Rails Event Store Logo',
          src: 'img/logo.svg',
        },

        items: [
          {
            type: 'doc',
            position: 'right',
            docId: 'start',
            label: 'Docs',
          },
          {
            href: '/community',
            position: 'right',
            label: 'Community',
          },
          {
            href: '/contributing',
            position: 'right',
            label: 'Contributing',
          },
          {
            href: '/support',
            position: 'right',
            label: 'Support',
          },
          {
            href: 'https://github.com/RailsEventStore/rails_event_store',
            label: 'GitHub',
            position: 'right',
          },
        ],
      },
      footer: {
        style: 'dark',

        links: [
          {
            title: 'Rails Event Store',
            items: [
              {
                label: 'Community',
                to: '/community',
              },
              {
                label: 'Support',
                to: '/support',
              },
              {
                label: 'Contributing',
                to: '/contributing',
              },
            ],
          },
          {
            title: 'Documentation',
            items: [
              {
                label: 'Geting Started',
                to: '/docs/start',
              }
            ],
          },
          {
            title: 'Connect',
            items: [
              {
                label: 'Stack Overflow',
                href: 'https://stackoverflow.com/questions/tagged/rails-event-store',
              },
              {
                label: 'Discord',
                href: 'https://discord.gg/qjPr9ZBpX6',
              },
              {
                label: 'X',
                href: 'https://x.com/RailsEventStore',
              },
            ],
          },
         
        ],
        copyright: `<p class="mt-8">Supported by <a href="https://arkency.com" target="_blank">Arkency</a></p>`,
      },
      prism: {
        theme: prismThemes.github,
        darkTheme: prismThemes.dracula,
      },
    }),

    plugins: [tailwindPlugin]
};

export default config;
