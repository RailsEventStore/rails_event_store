import Link from "@docusaurus/Link";
import useDocusaurusContext from "@docusaurus/useDocusaurusContext";
import Layout from "@theme/Layout";

import React, { useState, useEffect } from "react";

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
            <h1 className="text-3xl lg:text-4xl">Contributing</h1>
            <p className="text-xl lg:text-2xl">
              A short guide on how to contribute to RailsEventStore organization
              repositories.
            </p>
          </div>
        </header>

        <section className="max-w-2xl px-4 mx-auto">
  


            <h2 id="contributing-to-railseventstore-organization-repositories">
              Contributing to RailsEventStore organization repositories
            </h2>

            <p>Any kind of contribution is welcomed.</p>

            <h2 id="found-a-bug-have-a-question">
              Found a bug? Have a question?
            </h2>

            <ul>
              <li>
                <a href="https://help.github.com/articles/creating-an-issue/">
                  Create a new issue
                </a>
                , assuming one does not already exist.
              </li>
              <li>
                Clearly describe the problem including steps to reproduce when
                it is a bug.
              </li>
              <li>
                If possible provide a Pull Request with failing test case.
              </li>
            </ul>

            <h2 id="prepare-a-pull-request">Prepare a Pull Request</h2>

            <ul>
              <li>
                Fork the{" "}
                <a href="https://github.com/RailsEventStore/rails_event_store">
                  RailsEventStore monorepo
                </a>
              </li>
            </ul>
            <div class="highlight">
              <pre class="syntax-highlight plaintext">
                <code>
                  {" "}
                  git clone git@github.com:RailsEventStore/rails_event_store.git
                  cd rails_event_store
                </code>
              </pre>
            </div>
            <ul>
              <li>
                Make sure you have all latest changes or rebase your forked
                repository master branch with RailsEventStore master branch
              </li>
            </ul>
            <div class="highlight">
              <pre class="syntax-highlight plaintext">
                <code> cd rails_event_store make rebase</code>
              </pre>
            </div>
            <ul>
              <li>Create a pull request branch</li>
            </ul>
            <div class="highlight">
              <pre class="syntax-highlight plaintext">
                <code> git checkout -b new_branch</code>
              </pre>
            </div>
            <ul>
              <li>
                <p>
                  Implement your feature, don't forget about tests &amp;
                  documentation (to see how to work with documentation files
                  check{" "}
                  <a href="https://github.com/RailsEventStore/rails_event_store/blob/master/railseventstore.org/README.md">
                    documentation's readme{" "}
                  </a>
                </p>
              </li>
              <li>
                <p>Make sure your code pass all tests</p>
              </li>
            </ul>
            <div class="highlight">
              <pre class="syntax-highlight plaintext">
                <code> make test</code>
              </pre>
            </div>
            <p>
              You could test each project separately, just enter the project
              folder and run tests (<code>make test</code> again) there.
            </p>

            <ul>
              <li>Make sure your changes survive mutation testing</li>
            </ul>
            <div class="highlight">
              <pre class="syntax-highlight plaintext">
                <code> make mutate</code>
              </pre>
            </div>
            <p>
              Will run mutation tests for all projects. The same command
              executed in specific project's folder will run mutation tests only
              for that project. Mutation tests might be time consuming, so you
              could try to limit the scope of mutations to some specific
              subjects:
            </p>
            <div class="highlight">
              <pre class="syntax-highlight plaintext">
                <code> make mutate SUBJECT=code_to_mutate</code>
              </pre>
            </div>
            <p>
              How to specify <code>code_to_mutate</code> is described in{" "}
              <a href="https://github.com/mbj/mutant#test-selection">
                Mutant documentation
              </a>
              .
            </p>

            <ul>
              <li>
                Don't forget to{" "}
                <a href="https://help.github.com/articles/creating-a-pull-request-from-a-fork/">
                  create a Pull Request
                </a>
                . You could do it even if not everything is ready. The sooner
                you will share your changes the quicker feedback you will get.
              </li>
            </ul>

            <h2 id="license">License</h2>

            <p>
              By contributing, you agree that your contributions will be
              licensed under its{" "}
              <a href="https://github.com/RailsEventStore/rails_event_store/blob/master/LICENSE">
                MIT License
              </a>
              .
            </p>

        </section>
      </main>
    </Layout>
  );
}
