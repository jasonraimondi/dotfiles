{
  config,
  lib,
  pkgs,
  ...
}:
let
  home = config.home.homeDirectory;
  log = "${home}/Library/Logs/herdr-core-serve.log";
in
{
  # A herdr-core daemon started over SSH runs in the Background session, and so
  # does every terminal it spawns: none of them can reach the login keychain or
  # pinentry, so GPG signing and `docker login` fail. Starting it at GUI login
  # keeps it in the Aqua session.
  #
  # Tests activate into throwaway homes, but the launchd domain is per user, so
  # loading the agent there would collide with, or replace, the real one.
  launchd.agents.herdr-core-serve = lib.mkIf (pkgs.stdenv.hostPlatform.isDarwin && builtins.getEnv "DOTFILES_NO_LAUNCHD" == "") {
    enable = true;
    config = {
      ProgramArguments = [
        "${home}/.local/bin/herdr-core"
        "serve"
      ];
      LimitLoadToSessionType = "Aqua";
      RunAtLoad = true;
      KeepAlive = false;
      ProcessType = "Interactive";
      StandardOutPath = log;
      StandardErrorPath = log;
    };
  };
}
