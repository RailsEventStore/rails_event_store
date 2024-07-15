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
      className="grid px-6 py-8 text-lg font-semibold text-center rounded rounded-lg bg-gray-50 min-h-36 place-content-center"
    >
      {title}
    </li>
  );
}

export default function HomepageFeatures() {
  return (
    <section className="mb-16">
      <header className="container my-12 text--center">
        <h2 className="text-xl">
          <strong>Rails Event Store</strong> is a library for publishing,
          consuming, storing and retrieving events.
        </h2>
        <p className="text-lg">
          It's your best companion for going with&nbsp;an&nbsp;Event-Driven
          Architecture for your Rails application.
        </p>
      </header>
      <ul
        className="container grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3"
      >
        {FeatureList.map((props, idx) => (
          <Feature key={idx} {...props} />
        ))}
      </ul>
    </section>
  );
}
