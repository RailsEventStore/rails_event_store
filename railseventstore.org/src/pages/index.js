import useDocusaurusContext from "@docusaurus/useDocusaurusContext";
import Layout from "@theme/Layout";
import HomepageFeatures from "@site/src/components/HomepageFeatures";
import HomepageCompanies from "@site/src/components/HomepageCompanies";
import getYoutubeId from "@site/src/helpers/getYoutubeId";

const RES_CAMP_2026_VIDEO_URL = "https://www.youtube.com/watch?v=tF9cQVk1OKY";

function HomepageVideoPromo() {
  const youtubeId = getYoutubeId(RES_CAMP_2026_VIDEO_URL);
  return (
    <div class="container">
      <a
        href={RES_CAMP_2026_VIDEO_URL}
        target="_blank"
        rel="noopener noreferrer"
        class="relative overflow-hidden md:rounded-3xl mx-auto mb-12 md:ring-1 md:bg-gradient-to-tr from-[#ededed]/90 to-[#ededed]/20 ring-[#141414]/5 dark:from-transparent dark:to-transparent dark:md:bg-white/5 dark:ring-white/10 flex flex-col md:flex-row items-center gap-6 p-4 md:p-8 !no-underline group"
      >
        <div class="relative w-full md:w-80 shrink-0 rounded-xl overflow-hidden aspect-video">
          <img
            src={`https://img.youtube.com/vi/${youtubeId}/hqdefault.jpg`}
            alt="RES Camp 2026"
            loading="lazy"
            class="block w-full h-full object-cover"
          />
          <div class="absolute inset-0 grid place-items-center bg-black/30 group-hover:bg-black/40 transition-colors">
            <div class="size-14 rounded-full bg-[#CA3A31] grid place-items-center shadow-lg">
              <svg viewBox="0 0 24 24" class="size-6 fill-white ml-1">
                <path d="M8 5v14l11-7z" />
              </svg>
            </div>
          </div>
        </div>
        <div class="text-left">
          <span class="inline-block mb-2 text-xs font-semibold uppercase tracking-wide text-[#CA3A31]">
            RES Camp 2026
          </span>
          <h2 class="text-xl lg:text-2xl font-bold !text-[#141414] dark:!text-white mb-2">
            What's next for Rails Event Store, straight from the people
            building it
          </h2>
          <p class="text-base lg:text-lg !text-[#141414]/70 dark:!text-white/70">
            Watch the recap and see the ideas, decisions, and changes headed
            into the next releases.
          </p>
        </div>
      </a>
    </div>
  );
}

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
        <HomepageVideoPromo />
        <HomepageFeatures />
        <HomepageCompanies />
      </main>
    </Layout>
  );
}
