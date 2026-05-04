# modules/nixos/desktop/fonts.nix
#
# System-level fonts. Available to every user and to system
# services (printing, PDF rendering, etc.).
#
# - Noto + Noto CJK + Noto Color Emoji: broad Unicode coverage
#   so missing glyphs don't render as boxes.
# - Liberation: metric-compatible substitutes for Microsoft's
#   Arial/Times/Courier — keeps documents and web pages styled
#   with those fonts looking right.
# - JetBrains Mono Nerd Font: monospace + powerline/icon glyphs
#   for terminals, editors, and the Niri/Noctalia status bar.
# - Inter: modern proportional UI font; Noctalia and many GTK
#   apps look noticeably better with it as the default.
#
# fontconfig.defaultFonts sets the fallback chain that apps
# query when they ask for "monospace", "sans-serif", "serif".

{ pkgs, ... }:

{
  fonts = {
    # Pull in NixOS's curated default font set (DejaVu, Freefont,
    # etc.) in addition to the explicit list below. Without this,
    # apps that hardcode references to common defaults can fail
    # to find them.
    enableDefaultPackages = true;

    # The actual font packages installed system-wide.
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      liberation_ttf
      inter
      nerd-fonts.jetbrains-mono
    ];

    # ─── Fontconfig defaults ────────────────────────────────────────
    # When an app requests "monospace" / "sans-serif" / "serif"
    # generically, fontconfig walks this list in order and uses
    # the first available match. The fallback to Noto Color Emoji
    # at the end of each list ensures emoji render in any text.
    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [
          "JetBrainsMono Nerd Font"
          "Noto Sans Mono"
          "Noto Color Emoji"
        ];
        sansSerif = [
          "Inter"
          "Noto Sans"
          "Noto Color Emoji"
        ];
        serif = [
          "Noto Serif"
          "Noto Color Emoji"
        ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };
}
