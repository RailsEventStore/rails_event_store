{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:

let
  # Fixed ports mirror the DATABASE_URL constants in support/ci/generate,
  # so a DATABASE_URL copied from a CI matrix cell works here 1:1.
  #
  #   postgres 14 -> localhost:10014     mysql 8.4 -> 127.0.0.1:10084
  #   postgres 18 -> localhost:10018     mysql 9.7 -> 127.0.0.1:10097 (see note)
  #
  # MySQL 9.7 (CI's mysql_9_7) is intentionally absent: nixpkgs no longer
  # ships a 9.x/innovation build (mysql80 was removed at EOL). That matrix
  # axis can't be reproduced locally until nixpkgs packages it again.
  postgresInstances = {
    postgres_14 = {
      package = pkgs.postgresql_14;
      port = 10014;
    };
    postgres_18 = {
      package = pkgs.postgresql_18;
      port = 10018;
    };
  };

  mysqlInstances = {
    mysql_8_4 = {
      package = pkgs.mysql84;
      port = 10084;
    };
  };

  mkPostgres =
    name:
    { package, port }:
    {
      exec = ''
        set -euo pipefail
        DATADIR="$DEVENV_STATE/${name}"
        if [ ! -d "$DATADIR" ]; then
          ${package}/bin/initdb -D "$DATADIR" -U postgres --auth=trust >/dev/null
          ${package}/bin/pg_ctl -D "$DATADIR" -w \
            -o "-p ${toString port} -c listen_addresses=127.0.0.1 -c unix_socket_directories=$DATADIR" start
          ${package}/bin/createdb -h 127.0.0.1 -p ${toString port} -U postgres rails_event_store
          ${package}/bin/pg_ctl -D "$DATADIR" -w stop
        fi
        exec ${package}/bin/postgres -D "$DATADIR" \
          -p ${toString port} -c listen_addresses=127.0.0.1 -c unix_socket_directories="$DATADIR"
      '';
    };

  mkMysql =
    name:
    { package, port }:
    {
      exec = ''
        set -euo pipefail
        DATADIR="$DEVENV_STATE/${name}"
        SOCKET="$DEVENV_STATE/${name}.sock"
        if [ ! -d "$DATADIR" ]; then
          ${package}/bin/mysqld --initialize-insecure --datadir="$DATADIR" >/dev/null 2>&1
          ${package}/bin/mysqld --datadir="$DATADIR" --socket="$SOCKET" \
            --port=${toString port} --bind-address=127.0.0.1 &
          pid=$!
          until ${package}/bin/mysqladmin --socket="$SOCKET" ping >/dev/null 2>&1; do sleep 1; done
          ${package}/bin/mysql --socket="$SOCKET" -u root \
            -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'secret';
                CREATE USER 'root'@'127.0.0.1' IDENTIFIED BY 'secret';
                CREATE USER 'root'@'%' IDENTIFIED BY 'secret';
                GRANT ALL PRIVILEGES ON *.* TO 'root'@'127.0.0.1' WITH GRANT OPTION;
                GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
                CREATE DATABASE IF NOT EXISTS rails_event_store;
                FLUSH PRIVILEGES;"
          ${package}/bin/mysqladmin --socket="$SOCKET" -u root -psecret shutdown
          wait "$pid" || true
        fi
        exec ${package}/bin/mysqld --datadir="$DATADIR" --socket="$SOCKET" \
          --port=${toString port} --bind-address=127.0.0.1
      '';
    };

  # Alternate Ruby toolchains for reproducing non-4.0 CI cells. Each gets its
  # own GEM_HOME/BUNDLE_PATH so native extensions never leak across versions.
  altRuby =
    version:
    let
      ruby = inputs.nixpkgs-ruby.packages.${pkgs.system}."ruby-${version}";
    in
    {
      name = "res-ruby-${version}";
      value.exec = ''
        export GEM_HOME="$DEVENV_STATE/gems/${version}"
        export BUNDLE_PATH="$GEM_HOME"
        export PATH="${ruby}/bin:$GEM_HOME/bin:$PATH"
        exec "$@"
      '';
    };

  # Redis over a unix socket (no TCP port), mirroring support/nix/redis.nix so
  # REDIS_URL matches what the outbox/sidekiq suites expect and nothing clashes
  # with a redis already running on the host.
  redisSocket = "${config.devenv.state}/redis.sock";
in
{
  # Same binary cache CI already pushes to (support/ci/generate setup_cachix).
  cachix.pull = [ "railseventstore" ];

  languages.ruby.enable = true;
  languages.ruby.version = "4.0.5";

  packages = with pkgs; [
    # native build deps for pg / mysql2 / sqlite3 gems
    postgresql_18.pg_config
    libmysqlclient
    sqlite
    libyaml
    pkg-config
    # browser gem builds assets through the tailwindcss-ruby gem; node is
    # only needed if you touch raw JS tooling
    nodejs
    redis
    jq
  ];

  env.REDIS_URL = "unix://${redisSocket}";

  processes =
    (lib.mapAttrs' (n: v: lib.nameValuePair n (mkPostgres n v)) postgresInstances)
    // (lib.mapAttrs' (n: v: lib.nameValuePair n (mkMysql n v)) mysqlInstances)
    // {
      redis.exec = ''
        exec ${pkgs.redis}/bin/redis-server --port 0 --unixsocket ${redisSocket} \
          --save "" --appendonly no --protected-mode no
      '';
    };

  scripts = {
    # Reproduce one CI matrix cell without pasting a DATABASE_URL: maps a short
    # database name to the same URL support/ci/generate uses, sets DATA_TYPE and
    # runs the command. Compose with res-ruby-<version> for the Ruby axis:
    #   res-ruby-3.4 res-cell pg14 jsonb make test-ruby_event_store-active_record
    res-cell.exec = ''
      set -euo pipefail
      db="''${1:?usage: res-cell <sqlite|pg14|pg18|mysql84> <data_type> <command...>}"
      data_type="''${2:?usage: res-cell <sqlite|pg14|pg18|mysql84> <data_type> <command...>}"
      shift 2
      case "$db" in
        sqlite)  url="sqlite3:db.sqlite3" ;;
        pg14)    url="postgres://postgres:secret@localhost:10014/rails_event_store" ;;
        pg18)    url="postgres://postgres:secret@localhost:10018/rails_event_store" ;;
        mysql84) url="mysql2://root:secret@127.0.0.1:10084/rails_event_store" ;;
        *) echo "res-cell: unknown db '$db' (sqlite|pg14|pg18|mysql84)" >&2; exit 1 ;;
      esac
      exec env DATABASE_URL="$url" DATA_TYPE="$data_type" "$@"
    '';
  }
  // lib.listToAttrs (map altRuby [
    "3.3"
    "3.4"
  ]);

  enterShell = ''
    echo "rails_event_store dev shell (Ruby $(ruby -v | cut -d' ' -f2))"
    echo "Run 'devenv up' to start databases, then e.g.:"
    echo "  make test-ruby_event_store-active_record"
    echo "Databases (match support/ci/generate DATABASE_URLs):"
    echo "  postgres 14  postgres://postgres:secret@localhost:10014/rails_event_store"
    echo "  postgres 18  postgres://postgres:secret@localhost:10018/rails_event_store"
    echo "  mysql 8.4    mysql2://root:secret@127.0.0.1:10084/rails_event_store"
    echo "  redis        $REDIS_URL"
    echo "Reproduce a CI cell: res-cell pg14 jsonb make test-ruby_event_store-active_record"
    echo "Other Ruby versions: res-ruby-3.4 <command>"
  '';
}
