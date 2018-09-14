require 'parser/current'
require 'unparser'
require 'ruby_event_store'


module RubyEventStore
  class DeprecatedReadAPIRewriter < ::Parser::TreeRewriter
    DEPRECATED_READER_METHODS = [
      :read_all_streams_backward,
      :read_events_backward,
      :read_stream_events_backward,
      :read_all_streams_forward,
      :read_events_forward,
      :read_stream_events_forward
    ]
    private_constant :DEPRECATED_READER_METHODS

    def on_send(node)
      node.each_descendant(:send) { |desc_node| on_send(desc_node) }

      _, method_name, *args = node.children
      return unless DEPRECATED_READER_METHODS.include?(method_name)
      replace_range = node.location.selector
      replace_range = replace_range.join(node.location.end) if node.location.end

      case method_name
      when :read_all_streams_backward, :read_events_backward
        rewrite_api("read.backward", replace_range, **parse_args(args))
      when :read_stream_events_backward
        rewrite_api("read.backward", replace_range, count: nil, **parse_args(args))
      when :read_all_streams_forward, :read_events_forward
        rewrite_api("read", replace_range, **parse_args(args))
      when :read_stream_events_forward
        rewrite_api("read", replace_range, count: nil, **parse_args(args))
      end
    end

    def rewrite_api(query, range, start: nil, count: PAGE_SIZE, stream: nil)
      query << ".stream(#{stream})" if stream
      query << ".from(#{start})" if start
      query << ".limit(#{count})" if count

      replace(range, "#{query}.each.to_a")
    end

    def parse_args(args)
      return {} if args.empty?

      case args.size
      when 1
        case args[0].type
        when :hash
          stream_name, kwargs = nil, args[0]
        else
          stream_name, kwargs = parse_value(args[0]), AST::Node.new(:hash)
        end
      else
        stream_name, kwargs = parse_value(args[0]), args[1]
      end

      kwargs
        .children
        .reduce({stream: stream_name}) do |memo, pair|
        keyword, value = pair.children
        memo[parse_keyword(keyword)] = parse_value(value)
        memo
      end
    end

    def parse_value(node)
      Unparser.unparse(node)
    end

    def parse_keyword(node)
      node.children[0].to_sym
    end
  end
end
