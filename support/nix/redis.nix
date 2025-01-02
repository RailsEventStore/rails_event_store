with import <nixpkgs> {};

mkShell {
  buildInputs = [ redis ];

  shellHook = ''
    ${builtins.readFile ./pushtrap.sh}

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

    if [ $? -eq 0 ]; then
      echo "Redis server started successfully."
      export REDIS_URL="unix://$SOCKET"
    else
      echo "Failed to start Redis server. Check logs or permissions."
      exit 1
    fi

    if [ ! -f "$PIDFILE" ]; then
      echo "Redis PID file not found. Starting failed?"
      exit 1
    fi

    pushtrap "if [ -f $PIDFILE ]; then kill -9 $(cat $PIDFILE); fi; rm -rf $TMP" EXIT
  '';
}
