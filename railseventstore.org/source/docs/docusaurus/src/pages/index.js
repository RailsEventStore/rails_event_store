import clsx from "clsx";
import Link from "@docusaurus/Link";
import useDocusaurusContext from "@docusaurus/useDocusaurusContext";
import Layout from "@theme/Layout";
import HomepageFeatures from "@site/src/components/HomepageFeatures";
import HomepageCompanies from "@site/src/components/HomepageCompanies";

import Heading from "@theme/Heading";
import styles from "./index.module.css";

function HomepageHeader() {
  const { siteConfig } = useDocusaurusContext();
  return (
    <header className={clsx("hero hero--primary", styles.heroBanner)}>
      <div className="container">
        <h1 className="text-3xl lg:text-4xl">
          {siteConfig.title}
        </h1>
        <p className="mb-10 text-xl lg:text-2xl">{siteConfig.tagline}</p>
        <div className="flex flex-wrap justify-center gap-4">
          <Link
            className="button button--secondary button--lg"
            to="/docs/start"
          >
            Get Started
          </Link>
          <Link className="button button--primary button--lg" to="/support">
            Get Support
          </Link>
        </div>
      </div>
    </header>
  );
}

export default function Home() {
  const { siteConfig } = useDocusaurusContext();
  return (
    <Layout
      title={`${siteConfig.title}`}
      description="The open-source implementation of an Event Store for Ruby and Rails"
    >
      <main>
        <HomepageHeader />

        <HomepageFeatures />
        <HomepageCompanies />
      </main>
    </Layout>
  );
}
