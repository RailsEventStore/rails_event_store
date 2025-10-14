# frozen_string_literal: true

require "childprocess"
require "tempfile"

module SubprocessHelper
  def run_subprocess(script, cwd, env, stdout:, stderr:)
    process = ChildProcess.build("ruby", script)
    env.each { |k, v| process.environment[k] = v }
    process.cwd = cwd
    process.io.stdout = stdout if stdout
    process.io.stderr = stderr if stderr
    process.start
    begin
      process.poll_for_exit(10)
    rescue ChildProcess::TimeoutError
      process.stop
    end
    expect(process.exit_code).to eq(0)
  end

  def run_in_subprocess(code, cwd: Dir.pwd, env: {}, stdout: $stdout, stderr: $stderr)
    Tempfile.open do |script|
      script.write(code)
      script.close
      run_subprocess(script.path, cwd, env, stdout:, stderr:) 
    end
  end
end
