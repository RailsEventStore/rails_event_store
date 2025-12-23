// @ts-check
// `@type` JSDoc annotations allow editor autocompletion and type checking
// (when paired with `@ts-check`).
// There are various equivalent ways to declare your Docusaurus config.
// See: https://docusaurus.io/docs/api/docusaurus-config

import { themes as prismThemes } from "prism-react-renderer";
import tailwindPlugin from "./plugins/tailwind-config.cjs"; // add this

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: "Rails Event Store",
  tagline:
    "The open-source implementation of an Event Store for Ruby and Rails",
  favicon: "img/favicon.ico",
  themes: ["@docusaurus/theme-mermaid"],
  markdown: {
    mermaid: true,
  },

  // Set the production url of your site here
  url: "https://railseventstore.org",
  // Set the /<baseUrl>/ pathname under which your site is served
  // For GitHub pages deployment, it is often '/<projectName>/'
  baseUrl: "/",

  // GitHub pages deployment config.
  // If you aren't using GitHub pages, you don't need these.
  organizationName: "RailsEventStore", // Usually your GitHub org/user name.
  projectName: "rails_event_store", // Usually your repo name.

  onBrokenLinks: "warn",
  onBrokenMarkdownLinks: "warn",

  // Even if you don't use internationalization, you can use this field to set
  // useful metadata like html lang. For example, if your site is Chinese, you
  // may want to replace "en" with "zh-Hans".
  i18n: {
    defaultLocale: "en",
    locales: ["en"],
  },

  presets: [
    [
      "classic",
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: {
          lastVersion: "2.18.0",
          versions: {
            current: {
              label: "Master",
              path: "master",
            },
          },
          sidebarPath: "./sidebars.json",
          // Please change this to your repo.
          // Remove this to remove the "edit this page" links.
          editUrl:
            "https://github.com/RailsEventStore/rails_event_store/tree/master/railseventstore.org/",
        },
        blog: false,
        theme: {
          customCss: "./src/css/custom.css",
        },
      }),
    ],
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      // Replace with your project's social card
      image: "img/docusaurus-social-card.png",
      navbar: {
        title: "Rails Event Store",
        logo: {
          alt: "Rails Event Store Logo",
          src: "img/logo.svg",
        },

        items: [
          {
            type: "docsVersionDropdown",
            position: "right",
            dropdownActiveClassDisabled: true,
          },
          {
            type: "doc",
            docId: "getting-started/introduction",
            position: "right",
            label: "Docs",
          },
          {
            href: "/community",
            position: "right",
            label: "Community",
          },
          {
            href: "/support",
            position: "right",
            label: "Support",
          },
          {
            href: "https://github.com/RailsEventStore/rails_event_store/releases/tag/v2.18.0",
            label: "Changelog",
            position: "right",
          },
          {
            href: "https://github.com/RailsEventStore/rails_event_store",
            label: "GitHub",
            position: "right",
          },
        ],
      },
      footer: {
        style: "dark",

        links: [
          {
            title: "Rails Event Store",
            items: [
              {
                label: "Documentation",
                to: "/docs/getting-started/introduction",
              },
              {
                label: "Changelog",
                href: "https://github.com/RailsEventStore/rails_event_store/releases/tag/v2.18.0",
              },
              {
                label: "GitHub",
                href: "https://github.com/RailsEventStore/rails_event_store",
              },
            ],
          },
          {
            title: "Developers",
            items: [
              {
                label: "Community",
                to: "/community",
              },
              {
                label: "Support",
                to: "/support",
              },
              {
                label: "Contributing",
                to: "/contributing",
              },
            ],
          },
          {
            title: "Connect",
            items: [
              {
                label: "Stack Overflow",
                href: "https://stackoverflow.com/questions/tagged/rails-event-store",
              },
              {
                label: "Discord",
                href: "https://discord.gg/qjPr9ZBpX6",
              },
              {
                label: "X",
                href: "https://x.com/RailsEventStore",
              },
            ],
          },
        ],
        copyright: `<p class="mt-8">Brought to you by <a href="https://arkency.com" target="_blank"><img src="/images/arkency.svg" alt="Arkency" class="w-20 -translate-y-[3px]"></a></p>
        <p class="mt-8 text-sm text-gray-500 max-w-4xl mx-auto">The Rails trademarks are the intellectual property of David Heinemeier Hanson, and exclusively licensed to the Rails Foundation. Uses of 'Rails' and 'Ruby on Rails' in this website are for identification purposes only and do not imply an endorsement by or affiliation with Rails, the trademark owner, or the Rails Foundation.</p>
        `,
      },
      prism: {
        theme: prismThemes.github,
        additionalLanguages: ["bash", "ruby"],
      },
      algolia: {
        appId: "KK97TFKI4L",
        apiKey: "b16a0b4f93147cc606175f7117f8aa1d",
        indexName: "railseventstore_docusaurus",
        contextualSearch: true,
      },
    }),

  plugins: [tailwindPlugin],
  scripts: [
    {
      src: "https://plausible.io/js/script.js",
      defer: true,
      "data-domain": "railseventstore.org",
    },
  ],
};

export default config;
