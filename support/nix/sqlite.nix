with import <nixpkgs> {};

mkShell {
  shellHook = ''
    # ROM expectes sqlite://
    export DATABASE_URL=sqlite:db.sqlite3
  '';
}
