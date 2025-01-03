with import <nixpkgs> {};

mkShell {
  buildInputs = [ redis ];

  shellHook = ''
    ${builtins.readFile ./pushtrap.sh}

    TMP=$(mktemp -d)
    SOCKET=$TMP/redis.sock
    PIDFILE=$TMP/redis.pid
    LOGFILE=/home/runner/_temp/redis.log

    redis-server \
      --protected-mode no \
      --port 0 \
      --unixsocket $SOCKET \
      --save "" \
      --daemonize yes \
      --pidfile $PIDFILE \
      --loglevel verbose \
      --logfile $LOGFILE

    export REDIS_URL="unix://$SOCKET"

    pushtrap "kill -9 $(cat $PIDFILE);rm -rf $TMP" EXIT
  '';
}
