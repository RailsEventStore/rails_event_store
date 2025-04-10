import useDocusaurusContext from "@docusaurus/useDocusaurusContext";
import Layout from "@theme/Layout";

import React, { useState, useEffect } from "react";

export default function Support() {
  const { siteConfig } = useDocusaurusContext();

  return (
    <Layout
      title={`${siteConfig.title}`}
      description="The open-source implementation of an Event Store for Ruby and Rails"
    >
      <main className="pb-24 space-y-12 md:space-y-16">
        <header className="py-16 text-center hero hero--primary">
          <div className="container text-white">
            <h1 className="text-3xl lg:text-4xl">Support</h1>
            <p className="text-xl lg:text-2xl">
              Where to find support for Rails Event Store challenges
            </p>
          </div>
        </header>

        <div className="max-w-5xl  text-balance px-4 mx-auto divide-y divide-gray-200  dark:divide-gray-800 lg:px-8 xl:px-12 divide-solid *:!border-x-0 *:py-12 prose prose-lg dark:prose-invert">
          <div className="flex flex-wrap ">
            <div className="w-full text-2xl font-bold sm:w-2/5">
              <h2 className="my-1.5">Community Help</h2>
              <span className="block text-base font-bold text-gray-500 uppercase">
                Free
              </span>
            </div>
            <div className="w-full text-xl sm:sm:w-3/5">
              <p className="mt-1.5 mb-8">
                Rails Event Store has an active{" "}
                <a href="/community">community</a> of awesome contributors. They
                report encountered issues, propose and discuss possible
                improvements. Share what they've learned on blogs, meetups,
                conferences and strive to keep documentation comprehensive,
                up-to-date and on point.
              </p>
                <a
                  href="/community"
                  className="inline-block px-2 py-1.5 text-xs font-bold tracking-tight !no-underline hover:bg-red-700 !text-white uppercase rounded-md bg-[#CA3A31]"
                >
                  Learn more
                </a>
            </div>
          </div>
          <div className="flex flex-wrap">
            <div className="w-full text-2xl font-bold sm:w-2/5">
              <h2 className="my-1.5">Domain-Driven Rails</h2>
              <span className="block text-base font-bold text-gray-500 uppercase">
                Starting from $49
              </span>
            </div>
            <div className="w-full text-xl sm:sm:w-3/5">
              <p className="mt-1.5 mb-8">
                Struggling with complex Rails app and business domain?
                Domain-Driven Rails will help you:
              </p>
              <blockquote className="pl-4 mb-8 text-lg font-medium border-l-4">
                <p className="">
                  For a few years we’ve been studying Domain-Driven Design and
                  applying its techniques in our projects. In Domain-Driven
                  Rails we describe 11 techniques that you can use separately
                  and together in new and old Rails apps to achieve better
                  architecture. They were useful to us and we are sure they are
                  going to be useful for you and your complex apps.
                </p>
              </blockquote>
              <a
                href="https://blog.arkency.com/domain-driven-rails/"
                className="inline-block px-2 py-1.5 text-xs font-bold tracking-tight !no-underline hover:bg-red-700 !text-white uppercase rounded-md bg-[#CA3A31]"
                >
                Learn more
              </a>
            </div>
          </div>
          <div className="flex flex-wrap">
            <div className="w-full text-2xl font-bold sm:w-2/5">
              <h2 className="my-1.5">Arkademy Subscription</h2>
              <span className="block text-base font-bold text-gray-500 uppercase">
                $49 / month
              </span>
            </div>
            <div className="w-full text-xl sm:sm:w-3/5">
              <p className="mt-1.5 mb-8">
                Get access to Rails Architect Masterclass, Domain-Driven Rails
                video course, Anti-IF course, TDD video class and more. Get in
                touch with fellow students and instructors on Discord.
              </p>
              <p className="mt-1.5 mb-8">
                On Arkademy you will learn everything about DDD, Backend
                Architecture, UI Architecture Styles and Testing.
              </p>
              <a
                href="https://arkademy.dev"
                className="inline-block px-2 py-1.5 text-xs font-bold tracking-tight !no-underline hover:bg-red-700 !text-white uppercase rounded-md bg-[#CA3A31]"
                >
                Join now
              </a>
            </div>
          </div>
          <div className="flex flex-wrap">
            <div className="w-full text-2xl font-bold sm:w-2/5">
              <h2 className="my-1.5">Rails Event Store Mentoring</h2>
              <span className="block text-base font-bold text-gray-500 uppercase">
                $2,000 / month
              </span>
            </div>
            <div className="w-full text-xl sm:sm:w-3/5">
              <p className="mt-1.5 mb-8">
                3–month mentoring focused on initial development — first year of
                your project. Package includes code review and questions and
                answers calls every two weeks.
              </p>
              <a
                href="mailto:res@arkency.com"
                className="inline-block px-2 py-1.5 text-xs font-bold tracking-tight !no-underline hover:bg-red-700 !text-white uppercase rounded-md bg-[#CA3A31]"
                >
                Get in touch
              </a>
            </div>
          </div>
          <div className="flex flex-wrap">
            <div className="w-full text-2xl font-bold sm:w-2/5">
              <h2 className="my-1.5">Custom Feature Development</h2>
              <span className="block text-base font-bold text-gray-500 uppercase">
                Ask for quote
              </span>
            </div>
            <div className="w-full text-xl sm:sm:w-3/5">
              <p className="mt-1.5 mb-8">
                You ask for a missing Rails Event Store feature, we give you a
                fixed-price offer.
              </p>
              <a
                href="mailto:res@arkency.com"
                className="inline-block px-2 py-1.5 text-xs font-bold tracking-tight !no-underline hover:bg-red-700 !text-white uppercase rounded-md bg-[#CA3A31]"
                >
                Get in touch
              </a>
            </div>
          </div>
          <div className="flex flex-wrap">
            <div className="w-full text-2xl font-bold sm:w-2/5">
              <h2 className="my-1.5">One-shot Help</h2>
              <span className="block text-base font-bold text-gray-500 uppercase">
                Ask for quote
              </span>
            </div>
            <div className="w-full text-xl sm:sm:w-3/5">
              <p className="mt-1.5 mb-8">
                You're stuck with Rails Event Store — we can help. Price depends
                on the speed of our availability — we can fix something for you
                in a week or month.
              </p>
              <a
                href="mailto:res@arkency.com"
                className="inline-block px-2 py-1.5 text-xs font-bold tracking-tight !no-underline hover:bg-red-700 !text-white uppercase rounded-md bg-[#CA3A31]"
                >
                Get in touch
              </a>
            </div>
          </div>
          <div className="flex flex-wrap">
            <div className="w-full text-2xl font-bold sm:w-2/5">
              <h2 className="my-1.5">Legacy Rails/DDD Mentoring</h2>
              <span className="block text-base font-bold text-gray-500 uppercase">
                Ask for quote
              </span>
            </div>
            <div className="w-full text-xl sm:sm:w-3/5">
              <p className="mt-1.5 mb-8">
                6–month mentoring focused on existing apps — older than 2 years.
                Package includes code review and questions and answers calls
                every two weeks.
              </p>
              <a
                href="mailto:res@arkency.com"
                className="inline-block px-2 py-1.5 text-xs font-bold tracking-tight !no-underline hover:bg-red-700 !text-white uppercase rounded-md bg-[#CA3A31]"
                >
                Get in touch
              </a>
            </div>
          </div>
          <div className="flex flex-wrap">
            <div className="w-full text-2xl font-bold sm:w-2/5">
              <h2 className="leading-tight my-1.5">From Event Storming to an App</h2>
              <span className="block text-base font-bold text-gray-500 uppercase">
                Ask for quote
              </span>
            </div>
            <div className="w-full text-xl sm:sm:w-3/5">
              <p className="mt-1.5 mb-8">
                2–days workshop in your office or in Wrocław, Poland. 1st day
                consists on an Event Storming session on your domain and
                bootstraping an application. 2nd day focused on{" "}
                <a href="https://en.wikipedia.org/wiki/Mob_programming">
                  mob programming
                </a>{" "}
                of a Rails application with Rails Event Store — implementing
                disovered Domain Events, Commands and Aggregates.
              </p>
              <a
                href="mailto:res@arkency.com"
                className="inline-block px-2 py-1.5 text-xs font-bold tracking-tight !no-underline hover:bg-red-700 !text-white uppercase rounded-md bg-[#CA3A31]"
                >
                Get in touch
              </a>
            </div>
          </div>
          <div className="flex flex-wrap">
            <div className="w-full text-2xl font-bold sm:w-2/5">
              <h2 className="my-1.5">Rails DDD Workshop</h2>
              <span className="block text-base font-bold text-gray-500 uppercase">
                Ask for quote
              </span>
            </div>
            <div className="w-full text-xl sm:sm:w-3/5">
              <p className="mt-1.5 mb-8">
                2-days workshop focused on DDD foundations and building blocks.
                Open for public or for your company only.
              </p>
              <a
                href="https://blog.arkency.com/ddd-training/"
                className="inline-block px-2 py-1.5 text-xs font-bold tracking-tight !no-underline hover:bg-red-700 !text-white uppercase rounded-md bg-[#CA3A31]"
                >
                Learn More
              </a>
            </div>
          </div>
          <div className="flex flex-wrap">
            <div className="w-full text-2xl font-bold sm:w-2/5">
              <h2 className="my-1.5">Full time help from Arkency</h2>
              <span className="block text-base font-bold text-gray-500 uppercase">
                Ask for quote
              </span>
            </div>
            <div className="w-full text-xl sm:sm:w-3/5">
              <p className="mt-1.5 mb-8">
                Minimum 2 experienced remote developers from Arkency on
                short-term or long-term contract.
              </p>
              <a
                href="mailto:res@arkency.com"
                className="inline-block px-2 py-1.5 text-xs font-bold tracking-tight !no-underline hover:bg-red-700 !text-white uppercase rounded-md bg-[#CA3A31]"
                >
                Get in touch
              </a>
            </div>
          </div>
        </div>
      </main>
    </Layout>
  );
}
