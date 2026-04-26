{
  config,
  pkgs,
  nixpkgs-unstable,
  lib,
  inputs,
  ...
}:
let
  pkgs-unstable = import nixpkgs-unstable { system = pkgs.system; config.allowUnfree = true; };
  lua-packages =
    p: with p; [
      luarocks
    ];
  python-packages =
    p: with p; [
      pandas
      numpy
      pynvim
      ipython
      matplotlib
      plotly
      scikit-learn
      scipy
      kaleido
      # For molten.nvim
      jupyter-client
      cairosvg
      pnglatex
      plotly
      pyperclip
      nbformat
      pillow
      requests
      websocket-client
      # for markdown rendering in nvim
      pylatexenc
    ];
  neomutt_gruvboxtheme = pkgs.callPackage ./neomutt_gruvboxtheme.nix { };
  wallpaper = ./config/hypr/wallpaper/gruvbox-dark-blue.png;
  aspell-dicts =
    p: with p; [
      en
      en-computers
      en-science
      de
    ];
  keepass-database = "~/drive/Passwords.kdbx";
  run-cwd-sway = pkgs.writeShellScript "run-cwd-sway.sh" ''
    if FOCUSED=$(swaymsg -t get_tree | jq -e '.. | select(.type?) | select(.focused) | .pid') && [ -n "$FOCUSED" ]; then
      # cwd of first-level child is usually more useful (e.g. shell proc forked from terminal emulator)
      # but fallback to the cwd of the focused app if no children procs
      #
      echo $FOCUSED
      for pid in $(cat "/proc/$FOCUSED/task"/*/children) $FOCUSED; do
        # Ignores kitten for kitty terminal as that only does cleanup
        child_name=$(cat "/proc/$pid/cmdline")
        if cwd=$(readlink -e "/proc/$pid/cwd") && [ -n "$cwd" ] && [[ ! $child_name =~ "kitten" ]]; then

          echo $pid
          echo $cwd
          cd "$cwd" && break
        fi
      done
    fi
    exec "$@"
  '';
in
{
  imports = [ ./devel.nix ];

  home.packages =
    with pkgs;
    [
      alacritty
      warp-terminal
      element-desktop
      ferdium
      discord
      fnott
      mpv
      steam-run
      morgen
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
    ]
    ++ (with nixpkgs-unstable.legacyPackages.${pkgs.system}; [
      neovim-qt
      neovide
    ])
    ++ (with pkgs-unstable; [
      claude-code
    ]);

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    NIXOS_OZONE_WL = "1";
  };

  home.file.".config/sway/nix-managed" = {
    text = ''
      set $run-cwd ${run-cwd-sway}
    '';
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
        forwardAgent = false;
        serverAliveInterval = 30;
        serverAliveCountMax = 5;
        compression = true;
        addKeysToAgent = "30m";
        hashKnownHosts = false;
        userKnownHostsFile = "~/.ssh/known_hosts";
        controlMaster = "auto";
        controlPath = "~/.ssh/master-%r@%n:%p";
        controlPersist = "10h";
      };
      workCluster = {
        match = "originalhost luis-cluster*,work*,kisski-cluster* exec \"bash -c '! nc -zw1 %h 22'\"";
        proxyJump = "work-jump";
      };
      pc2Cluster = {
        match = "originalhost n2-jumphost,otus-jumphost exec \"bash -c '! nc -zw1 %h 22'\"";
        proxyJump = "workpc";
      };
      homepc = {
        user = "mtoepperwien";
        hostname = "192.168.1.149";
        proxyJump = "server";
        forwardAgent = true;
        remoteForwards = [
          {
            bind.address = "/run/user/1000/gnupg/S.gpg-agent";
            host.address = "/run/user/1000/gnupg/S.gpg-agent.extra";
          }
        ];
      };
      server = {
        hostname = "mosi.me";
        user = "mtoepperwien";
        forwardAgent = true;
      };
      tobiserver = {
        hostname = "accounts.fritz-schubert-akademie.de";
      };
      luis-cluster = {
        hostname = "login.cluster.uni-hannover.de";
        user = "nhwptoem";
      };
      luis-cluster-transfer = {
        hostname = "transfer.cluster.uni-hannover.de";
        user = "nhwptoem";
      };
      work-jump = {
        hostname = "ssh1.ai.uni-hannover.de";
        user = "toepperwien";
      };
      workpc = {
        hostname = "jmtoepperwienpc.ai.uni-hannover.de";
        user = "mtoepperwien";
        forwardAgent = true;
        remoteForwards = [
          {
            bind.address = "/run/user/1000/gnupg/S.gpg-agent";
            host.address = "/run/user/1000/gnupg/S.gpg-agent.extra";
          }
        ];
      };
      workpc-bootup = {
        hostname = "jmtoepperwienpc.ai.uni-hannover.de";
        user = "root";
        extraOptions."HostKeyAlias" = "workpc-bootup";
      };
      otus-jumphost = {
        hostname = "fe.otus.pc2.uni-paderborn.de";
        user = "inxml20";
        identityFile = "~/.config/ssh/yubikey.pub";
        identitiesOnly = true;
      };
      otus-login1 = {
        hostname = "login1.ln2025.pc2.uni-paderborn.de";
        user = "inxml20";
        proxyJump = "otus-jumphost";
        identityFile = "~/.config/ssh/yubikey.pub";
        identitiesOnly = true;
      };
      otus-login2 = {
        hostname = "login2.ln2025.pc2.uni-paderborn.de";
        user = "inxml20";
        proxyJump = "otus-jumphost";
        identityFile = "~/.config/ssh/yubikey.pub";
        identitiesOnly = true;
      };

      n2-jumphost = {
        hostname = "fe.noctua2.pc2.uni-paderborn.de";
        user = "inxml20";
        identityFile = "~/.config/ssh/yubikey.pub";
        identitiesOnly = true;
      };
      n2login1 = {
        hostname = "n2login1.ab2021.pc2.uni-paderborn.de";
        user = "inxml20";
        proxyJump = "n2-jumphost";
        identityFile = "~/.config/ssh/yubikey.pub";
        identitiesOnly = true;
      };
      n2login2 = {
        hostname = "n2login2.ab2021.pc2.uni-paderborn.de";
        user = "inxml20";
        proxyJump = "n2-jumphost";
        identityFile = "~/.config/ssh/yubikey.pub";
        identitiesOnly = true;
      };
      kisski-cluster = {
        hostname = "kisski01.cluster.uni-hannover.de";
        user = "mtoepper";
      };
    };
  };

  home.pointerCursor =
    let
      getFrom = url: hash: name: {
          gtk.enable = true;
          x11.enable = true;
          name = name;
          size = 48;
          package =
            pkgs.runCommand "moveUp" {} ''
              mkdir -p $out/share/icons
              ln -s ${pkgs.fetchzip {
                url = url;
                hash = hash;
              }} $out/share/icons/${name}
          '';
        };
    in
      getFrom
        "https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.7/Bibata-Modern-Ice.tar.xz"
        "sha256-SG/NQd3K9DHNr9o4m49LJH+UC/a1eROUjrAQDSn3TAU="
        "Bibata-Modern-Ice";
  programs.fuzzel = {
    enable = true;
    settings = {
      colors = {
        background = "282828ff";
        text = "d4be98ff";
        match = "e78a4eff";
        selection = "45403dff";
        selection-match = "e78a4eff";
        selection-text = "d4be98ff";
        border = "a9b665ff";
      };
    };
  };
  programs.vscode = {
    enable = true;
    package = pkgs.vscode.fhs;
  };
  # [TODO: maybe this can be removed in the future. Right now electron needs gpu disabled]
  xdg.desktopEntries."code" = {
    name = "Visual Studio Code";
    exec = "code --new-window --enable-ozone --ozone-platform=wayland --disable-gpu %F";
  };
  xdg.desktopEntries."obsidian" = {
    name = "Obsidian";
    exec = "obsidian --enable-ozone --ozone-platform=wayland --disable-gpu %u";
  };
  xdg.desktopEntries."ferdium" = {
    name = "Ferdium";
    exec = "ferdium --enable-ozone --ozone-platform=wayland --disable-gpu %U";
  };
  xdg.desktopEntries."Mattermost" = {
    name = "Mattermost";
    exec = "${pkgs.mattermost}/bin/mattermost --enable-ozone --ozone-platform=wayland --disable-gpu %U";
  };
  xdg.desktopEntries."spotify" = {
    name = "Spotify";
    exec = "spotify --enable-ozone --ozone-platform=wayland --disable-gpu %U";
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
    nix-direnv.enable = true;
  };

  programs.broot = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    enableNushellIntegration = false;
    git = true;
    colors = "auto";
  };

  programs.carapace = {
    enable = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
  };

  programs.git = {
    enable = true;
    settings = {
      user.name = "Jan Malte Töpperwien";
      user.email = lib.mkDefault "m.toepperwien@protonmail.com";
      core = {
        excludesfile = "/home/mtoepperwien/.config/git/ignore";
      };
      "filter \"sqlite3\"" = {
        clean = "f() { tmpfile=$(mktemp); cat - > $tmpfile; sqlite3 $tmpfile .dump; rm $tmpfile; }; f";
        smudge = "f() { tmpfile=$(mktemp); sqlite3 $tmpfile; cat $tmpfile; rm $tmpfile; }; f";
        required = "true";
      };
      merge.tool = "meld";
      mergetool.prompt = "false";
      "mergetool \"meld\"".cmd = "${pkgs.meld}/bin/meld \"$LOCAL\" \"$BASE\" \"$REMOTE\" --output=\"$MERGED\"";
    };
    signing = {
      key = "0x4AD13F07CA26E224!";
      signByDefault = true;
    };
    #riff.enable = true;
    #gitui.enable = true;
  };
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };

  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    enableNushellIntegration = true;
  };

  # use config folder
  home.file.".config" = {
    source = ./config;
    recursive = true;
  };
  home.file.".p10k.zsh".source = ./config/p10k.zsh;
  home.file.".taskrc".source = ./config/taskrc;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    package = nixpkgs-unstable.legacyPackages.${pkgs.system}.neovim-unwrapped;
    extraLuaPackages = ps: [
      ps.magick
      ps.luarocks
    ];
    extraPackages = [ pkgs.imagemagick pkgs.pyright pkgs.gcc_multi pkgs.nodejs_24 ];
    extraPython3Packages =
      ps: with ps; [
        pynvim
        ipython
        jupyter-client
        cairosvg
        pnglatex
        plotly
        pyperclip
        nbformat
        pillow
        requests
        websocket-client
        kaleido
        pylatexenc
      ];
    extraLuaConfig = ''
      vim.loader.enable()
      vim.g.mapleader = ","
      require("vimsettings")
      require("bootstrap/lazy")
      require("plugins")
      require("keybindings")
      local status, ts_install = pcall(require, "nvim-treesitter.install")
      if(status) then
        ts_install.compilers = { "${pkgs.gcc_multi}/bin/gcc" }
      end
    '';
  };

  programs.starship = {
    enable = true;
    enableNushellIntegration = true;
  };

  home.activation.cleanupNushellVendor = lib.hm.dag.entryBefore ["writeBoundary"] ''
    rm -rf "$HOME/.local/share/nushell"
  '';
  programs.nushell = {
    enable = true;
    settings = {
      show_banner = false;
      cursor_shape = {
        emacs = "line";
        vi_insert = "line";
        vi_normal = "block";
      };
    };
    extraConfig = ''
      overlay use ${inputs.nushell-git-aliases}
      $env.CARAPACE_LENIENT = 1
      $env.CARAPACE_BRIDGES = "zsh,fish,bash"
    '';
  };
  programs.kitty = {
    enable = true;
    shellIntegration.enableZshIntegration = true;
    shellIntegration.enableBashIntegration = true;
    font = {
      name = "SauceCodePro Nerd Font Mono";
      size = lib.mkDefault 15;
    };
    themeFile = "GruvboxMaterialDarkMedium";
    settings = {
      cursor_shape = "block";
      cursor_blink_interval = 0;
      disable_ligatures = "always";
      repaint_delay = 7; # this is approx 144hz
      enable_audio_bell = false;
      notify_on_cmd_finish = "unfocused 60.0";
    };
    extraConfig = ''
      map --new-mode passthrough --on-unknown passthrough ctrl+shift+space
      map --mode passthrough ctrl+shift+space pop_keyboard_mode
    '';
  };

  # allow homemanager fonts
  fonts.fontconfig.enable = true;

  programs.zsh = {
    enable = true;
    enableCompletion = true; # not finished if system package completion is wanted (look at home manager documentation)
    autocd = true;
    history.save = 1000;
    history.size = 1000;
    initContent = lib.mkMerge [
      (lib.mkBefore ''
        ZSH_DISABLE_COMPFIX=true
        skip_global_compinit=1
      '')
      (lib.mkAfter ''
        setopt extended_glob

        [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

        function open {
          for i
              do (xdg-open "$i" > /dev/null 2> /dev/null &)
          done
        }
      '')
      ];
    shellAliases = {
      "bat" = "bat --theme gruvbox-dark";
      "tree" = "tree -C";
      "tt" = "taskwarrior-tui";
      "cp" = "cp --reflink=auto";
      "cd" = "z";
      "ls" = "eza";
    };
    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
    ];
    oh-my-zsh = {
      enable = true;
      plugins = [
        "vi-mode"
        "git"
        "zoxide"
      ];
    };
  };
  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
  };

  services.fnott = {
    enable = true;
  };

  programs.firefox = {
    enable = true;
    nativeMessagingHosts = [ pkgs.fnott ];
  };

  programs.feh = {
    enable = true;
  };

  # default applications
  xdg.mime.enable = true;
  xdg.configFile."mimeapps.list" = lib.mkIf config.xdg.mimeApps.enable { force = true; };
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];
      "x-scheme-handler/about" = [ "firefox.desktop" ];
      "x-scheme-handler/unknown" = [ "firefox.desktop" ];
      "x-scheme-handler/mailto" = [ "thunderbird.desktop" ];
      "x-scheme-handler/steam" = [ "steam.desktop" ];
      "application/pdf" = [ "org.pwmt.zathura.desktop" ];
      "image/png" = [ "feh.desktop" ];
      "x-scheme-handler/obsidian" = [ "obsidian.desktop" ];
    };
  };

  # Hyprland
  services.hyprpaper = {
    enable = false;
    settings = {
      preload = "${wallpaper}";
      wallpaper = ",${wallpaper}";
    };
  };

  # GnuPG
  programs.gpg = {
    enable = true;
    scdaemonSettings = {
      disable-ccid = true;
    };
  };

  programs.zellij = {
    enable = true;
    settings = {
      theme = "gruvbox-dark";
      focus_follows_mouse = true;
    };
    extraConfig = ''
      keybinds {
          // keybinds are divided into modes
          normal {
              // bind instructions can include one or more keys (both keys will be bound separately)
              // bind keys can include one or more actions (all actions will be performed with no sequential guarantees)
              unbind "Ctrl g"
              bind "Ctrl a" { SwitchToMode "locked"; }
          }
          pane {
          }
          locked {
              unbind "Ctrl g"
              bind "Ctrl a" { SwitchToMode "normal"; }
          }
      }
    '';
  };


  # emails
  programs.thunderbird = {
    enable = true;
    profiles = {
      "main" = {
        isDefault = true;
      };
    };
  };
  accounts.email.accounts = {
    "protonmail" = {
      address = "m.toepperwien@protonmail.com";
      userName = "m.toepperwien@protonmail.com";
      realName = "Jan Malte Töpperwien";
      thunderbird.enable = true;
      neomutt.enable = true;
      passwordCommand = "pass protonmail";
      smtp = {
        host = "127.0.0.1";
        port = 1025;
        tls.enable = true;
        tls.useStartTls = true;
      };
      imap = {
        host = "127.0.0.1";
        port = 1143;
        tls.enable = true;
        tls.useStartTls = true;
      };
    };
    "university" =
      let
        mailboxFolders = [
          "Inbox"
          "Sent"
          "Archive"
        ];
      in
      {
        address = "m.toepperwien@stud.uni-hannover.de";
        userName = "m.toepperwien@stud.uni-hannover.de";
        realName = "Jan Malte Töpperwien";
        mbsync = {
          enable = true;
          create = "maildir";
        };
        msmtp.enable = true;
        smtp = {
          host = "smtp.uni-hannover.de";
          port = 587;
          tls.enable = true;
          tls.useStartTls = true;
        };
        imap = {
          host = "mail.uni-hannover.de";
          port = 993;
          tls.enable = true;
        };
        neomutt = {
          enable = true;
          extraMailboxes = mailboxFolders;
        };
        thunderbird.enable = true;
        passwordCommand = "keepassxc-cli clip ${keepass-database} 'LUH Mail' -y 2:$(${pkgs.yubikey-manager}/bin/ykman list -s)";
      };
    "ai" =
      let
        mailboxFolders = [
          "Inbox"
          "Sent"
          "Archive"
        ];
      in
      {
        address = "m.toepperwien@ai.uni-hannover.de";
        userName = "m.toepperwien@ai.uni-hannover.de";
        realName = "Jan Malte Töpperwien";
        primary = true;
        mbsync = {
          enable = true;
          create = "maildir";
        };
        msmtp.enable = true;
        smtp = {
          host = "smtp.uni-hannover.de";
          port = 587;
          tls.enable = true;
          tls.useStartTls = true;
        };
        imap = {
          host = "mail.uni-hannover.de";
          port = 993;
          tls.enable = true;
        };
        neomutt = {
          enable = true;
          extraMailboxes = mailboxFolders;
        };
        thunderbird.enable = true;
        passwordCommand = "keepassxc-cli clip ${keepass-database} 'AI Mail' -y 2:$(${pkgs.yubikey-manager}/bin/ykman list -s)";
      };

    "gmail" = {
      address = "m.toepperwien@gmail.com";
      userName = "m.toepperwien@gmail.com";
      realName = "Jan Malte Töpperwien";
      thunderbird.enable = true;
      imap = {
        host = "imap.gmail.com";
        port = 993;
        tls.enable = true;
      };
      smtp = {
        host = "smtp.gmail.com";
        port = 587;
        tls.enable = true;
        tls.useStartTls = true;
      };
    };
  };
  programs.neomutt = {
    enable = true;
    vimKeys = true;
    extraConfig = ''
      set mail_check_stats

      # Group reply
      bind index,pager R group-reply

      # Archive messages with 'A', applies to tagged emails if present and else to current email
      macro index A ":set confirmappend=no delete=yes<enter><tag-prefix><save-message>=Archive<enter>:set confirmappend=yes delete=ask-yes<enter>"

      bind index <Return> display-message

      # gruvbox theme
      source ${neomutt_gruvboxtheme}/colors-gruvbox-shuber.muttrc
      source ${neomutt_gruvboxtheme}/colors-gruvbox-shuber-extended.muttrc
    '';
  };
  programs.mbsync.enable = true;
  services.mbsync.enable = true;
  programs.msmtp.enable = true;
}
