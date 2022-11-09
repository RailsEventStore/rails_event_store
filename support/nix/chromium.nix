with import <nixpkgs> {};

mkShell {
  buildInputs = [ chromium ];
}
