{ pkgs, ... }:
{
  home.file = {
    ".oh-my-zsh".source = "${pkgs.oh-my-zsh}/share/oh-my-zsh";
    ".config/zsh/custom/plugins/zsh-autosuggestions".source =
      "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions";
    ".config/zsh/custom/plugins/fast-syntax-highlighting".source =
      "${pkgs.zsh-fast-syntax-highlighting}/share/zsh/plugins/fast-syntax-highlighting";
  };
}
