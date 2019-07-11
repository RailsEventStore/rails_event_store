require "yaml"

GEMS = %w[
  aggregate_root
  bounded_context
  ruby_event_store
  ruby_event_store-browser
  ruby_event_store-rom
  rails_event_store
  rails_event_store_active_record
  rails_event_store-rspec
]

RAILS_GEMS = %w[
  bounded_context
  rails_event_store
  rails_event_store_active_record
  rails_event_store-rspec
]

RDBMS_GEMS = %w[
  rails_event_store_active_record
  ruby_event_store-rom
]

DATATYPE_GEMS = %w[
  ruby_event_store-rom
]

def Config(jobs, workflows)
  {
    "version" => "2.1",
    "jobs" => jobs,
    "workflows" => {
      "version" => "2"
    }.merge(workflows)
  }
end

def Run(command)
  { "run" => command }
end

def NamedRun(name, command)
  { "run" => { "name" => name, "command" => command } }
end

def Workflow(name, jobs)
  { name => { "jobs" => jobs } }
end

def Requires(dependencies)
  dependencies.flat_map do |dependent, required|
    [required, { dependent => { "requires" => Array(required) } }]
  end
end

def Docker(image, environment = {})
  docker = { "image" => image }
  docker = { "environment" => environment }.merge(docker) unless environment.empty?
  {
    "docker" => [
      docker,
      { "image" => "postgres:11", "environment" => %w(POSTGRES_DB=rails_event_store POSTGRES_PASSWORD=secret), "command" => "-c max_connections=2000" },
      { "image" => "mysql:8", "environment" => %w(MYSQL_DATABASE=rails_event_store MYSQL_ROOT_PASSWORD=secret), "command" => "--default-authentication-plugin=mysql_native_password --max-connections=2000" }
    ]
  }
end

def Job(name, docker, steps)
  { name => docker.merge("steps" => steps) }
end

def GemJob(task, docker, gem_name, name)
  Job(name, docker, ["checkout", Run("make -C #{gem_name} install #{task}")])
end

database_url =
  ->(gem_name) do
    case gem_name
    when /active_record/
      "sqlite3:db.sqlite3"
    when /rom/
      "sqlite:db.sqlite3"
    else
      "sqlite3::memory:"
    end
  end
identity = ->(item) { item }
normalize = ->(name) { name.gsub("-", "_").gsub(".", "_") }
merge = ->(array, transform = identity) { array.reduce({}) { |memo, item| memo.merge(transform.(item)) } }
mutate = ->(name, gem_name) { GemJob('mutate', Docker('railseventstore/ruby:2.6', { 'MUTANT_JOBS' => 4 }), gem_name, name) }
test = ->(docker, name, gem_name) { GemJob('test', docker, gem_name, name) }
job_name = ->(task, ruby_version, gem_name) { [task, gem_name, ruby_version].map(&normalize).join('_') }

check_config =
  Job(
    "check_config",
    Docker("railseventstore/ruby:2.6"),
    [
      "checkout",
      NamedRun(
        "Verify .circleci/config.yml is generated from .circleci/config.rb",
        %Q[WAS="$(md5sum .circleci/config.yml)" && ruby .circleci/config.rb && test "$WAS" == "$(md5sum .circleci/config.yml)"]
      )
    ]
  )

ruby_2_4_compat = merge.(GEMS, ->(gem_name) { test.(Docker("railseventstore/ruby:2.4", { "DATABASE_URL" => database_url[gem_name] }), job_name.curry['test', 'ruby_2_4'][gem_name], gem_name) })
ruby_2_5_compat = merge.(GEMS, ->(gem_name) { test.(Docker("railseventstore/ruby:2.5", { "DATABASE_URL" => database_url[gem_name] }), job_name.curry['test', 'ruby_2_5'][gem_name], gem_name) })
current_ruby = merge.(GEMS, ->(gem_name) { test.(Docker("railseventstore/ruby:2.6", { "DATABASE_URL" => database_url[gem_name] }), job_name.curry['test', 'ruby_2_6'][gem_name], gem_name) })
mutations = merge.(GEMS, ->(gem_name) { mutate.(job_name.curry['mutate', 'ruby_2_6'][gem_name], gem_name) })
rails_4_2_compat = merge.(RAILS_GEMS, ->(gem_name) { test.(Docker("railseventstore/ruby:2.5", { "RAILS_VERSION" => "4.2.11" }), job_name.curry['test', 'rails_4_2'][gem_name], gem_name) })
rails_5_0_compat = merge.(RAILS_GEMS, ->(gem_name) { test.(Docker("railseventstore/ruby:2.5", { "RAILS_VERSION" => "5.0.7" }), job_name.curry['test', 'rails_5_0'][gem_name], gem_name) })
rails_5_1_compat = merge.(RAILS_GEMS, ->(gem_name) { test.(Docker("railseventstore/ruby:2.5", { "RAILS_VERSION" => "5.1.6.1" }), job_name.curry['test', 'rails_5_1'][gem_name], gem_name) })
rails_6_0_compat = merge.(RAILS_GEMS, ->(gem_name) { test.(Docker("railseventstore/ruby:2.5", { "RAILS_VERSION" => "6.0.0.rc1" }), job_name.curry['test', 'rails_6_0'][gem_name], gem_name) })
mysql_compat = merge.(RDBMS_GEMS, ->(gem_name) { test.(Docker("railseventstore/ruby:2.6", { "DATABASE_URL" => "mysql2://root:secret@127.0.0.1/rails_event_store?pool=5" }), job_name.curry['test', 'mysql'][gem_name], gem_name) })
postgres_compat = merge.(RDBMS_GEMS, ->(gem_name) { test.(Docker("railseventstore/ruby:2.6", { "DATABASE_URL" => "postgres://postgres:secret@localhost/rails_event_store?pool=5" }), job_name.curry['test', 'postgres'][gem_name], gem_name) })
json_compat = merge.(DATATYPE_GEMS, ->(gem_name) { test.(Docker("railseventstore/ruby:2.6", { "DATA_TYPE" => "json", "DATABASE_URL" => "postgres://postgres:secret@localhost/rails_event_store?pool=5" }), job_name.curry['test', 'data_type_json'][gem_name], gem_name) })
jsonb_compat = merge.(DATATYPE_GEMS, ->(gem_name) { test.(Docker("railseventstore/ruby:2.6", { "DATA_TYPE" => "jsonb", "DATABASE_URL" => "postgres://postgres:secret@localhost/rails_event_store?pool=5" }), job_name.curry['test', 'data_type_jsonb'][gem_name], gem_name) })

jobs = [
  check_config,
  mutations,
  current_ruby,
  ruby_2_4_compat,
  ruby_2_5_compat,
  rails_4_2_compat,
  rails_5_0_compat,
  rails_5_1_compat,
  rails_6_0_compat,
  mysql_compat,
  postgres_compat,
  json_compat,
  jsonb_compat
]
workflows =
  [
    Workflow("Check configuration", %w[check_config]),
    Workflow("Current Ruby", GEMS.flat_map { |gem_name|
      Requires(job_name.curry['mutate', 'ruby_2_6'][gem_name] => job_name.curry['test', 'ruby_2_6'][gem_name])
    }),
    Workflow("Ruby 2.5", GEMS.map(&job_name.curry['test', 'ruby_2_5'])),
    Workflow("Ruby 2.4", GEMS.map(&job_name.curry['test', 'ruby_2_4'])),
    Workflow("Rails 4.2", RAILS_GEMS.map(&job_name.curry['test', 'rails_4_2'])),
    Workflow("Rails 5.0", RAILS_GEMS.map(&job_name.curry['test', 'rails_5_0'])),
    Workflow("Rails 5.1", RAILS_GEMS.map(&job_name.curry['test', 'rails_5_1'])),
    Workflow("Rails 6.0", RAILS_GEMS.map(&job_name.curry['test', 'rails_6_0'])),
    Workflow("MySQL", RDBMS_GEMS.map(&job_name.curry['test', 'mysql'])),
    Workflow("PostgreSQL", RDBMS_GEMS.map(&job_name.curry['test', 'postgres'])),
    Workflow("JSONB data type", DATATYPE_GEMS.map(&job_name.curry['test', 'data_type_json'])),
    Workflow("JSON data type", DATATYPE_GEMS.map(&job_name.curry['test', 'data_type_jsonb']))
  ]

File.open(".circleci/config.yml", "w") do |f|
  f << <<~EOS << YAML.dump(Config(merge[jobs], merge[workflows])).gsub("---", "")
    # This file is generated by .circleci/config.rb, do not edit it manually!
    # Edit .circleci/config.rb and run ruby .circleci/config.rb
  EOS
end
