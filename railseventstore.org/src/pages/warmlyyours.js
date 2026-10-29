import Layout from "@theme/Layout";
import React from "react";

export default function WarmlyYours() {
  return (
    <Layout>
      <main className="py-10">
        <h1 className="sr-only">RailsEventStore in WarmlyYours</h1>
        <div className="px-4 mx-auto space-y-16  divide-y  text-balance *:pt-16">
          <div className="">
            <div className="flex justify-center">
            <a className="block mb-10" href="https://www.warmlyyours.com">
            <span className="inline-block p-6 rounded-lg bg-white/90">
              <img
                className="max-w-[12rem] block w-full mx-auto "
                src="/images/warmlyyours-logo-red-fktx2n.png"
                alt="WarmlyYours"
              /></span>
            </a></div>
            <div className="max-w-2xl px-4 mx-auto text-base md:text-lg ">
              <p className="mb-8">
                WarmlyYours is a US-based manufacturer and seller of electric
                radiant heating, founded in&nbsp;1999 and headquartered in Lake
                Zurich, Illinois. Its range covers floor heating, snow melting,
                roof and pipe heat tape, towel warmers and infrared panels, sold
                directly online and through a&nbsp;network of trade
                professionals in the US and Canada. Their products have been
                installed in more than 600&nbsp;000&nbsp;homes.
              </p>
              <p className="mb-8">
                WarmlyYours introduced RailsEventStore as a durable pub/sub bus
                for moving side effects out of model callbacks. The usage is
                deliberately focused: primarily per-record streams (with shared
                streams such as inventory where it makes sense), payloads made
                of ids and primitives only, and handlers that re-query the data
                they need.
              </p>
            </div>
          </div>

          <div className="py-6 border-t border-gray-200 f first:pb-6 first:pt-4 first:border-0">
            <div className="flex flex-wrap w-full max-w-6xl mx-auto max-w-8xl">
              <div className="w-full mb-8 text-2xl font-bold sm:w-2/5">
                <h2 className="mb-1 text-lg">Some statistics</h2>
                <span className="block text-sm font-bold text-gray-500 uppercase">
                  as of October 2026
                </span>
              </div>
              <div className="w-full text-lg sm:sm:w-3/5">
                <ul className="grid md:grid-cols-2 list-none list-inside gap-4 *:p-4  *:rounded-md *:bg-white/5 dark:*:ring-white/10 *:ring-[#141414]/10 *:ring-1 ">
                  <li>
                    Retained events: <strong>~947&nbsp;000</strong> (90-day
                    retention)
                  </li>
                  <li>
                    Throughput: <strong>~32&nbsp;600 events per day</strong> (7-day
                    average)
                  </li>
                  <li>
                    Event types: <strong>67</strong>
                  </li>
                  <li>
                    Subscriptions: <strong>89</strong>
                  </li>
                  <li>
                    Event handlers: <strong>89</strong> (67 asynchronous on
                    Sidekiq, 22 synchronous)
                  </li>
                  <li>
                    Stack: <strong>Rails 8.1, PostgreSQL with jsonb, RES 3.2</strong>
                  </li>
                </ul>
              </div>
            </div>
          </div>
          <div>
            <div className="w-full mb-8 text-2xl font-bold text-center">
              <h2>Benefits of RailsEventStore</h2>
            </div>
            <div className="max-w-6xl mx-auto mb-8">
              <dl className="grid gap-6 text-left list-none list-inside md:grid-cols-2 *:p-4  *:rounded-md *:bg-white/5 dark:*:ring-white/10 *:ring-[#141414]/10 *:ring-1">
                <div>
                  <dt className="mb-2 text-lg font-bold leading-tight tracking-tight">
                    Independent reactions to business events
                  </dt>
                  <dd>
                    new behavior can be added without giving more
                    responsibilities to the model where the event originates
                  </dd>
                </div>
                <div>
                  <dt className="mb-2 text-lg font-bold leading-tight tracking-tight">
                    Side effects out of model callbacks
                  </dt>
                  <dd>moved into explicit, testable handlers</dd>
                </div>
                <div>
                  <dt className="mb-2 text-lg font-bold leading-tight tracking-tight">
                    Asynchronous by default, synchronous where it matters
                  </dt>
                  <dd>
                    most work happens in background jobs, while handlers whose
                    result the request has to see stay in-process
                  </dd>
                </div>
                <div>
                  <dt className="mb-2 text-lg font-bold leading-tight tracking-tight">
                    Tracing across asynchronous handlers
                  </dt>
                  <dd>
                    correlation and causation metadata link related events as
                    they flow through the system
                  </dd>
                </div>
                <div>
                  <dt className="mb-2 text-lg font-bold leading-tight tracking-tight">
                    Per-record audit trail
                  </dt>
                  <dd>
                    each record's event stream, read backward, powers an audit
                    page alongside row-version history
                  </dd>
                </div>
                <div>
                  <dt className="mb-2 text-lg font-bold leading-tight tracking-tight">
                    Operational visibility
                  </dt>
                  <dd>
                    RES Browser available to admins, plus daily digests built on
                    reading events by type
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
