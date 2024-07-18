import Link from "@docusaurus/Link";
import useDocusaurusContext from "@docusaurus/useDocusaurusContext";
import Layout from "@theme/Layout";

import React, { useState, useEffect } from "react";

import getYoutubeId from "../helpers/getYoutubeId";

import appsList from "./data/apps.json";
import articlesList from "./data/articles.json";
import videosList from "./data/videos.json";

export default function Home() {
  const { siteConfig } = useDocusaurusContext();

  const [stats, setStats] = useState({
    stargazers: 0,
    contributors: 0,
    releases: 0,
    downloads: 0,
  });
  const [contributors, setContributors] = useState([]);

  useEffect(() => {
    const fetchData = async () => {
      const repo = "RailsEventStore/rails_event_store";
      const baseUrl = "https://api.github.com/repos/";

      try {
        const [
          stargazersResponse,
          contributorsResponse,
          releasesResponse,
          downloadsResponse,
        ] = await Promise.all([
          fetch(`${baseUrl}${repo}`),
          fetch(`${baseUrl}${repo}/contributors?per_page=100`),
          fetch(`${baseUrl}${repo}/releases?per_page=1&anon=true`),
          fetch(`https://rubygems.org/api/v1/gems/rails_event_store.json`),
        ]);

        const stargazersData = await stargazersResponse.json();
        const contributorsData = await contributorsResponse.json();
        const downloadsData = await downloadsResponse.json();

        const stargazers = stargazersData?.stargazers_count || 0;
        const releases =
          parseInt(
            releasesResponse.headers
              .get("link")
              ?.match(/page=(\d+)>; rel="last"/)[1],
            10
          ) || 0;
        const downloads = downloadsData.downloads || 0;
        setContributors(contributorsData);
        setStats({
          stargazers,
          contributors: contributorsData.length,
          releases,
          downloads,
        });
      } catch (error) {
        console.error(error);
      }
    };

    fetchData();
  }, []);

  return (
    <Layout
      title={`${siteConfig.title}`}
      description="The open-source implementation of an Event Store for Ruby and Rails"
    >
      <main className="pb-24 space-y-20 md:space-y-32">
        <header className="py-8 text-center hero hero--primary">
          <div className="container text-white">
            <h1 className="text-3xl lg:text-4xl">Community</h1>
            <p className="mb-10 text-xl lg:text-2xl">
              Join the Rails Event Store community to collaborate on an
              open-source event store built for Ruby and Rails.
            </p>
            <div className="flex flex-wrap justify-center gap-4">
              <div>
                <ul className="grid grid-cols-2 md:flex m-0 p-0  justify-center gap-4 list-none *:flex *:flex-col *:gap-2 uppercase text-xs">
                  <li className="p-4 bg-red-800 rounded-lg">
                    <span className="text-xl md:text-3xl">
                      {new Intl.NumberFormat("en-US").format(stats.stargazers)}
                    </span>{" "}
                    Stargazers
                  </li>
                  <li className="p-4 bg-red-800 rounded-lg">
                    <span className="text-xl md:text-3xl">
                      {stats.contributors}
                    </span>
                    Contributors
                  </li>
                  <li className="p-4 bg-red-800 rounded-lg">
                    <span className="text-xl md:text-3xl">
                      {stats.releases}
                    </span>
                    Releases
                  </li>
                  <li className="p-4 bg-red-800 rounded-lg">
                    <span className="text-xl md:text-3xl">
                      {new Intl.NumberFormat("en-US").format(stats.downloads)}
                    </span>
                    Downloads
                  </li>
                </ul>
              </div>
            </div>
          </div>
        </header>

        <section className="container">
          <h2 className="mb-5 text-3xl font-bold tracking-tight lg:text-5xl">
            Let's talk
          </h2>
          <p className="mb-8 md:text-xl">
            <a
              className="font-semibold underline"
              target="_blank"
              rel="noopener noreferrer"
              href="https://github.com/RailsEventStore/rails_event_store/discussions"
            >
              GitHub Discussions
            </a>{" "}
            is the best place to post your questions and answers with the
            community. We're also on{" "}
            <a
              className="font-semibold underline"
              target="_blank"
              rel="noopener noreferrer"
              href="https://discord.gg/qjPr9ZBpX6"
            >
              Discord
            </a>{" "}
            for a quick chat and occasional streaming.
          </p>
          <p className="mb-8 md:text-xl">
            Use <strong>#RailsEventStore</strong> on{" "}
            <a
              className="font-semibold underline"
              target="_blank"
              rel="noopener noreferrer"
              href="https://x.com/hashtag/railseventstore"
            >
              X
            </a>{" "}
            and tag <b>rails-event-store</b> on{" "}
            <a
              className="font-semibold underline"
              target="_blank"
              rel="noopener noreferrer"
              href="https://stackoverflow.com/questions/tagged/rails-event-store"
            >
              StackOverflow
            </a>
            .
          </p>
        </section>

        <section className="container">
          <h2 className="mb-5 text-3xl font-bold tracking-tight lg:text-5xl">
            Contribute
          </h2>
          <p className="mb-8 md:text-xl">
            Any kind of contribution is welcomed. See our guide{" "}
            <Link className="font-semibold underline" to="/contributing">
              how to start
            </Link>{" "}
            participating as a contributor.
          </p>

          <ul className="flex flex-wrap justify-start gap-2 p-0 m-0 mb-12 list-none">
            {contributors.map((contributor, key) => (
              <li className="p-0 m-0 group" key={key}>
            <div className="relative rounded-lg  overflow-hidden block before:content-['']  group-hover:before:opacity-0 before:absolute before:inset-0 before:bg-res before:bg-opacity-70  before:mix-blend-hard-light before:z-10 before:block">

                <img className="block size-14 grayscale group-hover:grayscale-0" src={contributor.avatar_url} alt={contributor.login}/>
                </div>
              </li>
            ))}
          </ul>
        </section>

        <section className="container">
          <div className="mb-16">
            <h2 className="mb-5 text-3xl font-bold tracking-tight lg:text-5xl">
              Explore
            </h2>
            <p className="mb-8 md:text-xl">
              Learn how Rails Event Store helps in delivering better software.
              Here are some resources to get you started.
            </p>
          </div>

          <div className="space-y-12 md:space-y-24">
            <section>
              <h3 className="mb-8 text-2xl font-bold tracking-tight md:text-3xl">
                Videos
              </h3>
              <ul className="grid grid-cols-1 gap-6 p-0 m-0 list-none sm:grid-cols-2 md:grid-cols-4 ">
                {videosList.map((video, key) => (
                  <li key={key} className="p-0 m-0 text-base">
                    <a
                      target="_blank"
                      rel="noopener noreferrer"
                      href={video.url}
                      className="flex flex-col justify-center gap-2 font-bold leading-tight text-black hover:text-black dark:text-gray-50 dark:hover:text-gray-50 group"
                    >
                      <div className="relative rounded-lg  overflow-hidden block before:content-[''] max-w-64 md:max-w-max aspect-video group-hover:before:opacity-0 before:absolute before:inset-0 before:bg-res before:bg-opacity-70  before:mix-blend-hard-light before:z-10 before:block">
                        <img
                          className="block w-full grayscale group-hover:grayscale-0 aspect-video"
                          src={`https://img.youtube.com/vi/${getYoutubeId(
                            video.url
                          )}/mqdefault.jpg`}
                          loading="lazy"
                          alt={video.title}
                        />
                      </div>
                      <span className="px-2">{video.title}</span>
                    </a>
                  </li>
                ))}
              </ul>
            </section>
            <section>
              <h3 className="mb-8 text-2xl font-bold tracking-tight md:text-3xl">
                Articles
              </h3>
              <ul className="grid grid-cols-1 gap-2 p-0 m-0 text-sm font-bold list-none gap-x-6 sm:grid-cols-2 ">
                {articlesList.map((article, key) => (
                  <li key={key} className="p-0 m-0">
                    <a
                      className="block w-full min-h-0 p-2 text-base leading-4 text-black md:truncate md:text-lg dark:text-gray-50 "
                      target="_blank"
                      rel="noopener noreferrer"
                      href={article.url}
                    >
                      {article.title}
                    </a>
                  </li>
                ))}
              </ul>
            </section>
            <section>
              <h3 className="mb-8 text-2xl font-bold tracking-tight md:text-3xl">
                Code
              </h3>
              <ul className="grid gap-4 p-0 m-0 list-none sm:grid-cols-2 md:grid-cols-3">
                {appsList.map((app, key) => (
                  <li key={key}>
                    <a
                      className="bg-[#222528] hover:bg-[#141414] p-4 h-full gap-2 text-balance group rounded-lg shadow-md font-mono font-bold !text-[#a3a3a3] !no-underline hover:!text-white flex items-start justify-between"
                      target="_blank"
                      rel="noopener noreferrer"
                      href={app.url}
                    >
                      <span className="block break-all grow-0">
                        {app.title}
                      </span>
                      <img
                        src="/img/github.svg"
                        alt=""
                        className="block opacity-60 group-hover:opacity-100 shrink-0 size-6"
                      />
                    </a>
                  </li>
                ))}
              </ul>
            </section>
          </div>
        </section>
      </main>
    </Layout>
  );
}
