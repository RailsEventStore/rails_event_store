require 'bounded_context'
require 'pp'
require 'fakefs/safe'

module StdoutHelper
  def silence_stdout(&block)
    $stdout = StringIO.new
    block.call
    $stdout = STDOUT
  end
end

module GeneratorHelper
  include StdoutHelper

  def destination_root
    File.join(__dir__, 'dummy')
  end

  def run_generator(generator_args)
    silence_stdout { ::BoundedContext::Module.start(generator_args, destination_root: destination_root) }
  end
end

RSpec.configure do |config|
  config.include GeneratorHelper

  config.around(:each) do |example|
    FakeFS.with_fresh do
      FakeFS::FileSystem.clone(File.join(__dir__, '../'))
      example.call
    end
  end
end