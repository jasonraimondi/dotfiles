{ lib, pkgs, ... }:
{
  dotfiles.links = {
    # Whole directories: these apps replace their config file on save, which
    # would swap a file link for a regular file.
    ".config/atuin" = "config/atuin";
    ".config/mise" = "config/mise";

    ".config/herdr/config.toml" = "config/herdr/config.toml";
    ".config/herdr-app/keys.json" = "config/herdr-app/keys.json";
    ".config/herdr-app/settings.json" = "config/herdr-app/settings.json";
    ".config/herdr-app/layouts/notebook-main.json" = "config/herdr-app/layouts/notebook-main.json";
    ".config/herdr-app/mods/notebook" = "config/herdr-app/mods/notebook";
    ".config/zed/settings.json" = "config/zed/settings.json";
    ".config/zed/themes" = "config/zed/themes";

    ".claude/settings.json" = "claude/settings.json";
    ".claude/hooks/herdr-tab-title.sh" = "claude/hooks/herdr-tab-title.sh";
    ".pi/agent/settings.json" = "pi/settings.json";
    ".pi/agent/extensions" = "pi/extensions";
  }
  // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
    "Library/Spelling/LocalDictionary" = "dictionary/LocalDictionary";
    ".config/karabiner" = "config/karabiner";
  };
}
