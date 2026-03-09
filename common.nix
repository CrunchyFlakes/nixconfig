{
  config,
  lib,
  modulesPath,
  pkgs,
  inputs,
  agenix,
  ...
}:

{
  nix.registry = {
    nixpkgs.flake = inputs.nixpkgs-stable;
    unstable.flake = inputs.nixpkgs-unstable;
  };
  nixpkgs.config.allowUnfree = true;
  nix = {
    settings.auto-optimise-store = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    package = pkgs.nixVersions.stable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
  # Use extra caches for packages
  nix.settings.substituters = [
    "https://nix-community.cachix.org"
    "https://cache.nixos-cuda.org"
  ];
  nix.settings.trusted-public-keys = [
    # Compare to the key published at https://nix-community.org/cache
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
  ];
  # allow remote builds
  nix.settings.trusted-users = [ "mtoepperwien" ];

  imports = [
    ./common/devel.nix
  ];

  environment.systemPackages = with pkgs; [
    su
    bat
    eza
    dust
    duf
    fzf
    fd
    ripgrep
    zoxide
    mcfly
    dig
    broot
    btrfs-progs
    wget
    curl
    # btop
    hdparm
    mediainfo
    ffmpeg
    ncdu
    pass
    gnupg
    pinentry-tty
    tmux
    tree
    tealdeer
    unrar
    unzip
    unp
    sshfs
    zsh
    findutils
    smartmontools
    usbutils
    rename
    irssi
    wcalc
    wireguard-tools
    speedtest-cli
    poetry
    pyrosimple
    imagemagick
    openseachest
    distrobox
    deploy-rs
    wol  # wake-on-lan
  ];

  programs.nix-ld = {
    enable = true;
    libraries = [
      (pkgs.runCommand "steamrun-lib" {} "mkdir $out; ln -s ${pkgs.steam-run.fhsenv}/usr/lib64 $out/lib")
    ];
  };
  programs.nix-index-database.comma.enable = true;

  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-qt;
    enableSSHSupport = true;
    enableExtraSocket = true;
  };

  programs.zsh = {
    enable = true;
    shellAliases = {
      nixgit = "cd /etc/nixos && sudo git pull";
    };
    autosuggestions.enable = true;
  };
  users.defaultUserShell = pkgs.zsh;

  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    package = inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}.neovim-unwrapped;
  };
  programs.git = {
    enable = true;
    config = {
      init.defaultBranch = "main";
      user.name = "Jan Malte Töpperwien";
      user.email = "m.toepperwien@protonmail.com";
    };
  };
  programs.tmux = {
    enable = true;
    plugins = with pkgs.tmuxPlugins; [
      gruvbox
      sensible
      jump
      tilish
      tmux-fzf
    ];
    extraConfig = ''
      set -g repeat-time 0
      set -g @tmux-gruvbox 'dark'
      set -g @tilish-default 'main-vertical'
      set -gq allow-passthrough on
      set -g visual-activity off
      set -g base-index 1
      setw -g pane-base-index 1

      # Alt + number key bindings for window switching/creation
      bind-key -n M-1 if-shell 'tmux list-windows | grep "^1:"' 'select-window -t 1' 'new-window -t 1'
      bind-key -n M-2 if-shell 'tmux list-windows | grep "^2:"' 'select-window -t 2' 'new-window -t 2'
      bind-key -n M-3 if-shell 'tmux list-windows | grep "^3:"' 'select-window -t 3' 'new-window -t 3'
      bind-key -n M-4 if-shell 'tmux list-windows | grep "^4:"' 'select-window -t 4' 'new-window -t 4'
      bind-key -n M-5 if-shell 'tmux list-windows | grep "^5:"' 'select-window -t 5' 'new-window -t 5'
      bind-key -n M-6 if-shell 'tmux list-windows | grep "^6:"' 'select-window -t 6' 'new-window -t 6'
      bind-key -n M-7 if-shell 'tmux list-windows | grep "^7:"' 'select-window -t 7' 'new-window -t 7'
      bind-key -n M-8 if-shell 'tmux list-windows | grep "^8:"' 'select-window -t 8' 'new-window -t 8'
      bind-key -n M-9 if-shell 'tmux list-windows | grep "^9:"' 'select-window -t 9' 'new-window -t 9'
      bind-key -n M-0 if-shell 'tmux list-windows | grep "^0:"' 'select-window -t 0' 'new-window -t 0'
    '';
  };
  xdg.mime.enable = true;

  # drive health checks
  services.smartd.enable = true;

  virtualisation = {
    oci-containers.backend = "podman";
    podman = {
      enable = true;

      dockerCompat = true;
    };
  };

  system.activationScripts.nonposix.text = ''
    ln -sf /run/current-system/sw/bin/bash /bin/bash
    rm -rf /lib64 ; mkdir /lib64 ; ln -sf ${pkgs.glibc.outPath}/lib/ld-linux-x86-64.so.2 /lib64
  '';
  boot.loader.systemd-boot.configurationLimit = 5;
  security.pki.certificateFiles = [ "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt" ];
}
