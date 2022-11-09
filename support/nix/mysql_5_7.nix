with import <nixpkgs> {};

let
  pkgs = import (builtins.fetchGit {
    name = "mysql-5.7.37";
    url = "https://github.com/NixOS/nixpkgs/";
    ref = "refs/heads/nixos-22.05";
    rev = "7d7622909a38a46415dd146ec046fdc0f3309f44";
  }) {};
  mysql57 = pkgs.mysql57;
in
mkShell {
  packages = [ mysql57 ];

  shellHook = ''
    ${builtins.readFile ./pushtrap.sh}

    TMP=$(mktemp -d)
    DB=$TMP/db
    SOCKET=$TMP/mysql.sock
    PIDFILE=$TMP/mysql.pid

    mkdir -p $DB
    mysqld \
      --basedir=${mysql57} \
      --datadir=$DB \
      --pid-file=$PIDFILE \
      --socket=$SOCKET \
      --initialize-insecure
    mysqld \
      --datadir=$DB \
      --pid-file=$PIDFILE \
      --socket=$SOCKET \
      --skip-networking \
      --log-error \
      --daemonize
    mysqladmin -u root --socket=$SOCKET create rails_event_store

    export DATABASE_URL="mysql2:///rails_event_store?socket=$SOCKET&username=root"

    pushtrap "mysqladmin -u root --socket=$SOCKET shutdown; rm -rf $TMP" EXIT
  '';
}
