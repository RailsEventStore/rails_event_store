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

Docker =
  Struct.new(:image, :environment, :command) do
    def to_h
      super.select { |_, value| value }.transform_keys(&:to_s)
    end
  end

class Postgres
  def initialize(version)
    @docker =
      Docker.new(
        "postgres:#{version}",
        %w[POSTGRES_DB=rails_event_store POSTGRES_PASSWORD=secret],
        "-c max_connections=2000"
      )
  end

  def to_h
    @docker.to_h
  end
end

def Postgres(version)
  Postgres.new(version).to_h
end

class MySQL
  def initialize(version)
    @docker =
      Docker.new(
        "mysql:#{version}",
        %w[MYSQL_DATABASE=rails_event_store MYSQL_ROOT_PASSWORD=secret],
        "--default-authentication-plugin=mysql_native_password --max-connections=2000"
      )
  end

  def to_h
    @docker.to_h
  end
end

def MySQL(version)
  MySQL.new(version).to_h
end

class Ruby
  def initialize(version, environment)
    @docker = Docker.new("railseventstore/ruby:#{version}", environment, nil)
  end

  def to_h
    @docker.to_h
  end
end

def Ruby(version, environment = nil)
  Ruby.new(version, environment).to_h
end

Images =
  Struct.new(:images) do
    def to_h
      { "docker" => images }
    end
  end

def Images(images)
  Images.new(images).to_h
end

def Config(jobs, workflows)
  {
    "version" => "2.1",
    "jobs" => jobs,
    "workflows" => { "version" => "2" }.merge(workflows)
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

def Job(name, docker, steps)
  { name => docker.merge("steps" => steps) }
end

def GemJob(task, docker, gem_name, name)
  Job(name, docker, ["checkout", Run("make -C #{gem_name} install #{task}")])
end

normalize =
  ->(name) do
    name.gsub("-", "_").gsub(".", "_")
  end
merge =
  ->(array, transform = ->(item) { item }) do
    array.reduce({}) { |memo, item| memo.merge(transform.(item)) }
  end
job_name =
  ->(task, ruby_version, gem_name) do
   [
     task,
     gem_name,
     ruby_version
   ].map(&normalize).join("_")
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
mutate =
  ->(name, gem_name) do
    GemJob(
      "mutate",
      Images([Ruby("2.6", "MUTANT_JOBS" => 4)]),
      gem_name,
      name
    )
  end
test =
  ->(images, name, gem_name) do
    GemJob(
      "test",
      images,
      gem_name,
      name
    )
  end
check_config =
  Job(
    "check_config",
    Images([Ruby("2.7")]),
    [
      "checkout",
      NamedRun(
        "Verify .circleci/config.yml is generated from .circleci/config.rb",
        %Q[WAS="$(md5sum .circleci/config.yml)" && ruby .circleci/config.rb && test "$WAS" == "$(md5sum .circleci/config.yml)"]
      )
    ]
  )
ruby_2_4_compat =
  merge.(
    GEMS,
    ->(gem_name) do
      test.(
        Images([Ruby("2.4", "DATABASE_URL" => database_url[gem_name])]),
        job_name.curry["test", "ruby_2_4"][gem_name],
        gem_name
      )
    end
  )
ruby_2_5_compat =
  merge.(
    GEMS,
    ->(gem_name) do
      test.(
        Images([Ruby("2.5", "DATABASE_URL" => database_url[gem_name])]),
        job_name.curry["test", "ruby_2_5"][gem_name],
        gem_name
      )
    end
  )
ruby_2_6_compat =
  merge.(
    GEMS,
    ->(gem_name) do
      test.(
        Images([Ruby("2.6", "DATABASE_URL" => database_url[gem_name])]),
        job_name.curry["test", "ruby_2_6"][gem_name],
        gem_name
      )
    end
  )
current_ruby =
  merge.(
    GEMS,
    ->(gem_name) do
      test.(
        Images([Ruby("2.7", "DATABASE_URL" => database_url[gem_name])]),
        job_name.curry["test", "ruby_2_7"][gem_name],
        gem_name
      )
    end
  )
mutations =
  merge.(
    GEMS,
    ->(gem_name) do
      mutate.(job_name.curry["mutate", "ruby_2_6"][gem_name], gem_name)
    end
  )
rails_4_2_compat =
  merge.(
    RAILS_GEMS,
    ->(gem_name) do
      test.(
        Images([Ruby("2.6", "RAILS_VERSION" => "4.2.11.1")]),
        job_name.curry["test", "rails_4_2"][gem_name],
        gem_name
      )
    end
  )
rails_5_0_compat =
  merge.(
    RAILS_GEMS,
    ->(gem_name) do
      test.(
        Images([Ruby("2.7", "RAILS_VERSION" => "5.0.7.2")]),
        job_name.curry["test", "rails_5_0"][gem_name],
        gem_name
      )
    end
  )
rails_5_1_compat =
  merge.(
    RAILS_GEMS,
    ->(gem_name) do
      test.(
        Images([Ruby("2.7", "RAILS_VERSION" => "5.1.7")]),
        job_name.curry["test", "rails_5_1"][gem_name],
        gem_name
      )
    end
  )
rails_5_2_compat =
  merge.(
    RAILS_GEMS,
    ->(gem_name) do
      test.(
        Images([Ruby("2.7", "RAILS_VERSION" => "5.2.4.1")]),
        job_name.curry["test", "rails_5_2"][gem_name],
        gem_name
      )
    end
  )
mysql_8_compat =
  merge.(
    RDBMS_GEMS,
    ->(gem_name) do
      test.(
        Images([
          Ruby(
            "2.7",
            "DATABASE_URL" =>
              "mysql2://root:secret@127.0.0.1/rails_event_store?pool=5"
          ),
          MySQL("8")
        ]),
        job_name.curry["test", "mysql_8"][gem_name],
        gem_name
      )
    end
  )
postgres_11_compat =
  merge.(
    RDBMS_GEMS,
    ->(gem_name) do
      test.(
        Images([
          Ruby(
            "2.7",
            "DATABASE_URL" =>
              "postgres://postgres:secret@localhost/rails_event_store?pool=5"
          ),
          Postgres("11"),
        ]),
        job_name.curry["test", "postgres_11"][gem_name],
        gem_name
      )
    end
  )
json_compat =
  merge.(
    DATATYPE_GEMS,
    ->(gem_name) do
      test.(
        Images([
          Ruby(
            "2.7",
            "DATA_TYPE" => "json",
            "DATABASE_URL" =>
              "postgres://postgres:secret@localhost/rails_event_store?pool=5"
          ),
          Postgres("11")
        ]),
        job_name.curry["test", "data_type_json"][gem_name],
        gem_name
      )
    end
  )
jsonb_compat =
  merge.(
    DATATYPE_GEMS,
    ->(gem_name) do
      test.(
        Images([
          Ruby(
            "2.7",
            "DATA_TYPE" => "jsonb",
            "DATABASE_URL" =>
              "postgres://postgres:secret@localhost/rails_event_store?pool=5"
          ),
          Postgres("11"),
        ]),
        job_name.curry["test", "data_type_jsonb"][gem_name],
        gem_name
      )
    end
  )
jobs =
  [
    check_config,
    mutations,
    current_ruby,
    ruby_2_4_compat,
    ruby_2_5_compat,
    ruby_2_6_compat,
    rails_4_2_compat,
    rails_5_0_compat,
    rails_5_1_compat,
    rails_5_2_compat,
    mysql_8_compat,
    postgres_11_compat,
    json_compat,
    jsonb_compat
  ]
workflows =
  [
    Workflow("Check configuration", %w[check_config]),
    Workflow(
      "Current Ruby",
      GEMS.flat_map do |gem_name|
        Requires(
          job_name.curry["mutate", "ruby_2_6"][gem_name] =>
            job_name.curry["test", "ruby_2_7"][gem_name]
        )
      end
    ),
    Workflow("Ruby 2.4", GEMS.map(&job_name.curry["test", "ruby_2_4"])),
    Workflow("Ruby 2.5", GEMS.map(&job_name.curry["test", "ruby_2_5"])),
    Workflow("Ruby 2.6", GEMS.map(&job_name.curry["test", "ruby_2_6"])),
    Workflow("Rails 4.2", RAILS_GEMS.map(&job_name.curry["test", "rails_4_2"])),
    Workflow("Rails 5.0", RAILS_GEMS.map(&job_name.curry["test", "rails_5_0"])),
    Workflow("Rails 5.1", RAILS_GEMS.map(&job_name.curry["test", "rails_5_1"])),
    Workflow("Rails 5.2", RAILS_GEMS.map(&job_name.curry["test", "rails_5_2"])),
    Workflow("MySQL 8", RDBMS_GEMS.map(&job_name.curry["test", "mysql_8"])),
    Workflow("Postgres 11", RDBMS_GEMS.map(&job_name.curry["test", "postgres_11"])),
    Workflow(
      "JSONB data type",
      DATATYPE_GEMS.map(&job_name.curry["test", "data_type_json"])
    ),
    Workflow(
      "JSON data type",
      DATATYPE_GEMS.map(&job_name.curry["test", "data_type_jsonb"])
    )
  ]

File.open(".circleci/config.yml", "w") do |f|
  f << <<~EOS << YAML.dump(Config(merge[jobs], merge[workflows])).gsub("---", "")
    # This file is generated by .circleci/config.rb, do not edit it manually!
    # Edit .circleci/config.rb and run ruby .circleci/config.rb
  EOS
end
