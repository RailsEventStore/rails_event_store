pushtrap () {
  test "$traps" || trap 'set +eu; eval $traps' 0;
  traps="$*; $traps"
}

