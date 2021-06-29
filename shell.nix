let

  sources = import ./nix/sources.nix;
  pkgs    = import sources.nixpkgs {};

  commands = import ./nix/commands.nix;
  tasks    = commands { pkgs = pkgs; };
  yarn     = pkgs.yarn.override { nodejs = pkgs.nodejs-16_x; };

  yarn = pkgs.yarn.override { nodejs = pkgs.nodejs-16_x; };

  deps = {
    elm = [
      pkgs.elmPackages.elm
      pkgs.elmPackages.elm-format
    ];

    node = [
      yarn
    ];
  };

in

  pkgs.mkShell {
    nativeBuildInputs = builtins.concatLists [
      deps.elm
      deps.node

      tasks
    ];
  }
