{
  config,
  lib,
  inputs,
  checkout,
  ...
}:
let
  # A link that points at the checkout instead of a copy in the Nix store, so
  # an edit takes effect without a rebuild, apps can write their settings back,
  # and git-ignored files never enter the world-readable store.
  live = path: { source = config.lib.file.mkOutOfStoreSymlink "${checkout}/${path}"; };

  tracked = {
    ".aws" = "aws/dot-aws";

    ".gitconfig" = "git/dot-gitconfig";
    ".gitcommit" = "git/dot-gitcommit";
    ".gitignore" = "git/dot-gitignore";

    ".gnupg/dirmngr.conf" = "gnupg/dirmngr.conf";
    ".gnupg/gpg-agent.conf" = "gnupg/gpg-agent.conf";
    ".gnupg/gpg.conf" = "gnupg/gpg.conf";

    "Library/Spelling/LocalDictionary" = "dictionary/LocalDictionary";

    ".default-gems" = "mise/dot-default-gems";
    ".default-npm-packages" = "mise/dot-default-npm-packages";
    ".default-python-packages" = "mise/dot-default-python-packages";

    ".gemrc" = "ruby/dot-gemrc";
    ".rspec" = "ruby/dot-rspec";

    ".tmux.conf" = "tmux/dot-tmux.conf";
    ".vimrc" = "vim/dot-vimrc";

    ".zshrc" = "zsh/dot-zshrc";
    ".zsh" = "zsh/dot-zsh";
    ".zlogin" = "zprezto/dot-zlogin";
    ".zlogout" = "zprezto/dot-zlogout";
    ".zpreztorc" = "zprezto/dot-zpreztorc";
    ".zprofile" = "zprezto/dot-zprofile";
    ".zshenv" = "zprezto/dot-zshenv";

    # Whole directories: these apps replace their config file on save, which
    # would swap a file link for a regular file.
    ".config/atuin" = "config/atuin";
    ".config/karabiner" = "config/karabiner";
    ".config/mise" = "config/mise";

    # Single entries: the rest of each directory is runtime state that belongs
    # to the app, not to this repository.
    ".config/gh/config.yml" = "config/gh/config.yml";
    ".config/herdr/config.toml" = "config/herdr/config.toml";
    ".config/herdr-app/keys.json" = "config/herdr-app/keys.json";
    ".config/herdr-app/settings.json" = "config/herdr-app/settings.json";
    ".config/herdr-app/layouts/notebook-main.json" = "config/herdr-app/layouts/notebook-main.json";
    ".config/herdr-app/mods/notebook" = "config/herdr-app/mods/notebook";
    ".config/nix/nix.conf" = "config/nix/nix.conf";
    ".config/zed/settings.json" = "config/zed/settings.json";
    ".config/zed/themes" = "config/zed/themes";

    ".claude/settings.json" = "claude/settings.json";
    ".claude/hooks/herdr-tab-title.sh" = "claude/hooks/herdr-tab-title.sh";
    ".pi/agent/settings.json" = "pi/settings.json";
    ".pi/agent/extensions" = "pi/extensions";

    ".claude/CLAUDE.md" = "GLOBAL_AGENTS.md";
    ".config/opencode/AGENTS.md" = "GLOBAL_AGENTS.md";
    ".pi/agent/AGENTS.md" = "GLOBAL_AGENTS.md";
  };

  # Git-ignored, so each exists only on a machine that created it.
  private = {
    ".git-user" = "git/dot-git-user";
    ".git-authors" = "git/dot-git-authors";
    ".ssh/config" = "ssh/config";
  };
  present = lib.filterAttrs (_: path: builtins.pathExists "${checkout}/${path}") private;
in
{
  home.file = lib.mapAttrs (_: live) (tracked // present) // {
    ".zprezto".source = inputs.prezto;
    ".vim/pack/themes/start/dracula".source = inputs.dracula-vim;
  };

  # Home Manager would create these with the default mode when it links into
  # them, and gpg and ssh reject a directory that others can read.
  home.activation.privateDirectories = lib.hm.dag.entryBefore [ "linkGeneration" ] ''
    run install -d -m 700 "$HOME/.gnupg" "$HOME/.ssh"
  '';
}
