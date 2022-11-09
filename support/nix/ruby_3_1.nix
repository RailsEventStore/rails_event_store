with import <nixpkgs> { };

mkShell {
  buildInputs = let
    gems = (g: with g; [ nokogiri sqlite3 pg mysql2 ]);
  in [ (ruby_3_1.withPackages gems) ];
}
