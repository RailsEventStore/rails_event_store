require 'bounded_context'

module StdoutHelper
  def silence_stdout(&block)
    $stdout = StringIO.new
    block.call
    $stdout = STDOUT
  end
end

module GeneratorHelper
  include StdoutHelper

  def dummy_app_root
    File.join(__dir__, 'dummy')
  end

  def tmp_root
    File.join(__dir__, 'tmp')
  end

  def run_generator(generator_args)
    silence_stdout { ::BoundedContext::Generators::Module.start(generator_args, destination_root: tmp_root) }
  end
end

RSpec.configure do |config|
  config.include GeneratorHelper

  config.around(:each) do |example|
    begin
      FileUtils.mkdir_p(tmp_root)
      FileUtils.cp_r("#{dummy_app_root}/.", tmp_root)
      example.call
    ensure
      FileUtils.rm_rf(tmp_root)
    end
  end
end
