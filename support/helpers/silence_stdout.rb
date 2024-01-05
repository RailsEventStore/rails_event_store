# frozen_string_literal: true

module SilenceStdout
  def silence_stdout
    $stdout = StringIO.new
    yield
  ensure
    $stdout = STDOUT
  end
  module_function :silence_stdout
end
