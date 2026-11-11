{
  config,
  lib,
  repoDir,
  ...
}:
let
  link = path: config.lib.file.mkOutOfStoreSymlink "${repoDir}/configs/${path}";
in
{
  home.file = {
    ".config/git".source = link "git";
    ".config/k9s".source = link "k9s";
    ".config/ghostty".source = link "ghostty";
    ".config/nvim".source = link "nvim";
    ".config/pip".source = link "package-managers/pip";
    ".config/uv".source = link "package-managers/uv";
    ".npmrc".source = link "package-managers/npm/.npmrc";
    ".config/pnpm/config.yaml".source = link "package-managers/pnpm/config.yaml";
    ".yarnrc".source = link "package-managers/yarn/.yarnrc";
    ".config/mise".source = link "package-managers/mise";
    ".zshrc".source = link "zsh/.zshrc";
    ".config/zsh/functions".source = link "zsh/functions";
    ".gnupg/gpg.conf".source = link "gnupg/gpg.conf";
    ".gnupg/gpg-agent.conf".source = link "gnupg/gpg-agent.conf";
    ".gnupg/common.conf".source = link "gnupg/common.conf";
    ".claude/settings.json".source = link "claude/settings.json";
    ".claude/CLAUDE.md".source = link "claude/AGENTS.md";
    ".claude/hooks".source = link "claude/hooks";
  };

  home.activation.gnupgPermissions = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run chmod 700 "$HOME/.gnupg"
  '';
}
