{
  description = "Jontyms's personal blog";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    # Import theme
    stack = {
      url = github:adityatelange/hugo-PaperMod;
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, stack }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        blog = pkgs.stdenv.mkDerivation {
          name = "blog";
          # Exclude themes and public folder from build sources
          src = builtins.filterSource
            (path: type: !(type == "directory" &&
              (baseNameOf path == "themes" ||
                baseNameOf path == "public")))
            ./.;
          # Link theme to themes folder and build
          buildPhase = ''
            mkdir -p themes
            ln -s ${stack} themes/PaperMod
            ${pkgs.hugo}/bin/hugo --minify
          '';
          installPhase = ''
            cp -r public $out
          '';
          meta = with pkgs.lib; {
            description = "Jontyms's personal blog";
            platforms = platforms.all;
          };
        };
      in
      {
        packages = {
          blog = blog;
          default = blog;
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [ hugo ];
          # Link theme to themes folder
          shellHook = ''
            mkdir -p themes
            ln -sf ${stack} themes/PaperMod
          '';
        };
      });
}
