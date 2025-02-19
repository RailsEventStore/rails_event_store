with import <nixpkgs> {};

mkShell {
  packages = [ mysql84 ];

  shellHook = ''
    ${builtins.readFile ./pushtrap.sh}

    TMP=$(mktemp -d)
    DB=$TMP/db
    SOCKET=$TMP/mysql.sock
    PIDFILE=$TMP/mysql.pid

    mkdir -p $DB
    mysqld \
      --basedir=${mysql80} \
      --datadir=$DB \
      --pid-file=$PIDFILE \
      --socket=$SOCKET \
      --initialize-insecure
    mysqld \
      --datadir=$DB \
      --pid-file=$PIDFILE \
      --socket=$SOCKET \
      --skip-networking \
      --skip-mysqlx \
      --daemonize
    mysqladmin -u root --socket=$SOCKET create rails_event_store

    export DATABASE_URL="mysql2:///rails_event_store?socket=$SOCKET&username=root"

    pushtrap "mysqladmin -u root --socket=$SOCKET shutdown; rm -rf $TMP" EXIT
  '';
}
