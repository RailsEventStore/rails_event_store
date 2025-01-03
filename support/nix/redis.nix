with import <nixpkgs> {};

mkShell {
  buildInputs = [ redis glibcLocales ];

  shellHook = ''
    ${builtins.readFile ./pushtrap.sh}

    LOCALE_ARCHIVE = "${glibcLocales}/lib/locale/locale-archive"
    LANG = "en_US.UTF-8"
    LC_ALL = "en_US.UTF-8"

    mkdir -p /home/runner/_temp/kakadudu
    touch /home/runner/_temp/redis.log

    TMP=/home/runner/_temp/kakadudu
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
