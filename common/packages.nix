{ pkgs, nixpkgs-unstable, lib, ... }:

{
  home.packages = with pkgs; [
    alacritty
    warp-terminal
    element-desktop
    ferdium
    discord
    fnott
    mpv
    steam-run
    obsidian
    papis
    zotero
    sqlite
    # neovim and plugin dependencies {{{
    neovim-remote
    luajitPackages.jsregexp # dependency of luasnip neovim plugin
    tree-sitter
    jq
    inkscape
    imv
    nodePackages.npm
    wget
    curl
    lua-language-server
    clang-tools
    pyright
    nixd
    nixfmt-rfc-style
    cairo
    # }}} neovim and plugin dependencies
    lazygit
    # Latex
    texlive.combined.scheme-full
    (aspellWithDicts aspell-dicts)
    qutebrowser
    sway
    swaylock
    hyprland
    slurp
    grim
    playerctl # sway audio button bindings
    waybar
    font-awesome # needed for waybar icons
    ungoogled-chromium
    google-chrome
    nautilus
    (python3.withPackages python-packages)
    uv
    (lua5_1.withPackages lua-packages)
    # poetry ignore for now due to dependency missing
    virtualenv
    ripgrep
    pdfgrep
    zathura
    kdePackages.okular
    wl-clipboard
    nerd-fonts.sauce-code-pro
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
    xdg-utils
    unzip
    # gnupg
    gnupg
    pinentry-qt
    pass
    gcr  # Provides org.gnome.keyring.SystemPrompter
    libreoffice-fresh
    grim
    pdftk
    pandoc
    xournalpp
    timewarrior
    taskwarrior3
    taskwarrior-tui
    pdfpc
    qmk
    amdgpu_top
    solvespace  # nice and easy CAD program
    bottles
    appimage-run
    aria2
    gimp
    drawio
    hexchat
    pocket-casts
  ] ++ (with nixpkgs-unstable.legacyPackages.${pkgs.system}; [
    neovim-qt
    neovide
  ]);
}