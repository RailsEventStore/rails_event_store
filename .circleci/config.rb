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

DATABASE_GEMS = %w[
  rails_event_store_active_record
  ruby_event_store-rom
]

DATATYPE_GEMS = %w[
  ruby_event_store-rom
]

RAILS_VERSIONS = {
  "5.2" => "5.2.4.4",
  "5.1" => "5.1.7",
  "5.0" => "5.0.7.2",
}

DATABASE_URLS = {
  "mysql" => "mysql2://root:secret@127.0.0.1/rails_event_store?pool=5",
  "postgres" => "postgres://postgres:secret@localhost/rails_event_store?pool=5"
}

Docker =
  Struct.new(:image, :environment, :command) do
    def to_h
      super.select { |_, value| value }.transform_keys(&:to_s)
    end
  end

def Postgres(version)
  Docker.new(
    "postgres:#{version}",
    %w[POSTGRES_DB=rails_event_store POSTGRES_PASSWORD=secret],
    "-c max_connections=2000"
  )
end

def MySQL(version)
  Docker.new(
    "mysql:#{version}",
    %w[MYSQL_DATABASE=rails_event_store MYSQL_ROOT_PASSWORD=secret],
    "--default-authentication-plugin=mysql_native_password --max-connections=2000"
  )
end

def Ruby(version, environment=nil)
  Docker.new(
    "railseventstore/ruby:#{version}",
    environment,
    nil
  )
end

def Images(images)
  { "docker" => images.map(&:to_h) }
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

def JobName(task, ruby_version)
  normalize = ->(name) { name.gsub("-", "_").gsub(".", "_") }
  ->(gem_name) do
    [
      task,
      gem_name,
      ruby_version
    ].map(&normalize).join("_")
  end
end

def Test(name, *images)
  ->(gem_name) do
    GemJob(
      "test",
      Images(images),
      gem_name,
      JobName("test", name)[gem_name]
    )
  end
end

def Mutate(name)
  ->(gem_name) do
    GemJob(
      "mutate-incremental",
      Images([Ruby("2.7", "MUTANT_JOBS" => 4)]),
      gem_name,
      JobName("mutate", name)[gem_name]
    )
  end
end

def Merge(array, transform = ->(item) { item })
  array.reduce({}) { |memo, item| memo.merge(transform.(item)) }
end

sqlite3_url =
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
ruby_2_5_compat =
  Merge(
    GEMS,
    ->(gem_name) do
      Test(
        "ruby_2_5",
        Ruby("2.5", "DATABASE_URL" => sqlite3_url[gem_name])
      )[gem_name]
    end
  )
ruby_2_6_compat =
  Merge(
    GEMS,
    ->(gem_name) do
      Test(
        "ruby_2_6",
        Ruby("2.6", "DATABASE_URL" => sqlite3_url[gem_name])
      )[gem_name]
    end
  )
current_ruby =
  Merge(
    GEMS,
    ->(gem_name) do
      Test(
        "ruby_2_7",
        Ruby("2.7", "DATABASE_URL" => sqlite3_url[gem_name])
      )[gem_name]
    end
  )
mutations =
  Merge(
    GEMS,
    Mutate("ruby_2_7")
  )
rails_5_0_compat =
  Merge(
    RAILS_GEMS,
    Test(
      "rails_5_0",
      Ruby("2.7", "RAILS_VERSION" => RAILS_VERSIONS["5.0"])
    )
  )
rails_5_1_compat =
  Merge(
    RAILS_GEMS,
    Test(
      "rails_5_1",
      Ruby("2.7", "RAILS_VERSION" => RAILS_VERSIONS["5.1"])
    )
  )
rails_5_2_compat =
  Merge(
    RAILS_GEMS,
    Test(
      "rails_5_2",
      Ruby("2.7", "RAILS_VERSION" => RAILS_VERSIONS["5.2"])
    )
  )
mysql_5_compat =
  Merge(
    DATABASE_GEMS,
    Test(
      "mysql_5",
      Ruby("2.7", "DATABASE_URL" => DATABASE_URLS["mysql"]),
      MySQL("5")
    )
  )
mysql_8_compat =
  Merge(
    DATABASE_GEMS,
    Test(
      "mysql_8",
      Ruby("2.7", "DATABASE_URL" => DATABASE_URLS["mysql"]),
      MySQL("8")
    )
  )
postgres_11_compat =
  Merge(
    DATABASE_GEMS,
    Test(
      "postgres_11",
      Ruby("2.7", "DATABASE_URL" => DATABASE_URLS["postgres"]),
      Postgres("11")
    )
  )
postgres_12_compat =
  Merge(
    DATABASE_GEMS,
    Test(
      "postgres_12",
      Ruby("2.7", "DATABASE_URL" => DATABASE_URLS["postgres"]),
      Postgres("12")
    )
  )
json_compat =
  Merge(
    DATATYPE_GEMS,
    Test(
      "data_type_json",
      Ruby("2.7", "DATA_TYPE" => "json", "DATABASE_URL" => DATABASE_URLS["postgres"]),
      Postgres("11")
    )
  )
jsonb_compat =
  Merge(
    DATATYPE_GEMS,
    Test(
      "data_type_jsonb",
      Ruby("2.7", "DATA_TYPE" => "jsonb", "DATABASE_URL" => DATABASE_URLS["postgres"]),
      Postgres("11")
    )
  )
jobs =
  [
    check_config,
    mutations,
    current_ruby,
    ruby_2_5_compat,
    ruby_2_6_compat,
    rails_5_0_compat,
    rails_5_1_compat,
    rails_5_2_compat,
    mysql_5_compat,
    mysql_8_compat,
    postgres_11_compat,
    postgres_12_compat,
    json_compat,
    jsonb_compat
  ]
workflows          =
  [
    Workflow(
      "Check configuration",
      %w[check_config]
    ),
    Workflow(
      "Current Ruby",
      GEMS.flat_map do |gem_name|
        Requires(
          JobName("mutate", "ruby_2_7")[gem_name] =>
            JobName("test", "ruby_2_7")[gem_name]
        )
      end
    ),
    Workflow(
      "Ruby 2.5",
      GEMS.map(&JobName("test", "ruby_2_5"))
    ),
    Workflow(
      "Ruby 2.6",
      GEMS.map(&JobName("test", "ruby_2_6"))
    ),
    Workflow(
      "Rails 5.0",
      RAILS_GEMS.map(&JobName("test", "rails_5_0"))
    ),
    Workflow(
      "Rails 5.1",
      RAILS_GEMS.map(&JobName("test", "rails_5_1"))
    ),
    Workflow(
      "Rails 5.2",
      RAILS_GEMS.map(&JobName("test", "rails_5_2"))
    ),
    Workflow(
      "MySQL 5",
      DATABASE_GEMS.map(&JobName("test", "mysql_5"))
    ),
    Workflow(
      "MySQL 8",
      DATABASE_GEMS.map(&JobName("test", "mysql_8"))
    ),
    Workflow(
      "Postgres 11",
      DATABASE_GEMS.map(&JobName("test", "postgres_11"))
    ),
    Workflow(
      "JSONB data type",
      DATATYPE_GEMS.map(&JobName("test", "data_type_json"))
    ),
    Workflow(
      "JSON data type",
      DATATYPE_GEMS.map(&JobName("test", "data_type_jsonb"))
    )
  ]
config =
  Config(
    Merge(jobs),
    Merge(workflows)
  )

File.open(".circleci/config.yml", "w") do |f|
  f << <<~EOS << YAML.dump(config).gsub("---", "")
    # This file is generated by .circleci/config.rb, do not edit it manually!
    # Edit .circleci/config.rb and run ruby .circleci/config.rb
  EOS
end
