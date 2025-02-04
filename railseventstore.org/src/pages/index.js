import useDocusaurusContext from "@docusaurus/useDocusaurusContext";
import Layout from "@theme/Layout";
import HomepageFeatures from "@site/src/components/HomepageFeatures";
import HomepageCompanies from "@site/src/components/HomepageCompanies";

function HomepageHeader() {
  return (
    <>
      <div class="container">
        <header class="relative overflow-hidden   md:rounded-3xl mx-auto my-12 md:ring-1 md:bg-gradient-to-tr from-[#ededed]/90 to-[#ededed]/20 ring-[#141414]/5 dark:from-transparent dark:to-transparent  dark:md:bg-white/5 dark:ring-white/10">
          <div class="  backdrop-blur-3xl p-4 md:p-10  lg:p-16  xl:p-32 flex lg:gap-16  xl:gap-24 items-center justify-start ">
            <div class="size-48 shrink-0 hidden ring-1 ring-[#141414]/5  bg-white/95  rounded-full lg:grid place-items-center">
              <img src="/img/logo.svg" alt="RES Logo" class="size-24" />
            </div>
            <div class="max-w-4xl text-left">
              <div class="flex justify-between items-center mb-2 ">
                <h1 class=" text-3xl lg:text-6xl font-bold">Rails Event Store</h1>
              </div>
              <p class="text-xl lg:text-2xl font-medium">
                The open-source event store for Ruby & Rails.
              </p>
              <p class="mt-4 text-lg lg:text-xl">
                A robust library for publishing, consuming, storing, and
                retrieving events. Simplify your event-driven architecture,
                decouple business logic, and gain full control over event flow
                in your application.
              </p>
              <div class="mt-6 flex justify-start gap-4">
                <a
                  href="/docs/getting-started/introduction"
                  class="px-6 py-3 bg-[#CA3A31]  !text-white !no-underline hover:bg-[#ca3a31]/95 rounded-lg font-semibold group"
                >
                  Get Started <span className="inline-block transition-transform transform translate-x-1 group-hover:translate-x-2">&rarr;</span>
                </a>
                <a
                  href="/support"
                  class="px-6 py-3 bg-[#141414] !text-white !no-underline  hover:bg-[#141414]/90  rounded-lg font-semibold group"
                >
                  Get Support  
                </a>
              </div>
            </div>
          </div>
        </header>
      </div>
    </>
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
