require 'spec_helper'
require 'ruby_event_store/deprecated_read_api_rewriter'
require 'ruby_event_store/deprecated_read_api_runner'


module RubyEventStore
  RSpec.describe DeprecatedReadAPIRewriter do
    def rewrite(string)
      parser = Parser::CurrentRuby.new(Astrolabe::Builder.new)
      rewriter = DeprecatedReadAPIRewriter.new
      buffer = Parser::Source::Buffer.new('(string)')
      buffer.source = string
      rewriter.rewrite(buffer, parser.parse(buffer))
    end

    specify { expect(rewrite('client.read_all_streams_forward')).to eq('client.read.limit(100).each.to_a') }

    specify { expect(rewrite('client.read_all_streams_forward(count: 1)')).to eq('client.read.limit(1).each.to_a') }

    specify { expect(rewrite('client.read_all_streams_forward(start: :head)')).to eq('client.read.from(:head).limit(100).each.to_a') }

    specify { expect(rewrite('client.read_all_streams_forward(count: 1, start: :head)')).to eq('client.read.from(:head).limit(1).each.to_a') }

    specify { expect(rewrite('client.read_all_streams_backward')).to eq('client.read.backward.limit(100).each.to_a') }

    specify { expect(rewrite('client.read_all_streams_backward(count: 1)')).to eq('client.read.backward.limit(1).each.to_a') }

    specify { expect(rewrite('client.read_all_streams_backward(start: :head)')).to eq('client.read.backward.from(:head).limit(100).each.to_a') }

    specify { expect(rewrite('client.read_all_streams_backward(count: 1, start: :head)')).to eq('client.read.backward.from(:head).limit(1).each.to_a') }

    specify { expect(rewrite('client.read_events_forward("dummy")')).to eq('client.read.stream("dummy").limit(100).each.to_a') }

    specify { expect(rewrite('client.read_events_forward("dummy", count: 1)')).to eq('client.read.stream("dummy").limit(1).each.to_a') }

    specify { expect(rewrite('client.read_events_forward("dummy", start: :head)')).to eq('client.read.stream("dummy").from(:head).limit(100).each.to_a') }

    specify { expect(rewrite('client.read_events_forward("dummy", count: 1, start: :head)')).to eq('client.read.stream("dummy").from(:head).limit(1).each.to_a') }

    specify { expect(rewrite('client.read_events_backward("dummy")')).to eq('client.read.backward.stream("dummy").limit(100).each.to_a') }

    specify { expect(rewrite('client.read_events_backward("dummy", count: 1)')).to eq('client.read.backward.stream("dummy").limit(1).each.to_a') }

    specify { expect(rewrite('client.read_events_backward("dummy", start: :head)')).to eq('client.read.backward.stream("dummy").from(:head).limit(100).each.to_a') }

    specify { expect(rewrite('client.read_events_backward("dummy", count: 1, start: :head)')).to eq('client.read.backward.stream("dummy").from(:head).limit(1).each.to_a') }

    specify { expect(rewrite('client.read_stream_events_forward("dummy")')).to eq('client.read.stream("dummy").each.to_a') }

    specify { expect(rewrite('client.read_stream_events_backward("dummy")')).to eq('client.read.backward.stream("dummy").each.to_a') }

    specify { expect(rewrite('some_nested_call(client.read_all_streams_forward)')).to eq('some_nested_call(client.read.limit(100).each.to_a)') }

    specify { expect(rewrite('block_call{client.read_all_streams_forward}')).to eq('block_call{client.read.limit(100).each.to_a}') }

    specify { expect(rewrite('client.read_stream_events_forward(name_as_variable)')).to eq('client.read.stream(name_as_variable).each.to_a') }
  end
end