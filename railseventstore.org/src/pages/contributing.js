import useDocusaurusContext from "@docusaurus/useDocusaurusContext";
import Layout from "@theme/Layout";

import React from "react";

export default function Contributing() {
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

        <div className="max-w-5xl  text-balance px-4 mx-auto divide-y divide-gray-200  dark:divide-gray-800 lg:px-8 xl:px-12 divide-solid *:!border-x-0 *:py-12">
          <div className="flex flex-wrap flex-col gap-4">
            <div className="w-full text-2xl font-bold">
              <h2 className="mb-1.5">Contributing to RailsEventStore organization repositories</h2>
              <span className="block text-base font-bold text-gray-500 uppercase">
                Any kind of contribution is welcomed.
              </span>
            </div>
            <div className="w-full text-xl">
              <h2 id="found-a-bug-have-a-question" className="font-semibold mb-2">Found a bug? Have a question?</h2>
              <ul>
                <li className="py-2 list-disc">
                  <a href="https://help.github.com/articles/creating-an-issue/">Create a new issue</a>
                  , assuming one does not already exist.
                </li>
                <li className="py-2 list-disc">Clearly describe the problem including steps to reproduce when it is a bug.</li>
                <li className="py-2 list-disc">If possible provide a Pull Request with failing test case.</li>
              </ul>
            </div>
            <div className="w-full text-xl ">
              <h2 id="prepare-a-pull-request" className="font-semibold mb-2">Prepare a Pull Request</h2>
              <ul>
                <li className="py-2 list-disc">
                  Fork the{" "}
                  <a href="https://github.com/RailsEventStore/rails_event_store">RailsEventStore monorepo</a>
                </li>
              </ul>
              <div className="highlight text-base py-2">
                <pre className="syntax-highlight text-base plaintext">
                  <code>
                    {" "}
                    git clone git@github.com:RailsEventStore/rails_event_store.git cd rails_event_store
                  </code>
                </pre>
              </div>
              <ul>
                <li className="py-2 list-disc">Make sure you have all latest changes or rebase your forked repository master branch with RailsEventStore master branch</li>
              </ul>
              <div className="highlight text-base py-2">
                <pre className="syntax-highlight text-base plaintext">
                  <code> cd rails_event_store make rebase</code>
                </pre>
              </div>
              <ul>
                <li className="py-2 list-disc">Create a pull request branch</li>
              </ul>
              <div className="highlight text-base py-2">
                <pre className="syntax-highlight text-base plaintext">
                  <code> git checkout -b new_branch</code>
                </pre>
              </div>
              <ul>
                <li className="py-2 list-disc">
                  <p>
                    Implement your feature, don&#x27;t forget about tests &amp; documentation (to see how to work with documentation files check{" "}
                    <a href="https://github.com/RailsEventStore/rails_event_store/blob/master/railseventstore.org/README.md">
                      documentation&#x27;s readme{" "}
                    </a>
                  </p>
                </li>
                <li className="py-2 list-disc">
                  <p>Make sure your code pass all tests</p>
                </li>
              </ul>
              <div className="highlight text-base py-2">
                <pre className="syntax-highlight text-base plaintext">
                  <code> make test</code>
                </pre>
              </div>
              <p>
                You could test each project separately, just enter the project folder and run tests (
                <code>make test</code>{" "}
                again) there.
              </p>
              <ul>
                <li className="py-2 list-disc">Make sure your changes survive mutation testing</li>
              </ul>
              <div className="highlight text-base py-2">
                <pre className="syntax-highlight text-base plaintext">
                  <code> make mutate</code>
                </pre>
              </div>
              <p>Will run mutation tests for all projects. The same command executed in specific project&#x27;s folder will run mutation tests only for that project. Mutation tests might be time consuming, so you could try to limit the scope of mutations to some specific subjects:</p>
              <div className="highlight text-base py-2">
                <pre className="syntax-highlight text-base plaintext">
                  <code> make mutate SUBJECT=code_to_mutate</code>
                </pre>
              </div>
              <p>
                How to specify{" "}
                <code>code_to_mutate</code>
                {" "}is described in{" "}
                <a href="https://github.com/mbj/mutant#test-selection">Mutant documentation</a>
                .
              </p>
              <ul>
                <li className="py-2 list-disc">
                  Don&#x27;t forget to{" "}
                  <a href="https://help.github.com/articles/creating-a-pull-request-from-a-fork/">create a Pull Request</a>
                  . You could do it even if not everything is ready. The sooner you will share your changes the quicker feedback you will get.
                </li>
              </ul>
            </div>
          </div>
          <div className="flex flex-wrap flex-col gap-2">
            <div className="w-full text-2xl font-bold">
              <h2 className="mb-1.5">License</h2>
            </div>
            <div className="w-full text-xl">
              <p className="mb-8">
                By contributing, you agree that your contributions will be
                licensed under its{" "}
                <a href="https://github.com/RailsEventStore/rails_event_store/blob/master/LICENSE">
                  MIT License
                </a>
                .
              </p>
            </div>
          </div>
        </div>
      </main>
    </Layout>
  );
}
