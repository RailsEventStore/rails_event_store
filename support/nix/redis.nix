with import <nixpkgs> {};

mkShell {
  buildInputs = [ redis ];

  shellHook = ''
    set -x

    ${builtins.readFile ./pushtrap.sh}

    # TMP=$(mktemp -d)
    mkdir -p /home/runner/_temp/kakadudu
    TMP=/home/runner/_temp/kakadudu
    SOCKET=$TMP/redis.sock
    PIDFILE=$TMP/redis.pid
    LOGFILE=$TMP/redis.log

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

    set +x
  '';
}
