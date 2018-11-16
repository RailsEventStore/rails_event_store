require 'childprocess'

module SubprocessHelper
  def run_subprocess(cwd, script)
    cwd = Pathname.new(cwd)
    FileUtils.rm(cwd.join("Gemfile.lock")) if cwd.join("Gemfile.lock").exist?
    process = ChildProcess.build("bundle", "exec", "ruby", script)
    process.environment['BUNDLE_GEMFILE'] = cwd.join('Gemfile')
    process.environment['DATABASE_URL']   = ENV['DATABASE_URL']
    process.environment['RAILS_VERSION']  = ENV['RAILS_VERSION']
    process.cwd = cwd
    process.io.stdout = $stdout
    process.io.stderr = $stderr
    process.start
    begin
      process.poll_for_exit(10)
    rescue ChildProcess::TimeoutError
      process.stop
    end
    expect(process.exit_code).to eq(0)
  end
end