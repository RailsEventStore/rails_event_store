import Layout from "@theme/Layout";
import React from "react";

export default function Billetto() {
  return (
    <Layout>
      <main className="py-10">
        <h1 className="sr-only">RailsEventStore in Billetto</h1>
        <div className="px-4 mx-auto space-y-16  divide-y  text-balance *:pt-16">
          <div className="">
            <a className="block" href="https://billetto.co.uk">
              <img
                className="max-w-[10rem] block w-full mx-auto mb-10"
                src="/images/billetto_logo.svg"
              />
            </a>
            <div className="max-w-2xl px-4 mx-auto text-base md:text-lg ">
              <p className="mb-8">
                Billetto is the leading subculture event marketplace in the
                Nordics and operates in&nbsp;most of the EU countries. It
                connects ticket buyers to indie events and push for cultural
                diversity by promoting subcultures that make us human. The
                Billetto community has grown to 3+&nbsp;million members over the
                last 12&nbsp;years. Billetto is more than just a ticket sales
                tool. It provides users with a fully-kitted platform for ticket
                sales and effortless event advertisement.
              </p>
              <p className="mb-8">
                Rails Event Store has been introduced to the codebase as a tool
                to help integrate with 3rd&nbsp;party systems. After a few
                months successfully running in production the Rails Event Store
                concepts was proven by&nbsp;raising usage of event store and
                acceptance by Billetto team members.
              </p>
            </div>
          </div>
          <div>
            <div className="max-w-5xl mx-auto">
              <h2 className="mb-8 text-2xl font-bold tracking-tight text-center">
                Domains events in time
              </h2>
              <img className="w-full" src="/images/billetto-chart.png" />
            </div>
          </div>

          <div className="py-6 border-t border-gray-200 f first:pb-6 first:pt-4 first:border-0">
            <div className="flex flex-wrap w-full max-w-6xl mx-auto max-w-8xl">
              <div className="w-full mb-8 text-2xl font-bold sm:w-2/5">
                <h2 className="mb-1 text-lg">Some statistics</h2>
                <span className="block text-sm font-bold text-gray-500 uppercase">
                  as for October 2024
                </span>
              </div>
              <div className="w-full text-lg sm:sm:w-3/5">
                <ul className="grid md:grid-cols-2 list-none list-inside gap-4 *:p-4  *:rounded-md *:bg-gray-50 *:border-gray-200 *:!border *:!border-solid">
                  <li>
                    First event published: <strong>November 2014</strong>
                  </li>
                  <li>
                    Current number of events: <strong>876 949 097</strong>
                  </li>
                  <li>
                    Current number of streams: <strong>35 408 173</strong>
                  </li>
                  <li>
                    RES tables size: <strong>~2 TB</strong>
                  </li>
                  <li>
                    Unique number of event types: <strong>932</strong>
                  </li>
                  <li>
                    Event handlers: <strong>547</strong>
                  </li>
                </ul>
              </div>
            </div>
          </div>
          <div>
            <div className="w-full mb-8 text-2xl font-bold text-center">
              <h2>Benefits of RailsEventStore</h2>
            </div>
            <div className="max-w-3xl px-4 mx-auto text-base text-center md:text-lg text-balance">
              <p className="mb-16">
                Implementation of event store, and in more general a event
                centric approach, has enabled Billetto team to embrace
                asynchronous processing, changed the way of thinking about
                building the monolithic system and allowed improvements in
                several areas of the application.
              </p>
            </div>
            <div className="max-w-6xl mx-auto mb-8">
              <dl className="grid gap-6 text-left list-none list-inside md:grid-cols-2 *:bg-gray-50 *:border-gray-200 *:border  *:p-4 *:rounded-md">
                <div>
                  <dt className="mb-2 text-lg font-bold leading-tight tracking-tight">
                    improved performance as significant part of data processing
                    is handled asynchronously
                  </dt>
                  <dd>
                    {" "}
                    results in faster responses to web requests and allowed much
                    higher requests / second processed concurrently
                  </dd>
                </div>
                <div>
                  <dt className="mb-2 text-lg font-bold leading-tight tracking-tight">
                    audit log of user's actions
                  </dt>
                  <dd>
                    by storing facts (domain events) for each change in the
                    system state - allowing not only to debug what happened in
                    this distributed asynchronous system but also business
                    analysis of system state &amp; users behaviour
                  </dd>
                </div>
                <div>
                  <dt className="mb-2 text-lg font-bold leading-tight tracking-tight">
                    simpler &amp; less fragile integration with 3rd party
                    systems
                  </dt>
                  <dd>
                    {" "}
                    allowing the app to operate when some of them are not
                    responding or even automatically switch to fallback system
                    when the primary one is experiencing issues (i.e. payment
                    processors)
                  </dd>
                </div>
                <div>
                  <dt className="mb-2 text-lg font-bold leading-tight tracking-tight">
                    internal &amp; external read models
                  </dt>
                  <dd>
                    {" "}
                    optimised for reads and build asynchronously (with eventual
                    consistency) that allowed tracking of complex calculations
                    results and business metrics almost in real time without
                    additional use on transactional database
                  </dd>
                </div>{" "}
                <div>
                  <dt className="mb-2 text-lg font-bold leading-tight tracking-tight">
                    improved resilience to errors,
                  </dt>
                  <dd>
                    {" "}
                    automatic errors handling mechanisms (i.e. retry with
                    exponential backoff)
                  </dd>
                </div>
              </dl>
            </div>
          </div>
        </div>
      </main>
    </Layout>
  );
}
