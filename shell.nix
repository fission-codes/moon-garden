let

  sources = import ./nix/sources.nix;
  pkgs    = import sources.nixpkgs {};

  commands = import ./nix/commands.nix;
  tasks = commands {pkgs = pkgs;};

  deps = {
    tools = [
      pkgs.curl
      pkgs.devd
      pkgs.just
      pkgs.watchexec
    ];

    elm = [
      pkgs.elmPackages.elm
      pkgs.elmPackages.elm-format
      pkgs.elmPackages.elm-live
    ];

    node = [
      pkgs.nodejs-14_x
      pkgs.nodePackages.pnpm
    ];
  };

in

  pkgs.mkShell {
    nativeBuildInputs = builtins.concatLists [
      deps.tools
      deps.elm
      deps.node
      tasks
    ];
  }
