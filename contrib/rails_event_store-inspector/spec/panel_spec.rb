# frozen_string_literal: true

module RailsEventStore
  module Inspector
    ::RSpec.describe Panel do
      def html_for(entries, links: BrowserLinks.new(nil))
        Panel.new(entries, links).to_fragment
      end

      specify "says so when there is nothing to show" do
        expect(html_for([])).to include("no events yet")
      end

      specify "renders the event type and how long it took" do
        html = html_for([entry(:event, event_id: "e1", event_type: "Ordering::OrderSubmitted", duration: 0.0021)])

        expect(html).to include("Ordering::OrderSubmitted")
        expect(html).to include("2.1 ms")
      end

      specify "counts the handlers that took an event" do
        html =
          html_for(
            [
              entry(:event, event_id: "e1", event_type: "Something"),
              entry(:handler, event_id: "e1", subscriber: "MyHandler"),
              entry(:handler, event_id: "e1", subscriber: "OtherHandler"),
            ],
          )

        expect(html).to include("2 handlers")
      end

      specify "names each handler under its event" do
        html =
          html_for(
            [
              entry(:event, event_id: "e1", event_type: "Something"),
              entry(:handler, event_id: "e1", subscriber: "MyHandler"),
            ],
          )

        expect(html.index("Something")).to be < html.index("MyHandler")
      end

      describe "nesting" do
        specify "a child event hangs under the handler that produced it" do
          html =
            html_for(
              [
                entry(:event, event_id: "parent", event_type: "Parent"),
                entry(:handler, event_id: "parent", subscriber: "MyHandler"),
                entry(:event, event_id: "child", event_type: "Child", causation_id: "parent", producer: "MyHandler"),
              ],
            )

          expect(html.index("MyHandler")).to be < html.index("Child")
        end

        specify "a child whose producer matches no handler hangs under the event itself" do
          html =
            html_for(
              [
                entry(:event, event_id: "parent", event_type: "Parent"),
                entry(:event, event_id: "child", event_type: "Child", causation_id: "parent", producer: "Gone"),
              ],
            )

          expect(html).to include("Child")
        end

        specify "a child is not also listed as a root" do
          html =
            html_for(
              [
                entry(:event, event_id: "parent", event_type: "Parent"),
                entry(:event, event_id: "child", event_type: "Child", causation_id: "parent"),
              ],
            )

          expect(html.scan("Child").size).to eq(1)
        end
      end

      describe "grouping" do
        specify "one group per request" do
          html =
            html_for(
              [
                entry(:event, event_id: "e1", event_type: "First", request_id: "req-aaaaaaaa"),
                entry(:event, event_id: "e2", event_type: "Second", request_id: "req-bbbbbbbb"),
              ],
            )

          expect(html).to include("req req-aaaa", "req req-bbbb")
        end

        specify "stream entries are an index, not a group of their own" do
          html =
            html_for(
              [
                entry(:event, event_id: "e1", event_type: "Something", request_id: "r1"),
                entry(:stream, event_id: "e1", stream: "Ordering::Order$1"),
              ],
            )

          expect(html).not_to include("outside request")
        end
      end

      describe "what did not happen" do
        specify "warns about an event nobody handled" do
          expect(html_for([entry(:event, event_id: "e1", event_type: "Lonely")])).to include("no handlers")
        end

        specify "RES built-ins do not count as somebody handling it" do
          html =
            html_for(
              [
                entry(:event, event_id: "e1", event_type: "Something"),
                entry(:handler, event_id: "e1", subscriber: "RailsEventStore::LinkByEventType", infra: true),
              ],
            )

          expect(html).to include("no handlers")
        end

        specify "an application handler does" do
          html =
            html_for(
              [
                entry(:event, event_id: "e1", event_type: "Something"),
                entry(:handler, event_id: "e1", subscriber: "MyHandler", infra: false),
                entry(:handler, event_id: "e1", subscriber: "RailsEventStore::LinkByEventType", infra: true),
              ],
            )

          expect(html).to include("1 handler")
          expect(html).not_to include("no handlers")
        end

        specify "built-ins collapse into a single dimmed line" do
          html =
            html_for(
              [
                entry(:event, event_id: "e1", event_type: "Something"),
                entry(:handler, event_id: "e1", subscriber: "RailsEventStore::LinkByEventType", infra: true),
                entry(:handler, event_id: "e1", subscriber: "RailsEventStore::LinkByCorrelationId", infra: true),
              ],
            )

          expect(html).to include("2 × RES (LinkByEventType, LinkByCorrelationId)")
        end
      end

      describe "asynchronous handlers" do
        def async_html(enqueued:)
          entries = [
            entry(:event, event_id: "e1", event_type: "Something", request_id: "r1"),
            entry(:handler, event_id: "e1", subscriber: "MailerJob", async: true, request_id: "r1"),
          ]
          entries << entry(:enqueued, job: "MailerJob", request_id: "r1") if enqueued
          html_for(entries)
        end

        specify "confirms the job reached the queue" do
          expect(async_html(enqueued: true)).to include("enqueued")
        end

        specify "flags one that was scheduled but never enqueued" do
          expect(async_html(enqueued: false)).to include("scheduled but never enqueued")
        end

        specify "a job enqueued in another request does not vouch for this one" do
          html =
            html_for(
              [
                entry(:event, event_id: "e1", event_type: "Something", request_id: "r1"),
                entry(:handler, event_id: "e1", subscriber: "MailerJob", async: true, request_id: "r1"),
                entry(:enqueued, job: "MailerJob", request_id: "other-request"),
              ],
            )

          expect(html).to include("scheduled but never enqueued")
        end

        specify "an ordinary handler says nothing about queues" do
          html =
            html_for(
              [
                entry(:event, event_id: "e1", event_type: "Something"),
                entry(:handler, event_id: "e1", subscriber: "MyHandler", async: false),
              ],
            )

          expect(html).not_to include("enqueued")
        end
      end

      describe "links into the Browser" do
        let(:links) { BrowserLinks.new("/res") }

        specify "the event name points at that very event" do
          html = html_for([entry(:event, event_id: "e1", event_type: "Something")], links: links)

          expect(html).to include(%(href="/res/events/e1"))
        end

        specify "the correlated chain is one click away" do
          html = html_for([entry(:event, event_id: "e1", event_type: "X", correlation_id: "c1")], links: links)

          expect(html).to include("/res/streams/%24by_correlation_id_c1")
        end

        specify "a swimlane covers the domain streams of the request" do
          allow(links).to receive(:swimlane_available?).and_return(true)
          html =
            html_for(
              [
                entry(:event, event_id: "e1", event_type: "Something", request_id: "r1"),
                entry(:stream, event_id: "e1", stream: "Ordering::Order$1"),
                entry(:stream, event_id: "e1", stream: "$by_type_Something"),
                entry(:stream, event_id: "e1", stream: "all"),
              ],
              links: links,
            )

          expect(html).to include("swimlane")
          expect(html).to include("streams[]=#{CGI.escape("Ordering::Order$1")}")
          expect(html).not_to include("by_type_Something")
        end
      end

      describe "what goes into an application page" do
        specify "is the shell, not the tree" do
          html = Panel.new([entry(:event, event_id: "e1", event_type: "SomeEvent")]).to_html

          expect(html).to include(%(id="res-inspector-panel"))
          expect(html).not_to include("SomeEvent")
        end

        specify "does not grow with how much has been collected" do
          few = Panel.new(Array.new(1) { |i| entry(:event, event_id: "e#{i}") }).to_html
          many = Panel.new(Array.new(400) { |i| entry(:event, event_id: "e#{i}") }).to_html

          expect(many.bytesize - few.bytesize).to eq(2)
        end
      end

      describe "getting out of the way" do
        specify "starts as a badge, not as a panel over the page" do
          html = Panel.new([]).to_html

          expect(html).to include(%(id="res-inspector-toggle"))
          expect(html).to match(/#res-inspector-panel \{[^}]*display:\s*none/m)
        end

        specify "the badge counts the events, so a closed panel still says something happened" do
          html =
            Panel.new(
              [
                entry(:event, event_id: "e1"),
                entry(:event, event_id: "e2"),
                entry(:handler, event_id: "e1", subscriber: "MyHandler"),
              ],
            ).to_html

          expect(html).to include(%(<span id="res-inspector-count">2</span>))
        end

        specify "opening is a state of the document, so replacing the contents does not close it" do
          html = Panel.new([]).to_html

          expect(html).to match(/html\[data-res-inspector="open"\] #res-inspector-panel \{[^}]*display:\s*block/m)
        end

        specify "the page is pushed aside rather than covered" do
          expect(Panel.new([]).to_html).to match(/html\[data-res-inspector="open"\] body \{[^}]*margin-right/m)
        end
      end

      specify "escapes what the application put in an event type" do
        html = html_for([entry(:event, event_id: "e1", event_type: "<script>alert(1)</script>")])

        expect(html).not_to include("<script>alert(1)")
        expect(html).to include("&lt;script&gt;")
      end
    end
  end
end
