require 'parser/runner'
require 'tempfile'
require 'astrolabe/builder'


module RubyEventStore
  class DeprecatedReadAPIRunner < Parser::Runner
    attr_reader :rewriter, :parser_class, :modify

    def initialize
      super
      @rewriter = DeprecatedReadAPIRewriter.new
    end

    def runner_name
      "res-deprecated-read-api-migrator"
    end

    def setup_option_parsing(opts)
      super(opts)

      opts.on '-m', '--modify' do
        @modify = true
      end
    end

    def process(buffer)
      parser = parser_class.new(Astrolabe::Builder.new)
      new_source = rewriter.rewrite(buffer, parser.parse(buffer))
      new_buffer = Parser::Source::Buffer.new(buffer.name + '|after res-deprecated-read-api-migrator')
      new_buffer.source = new_source

      if !modify
        old = Tempfile.new('old')
        old.write(buffer.source + "\n")
        old.flush

        new = Tempfile.new('new')
        new.write(new_source + "\n")
        new.flush

        IO.popen("diff -u #{old.path} #{new.path}") do |io|
          $stderr.write(
            io.read
              .sub(/^---.*/, "--- #{buffer.name}")
              .sub(/^\+\+\+.*/, "+++ #{new_buffer.name}")
          )
        end
        exit(1)
      end

      if File.exist?(buffer.name)
        File.open(buffer.name, 'w') do |file|
          file.write(new_source)
        end
      else
        if input_size > 1
          puts "Rewritten content of #{buffer.name}:"
        end
        puts new_source
      end
    end
  end
end