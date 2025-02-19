with import <nixpkgs> {};

mkShell {
  buildInputs = [ postgresql ];

  shellHook = ''
    ${builtins.readFile ./pushtrap.sh}

    TMP=$(mktemp -d)
    DB=$TMP/db
    SOCKET=$TMP

    initdb -D $DB
    pg_ctl -D $DB \
      -l $TMP/logfile \
      -o "--unix_socket_directories='$SOCKET'" \
      -o "--listen_addresses=''\'''\'" \
      start

    createdb -h $SOCKET rails_event_store
    export DATABASE_URL="postgresql:///rails_event_store?host=$SOCKET"

    pushtrap "pg_ctl -D $DB stop; rm -rf $TMP" EXIT
  '';
}
