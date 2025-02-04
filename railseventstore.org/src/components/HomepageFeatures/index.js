import clsx from "clsx";
import Heading from "@theme/Heading";

const FeatureList = [
  {
    title: "Introduce Publish-Subscribe bus",
  },
  {
    title:
      "Decouple core business logic from external concerns in Hexagonal style architectures",
  },
  {
    title: "Replace ActiveRecord callbacks and Observers",
  },
  {
    title: "Introduce communication layer between loosely coupled components",
  },
  {
    title: "React to published events synchronously or asynchronously",
  },
  {
    title:
      "Extract side-effects from your controllers and services into event handlers",
  },
  {
    title: "Build an Audit Log",
  },
  {
    title: "Introduce Read Models",
  },
  {
    title: "Implement Event Sourcing",
  },
];

function Feature({ Svg, title, description }) {
  return (
    <li
      className="grid px-6 py-8  ring-1 ring-[#141414]/10  dark:bg-[#ededed]/5 dark:ring-white/10  text-lg font-semibold text-center rounded-xl  min-h-36 place-content-center"
    >
      {title}
    </li>
  );
}

export default function HomepageFeatures() {
  return (

    <section className="container my-20 md:mb-32">
      <header className="my-12 text-center ">
        <h2 className="text-2xl font-semibold tracking-tight md:text-3xl">
        Unlock the <span class="font-bold">Full Potential</span> of <span class="font-bold">Event-Driven Rails</span>

        </h2>
      </header>
      <ul
        className="container grid grid-cols-1 gap-8 md:grid-cols-2 lg:grid-cols-3"
      >
        {FeatureList.map((props, idx) => (
          <Feature key={idx} {...props} />
        ))}
      </ul>
    </section>
  );
}
