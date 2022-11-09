with import <nixpkgs> {};

mkShell {
  shellHook = ''
    # ActiveRecord expects sqlite3://
    export DATABASE_URL=sqlite3:db.sqlite3
  '';
}
