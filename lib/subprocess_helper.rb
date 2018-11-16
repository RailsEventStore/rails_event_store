require 'childprocess'
require 'tempfile'


module SubprocessHelper
  def run_subprocess(gemfile_path, script)
    gemfile_dirname = File.dirname(gemfile_path)
    FileUtils.rm(File.join(gemfile_dirname, "Gemfile.lock")) if File.exists?(File.join(gemfile_dirname, "Gemfile.lock"))

    process = ChildProcess.build("bundle", "exec", "ruby", script)
    process.environment['BUNDLE_GEMFILE'] = gemfile_path
    process.environment['DATABASE_URL']   = ENV['DATABASE_URL']
    process.environment['RAILS_VERSION']  = ENV['RAILS_VERSION']
    process.cwd = gemfile_dirname
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

  def run_in_subprocess(gemfile_path, code)
    Tempfile.open do |script|
      script.write(code)
      script.close
      run_subprocess(gemfile_path, script.path)
    end
  end
end