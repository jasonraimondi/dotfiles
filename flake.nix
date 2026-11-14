{
  description = "macOS dotfiles, linked into $HOME by Home Manager";

  inputs = {
    # The unstable channel, because the stable one trails Homebrew by months
    # for the command-line tools in nix/packages.nix.
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    prezto = {
      url = "git+https://github.com/sorin-ionescu/prezto?submodules=1";
      flake = false;
    };
    dracula-vim = {
      url = "github:dracula/vim";
      flake = false;
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    let
      # The username, home directory and checkout path differ per machine and
      # this repository is public, so they are read from the environment
      # instead of being committed. Evaluation therefore needs --impure, which
      # setup-home.sh passes.
      homeWith =
        modules:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${builtins.currentSystem};
          extraSpecialArgs = {
            inherit inputs;
            checkout = builtins.getEnv "DOTFILES_HOME";
          };
          modules = [
            {
              home.username = builtins.getEnv "USER";
              home.homeDirectory = builtins.getEnv "HOME";
              home.stateVersion = "26.05";
            }
          ]
          ++ modules;
        };
    in
    {
      homeConfigurations = {
        default = homeWith [
          ./nix/packages.nix
          ./nix/links.nix
          ./nix/skills.nix
        ];
        # Activating a generation with no files removes every link the previous
        # generation created. The packages stay installed.
        unlinked = homeWith [ ./nix/packages.nix ];
      };
    };
}
