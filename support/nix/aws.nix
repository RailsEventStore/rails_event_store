with import <nixpkgs> {};

mkShell {
  buildInputs = [ awscli2 ];
}
