require 'childprocess'
require 'tempfile'


module SubprocessHelper
  def run_subprocess(gemfile_path, script, cwd)
    gemfile_lock_path = gemfile_path + ".lock"
    FileUtils.rm(gemfile_lock_path) if File.exist?(gemfile_lock_path)

    process = ChildProcess.build("bundle", "exec", "ruby", script)
    process.environment['BUNDLE_GEMFILE'] = gemfile_path
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

  def run_in_subprocess(code, gemfile: 'Gemfile.master', cwd: Dir.pwd)
    Tempfile.open do |script|
      script.write(code)
      script.close
      run_subprocess(File.join(__dir__, '../bundler', gemfile), script.path, cwd)
    end
  end
end
