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
      --pidfile $PIDFILE \
      --loglevel verbose

    export REDIS_URL="unix://$SOCKET"

    ls -la /home/runner/work/_temp

    env | grep REDIS

    pushtrap "kill -9 $(cat $PIDFILE);rm -rf $TMP" EXIT
  '';
}
