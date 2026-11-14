{
  config,
  lib,
  pkgs,
  checkout,
  ...
}:
let
  targets = [
    ".claude/skills"
    ".agents/skills"
  ];

  skillsIn =
    directory:
    builtins.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir directory));

  # Skills written or synced in this repository link straight to the checkout,
  # so an edit is live. The checkout is listed rather than the flake source so
  # that a new skill is linked before it is staged in git.
  live =
    package:
    lib.genAttrs (skillsIn "${checkout}/skills/${package}") (
      name: config.lib.file.mkOutOfStoreSymlink "${checkout}/skills/${package}/${name}"
    );

  # Third-party skills are copied into the Nix store with their invocation
  # policy applied there, which leaves the tracked SKILL.md files untouched.
  #   disable  user-invoked only
  #   auto     the model may invoke it
  withPolicy =
    policy: package:
    let
      source = ../skills + "/${package}";
      patched = pkgs.runCommand "skills-${package}" { } ''
        cp -R ${source} $out
        chmod -R u+w $out
        for skill in $out/*/SKILL.md; do
          awk -v policy=${policy} -f ${./skill-invocation-policy.awk} "$skill" > "$skill.patched"
          mv "$skill.patched" "$skill"
        done
      '';
    in
    lib.genAttrs (skillsIn source) (name: "${patched}/${name}");

  packages = [
    (live "personal")
    (live "work")
    (live "vendor-mattpocock")
    (withPolicy "disable" "vendor")
    (withPolicy "auto" "vendor-auto")
  ];

  linkInto =
    target: lib.mapAttrs' (name: source: lib.nameValuePair "${target}/${name}" { inherit source; });
in
{
  # mkMerge, not //, so that a skill name present in two packages is a
  # conflicting definition and fails the build instead of one silently winning.
  home.file = lib.mkMerge (lib.concatMap (target: map (linkInto target) packages) targets);
}
