with import <nixpkgs> {};

mkShell {
  buildInputs = [ redis glibcLocales ];

  shellHook = ''
    ${builtins.readFile ./pushtrap.sh}

    LOCALE_ARCHIVE = "${glibcLocales}/lib/locale/locale-archive"
    LANG = "en_US.UTF-8"
    LC_ALL = "en_US.UTF-8"

    TMP=$(mktemp -d)
    SOCKET=$TMP/redis.sock
    PIDFILE=$TMP/redis.pid

    redis-server \
      --protected-mode no \
      --port 0 \
      --unixsocket $SOCKET \
      --save "" \
      --daemonize yes \
      --pidfile $PIDFILE

    export REDIS_URL="unix://$SOCKET"

    pushtrap "kill -9 $(cat $PIDFILE);rm -rf $TMP" EXIT
  '';
}
