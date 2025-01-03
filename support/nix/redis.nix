with import <nixpkgs> {};

mkShell {
  buildInputs = [ redis ];

  shellHook = ''
    ${builtins.readFile ./pushtrap.sh}

    LANG=C
    LC_ALL=C

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
