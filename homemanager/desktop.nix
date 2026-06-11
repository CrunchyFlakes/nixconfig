{
  config,
  pkgs,
  nixpkgs-unstable,
  lib,
  inputs,
  ...
}:
let
  pkgs-unstable = import nixpkgs-unstable {
    system = pkgs.system;
    config.allowUnfree = true;
  };
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
      gh
      typst
      # Latex
      texlive.combined.scheme-full
      (aspellWithDicts aspell-dicts)
      qutebrowser
      sway
      swaylock
      swayidle
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
      poppler-utils
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
      gcr # Provides org.gnome.keyring.SystemPrompter

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
      solvespace # nice and easy CAD program
      bottles
      appimage-run
      aria2
      gimp
      drawio
      hexchat
      pocket-casts
      imagemagick
      ghostscript
    ]
    ++ (with nixpkgs-unstable.legacyPackages.${pkgs.system}; [
      neovim-qt
      neovide
    ])
    ++ (with pkgs-unstable; [
      claude-code
      papis
    ])
    ++ (with inputs.llm-agents.packages.${pkgs.system}; [
      pi
    ]);

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    NIXOS_OZONE_WL = "1";
    NPM_CONFIG_PREFIX = "$HOME/.npm-global";
  };

  home.sessionPath = [
    "$HOME/.npm-global/bin"
  ];

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
        package = pkgs.runCommand "moveUp" { } ''
          mkdir -p $out/share/icons
          ln -s ${
            pkgs.fetchzip {
              url = url;
              hash = hash;
            }
          } $out/share/icons/${name}
        '';
      };
    in
    getFrom "https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.7/Bibata-Modern-Ice.tar.xz"
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
      "mergetool \"meld\"".cmd =
        "${pkgs.meld}/bin/meld \"$LOCAL\" \"$BASE\" \"$REMOTE\" --output=\"$MERGED\"";
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
  home.file.".local/bin/lean-ctx" = {
    source = config.lib.file.mkOutOfStoreSymlink "/home/mtoepperwien/.npm-global/bin/lean-ctx";
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    package = nixpkgs-unstable.legacyPackages.${pkgs.system}.neovim-unwrapped;
    plugins = with pkgs.vimPlugins; [
      # neovim-gui-shim must be first (was priority=9999 in lazy) so GUI shims are available early
      {
        plugin = pkgs.vimUtils.buildVimPlugin {
          pname = "neovim-gui-shim";
          version = "2026-06-10";
          src = pkgs.fetchFromGitHub {
            owner = "equalsraf";
            repo = "neovim-gui-shim";
            rev = "4d10bf3f68b9c0903bd1d9e456571d1d2ec16fde";
            hash = "sha256-sfbVVFJSNpgVBYxg/kOW/rQB29goIOwMk5GDrtBfOAI=";
          };
        };
        type = "lua";
        config = "";
      }
      # tpope set
      vim-sensible
      vim-abolish
      vim-vinegar
      vim-eunuch
      # wordmotion
      vim-wordmotion
      # nix
      nix-develop-nvim
      # plenary-nvim: required by obsidian-nvim, hawtkeys, neogit, fzf-lua etc.
      plenary-nvim
      # simple setup() plugins
      { plugin = marks-nvim;        type = "lua"; config = "require('marks').setup()"; }
      { plugin = nvim-colorizer-lua; type = "lua"; config = "require('colorizer').setup()"; }
      { plugin = neoscroll-nvim;    type = "lua"; config = "require('neoscroll').setup()"; }
      {
        plugin = guess-indent-nvim;
        type = "lua";
        config = ''
          require('guess-indent').setup {
            auto_cmd = true,
            override_editorconfig = false,
            filetype_exclude = { "netrw", "tutor" },
            buftype_exclude = { "help", "nofile", "terminal", "prompt" },
            on_tab_options = {
              ["expandtab"] = false,
              ["tabstop"] = 2,
              ["softtabstop"] = 2,
              ["shiftwidth"] = 2,
            },
            on_space_options = {
              ["expandtab"] = true,
              ["tabstop"] = "detected",
              ["softtabstop"] = "detected",
              ["shiftwidth"] = "detected",
            },
          }
        '';
      }
      # treesitter: replaces neovim-treesitter/nvim-treesitter + tree-sitter-manager.nvim
      {
        plugin = nvim-treesitter.withAllGrammars;
        type = "lua";
        config = ''
          require("nvim-treesitter").setup({
            incremental_selection = { enable = true },
            indent = { enable = true },
            context_commentstring = { enable = true },
          })
          -- Sync treesitter grammars on first run (was :TSUpdate in lazy)
          vim.api.nvim_create_autocmd("User", {
            pattern = "TSSourcesReady",
            callback = function()
              vim.cmd("TSUpdateSync")
            end,
            once = true,
          })
        '';
      }
      {
        plugin = nvim-treesitter-context;
        type = "lua";
        config = "require('treesitter-context').setup({ max_lines = 5 })";
      }
      {
        plugin = rainbow-delimiters-nvim;
        type = "lua";
        config = ''
          -- Defer setup to VimEnter so the FileType autocmd is only registered
          -- after startup. This matches lazy.nvim's default lazy-load behaviour
          -- and avoids errors on scratch buffers (blink.cmp, telescope, etc.)
          -- that are created during startup before any real file opens.
          vim.api.nvim_create_autocmd("VimEnter", {
            once = true,
            callback = function()
              local rainbow = require("rainbow-delimiters")
              require("rainbow-delimiters.setup").setup({
                strategy = {
                  [""] = rainbow.strategy["global"],
                  vim = rainbow.strategy["local"],
                },
                query = {
                  [""] = "rainbow-delimiters",
                  lua = "rainbow-blocks",
                },
                highlight = {
                  "RainbowDelimiterRed", "RainbowDelimiterYellow", "RainbowDelimiterBlue",
                  "RainbowDelimiterOrange", "RainbowDelimiterGreen", "RainbowDelimiterViolet",
                  "RainbowDelimiterCyan",
                },
              })
            end,
          })
        '';
      }
      # LSP + completion
      # fallback icons for unknown filetypes
      { plugin = nvim-web-devicons; type = "lua"; config = "require('nvim-web-devicons').setup({ default = true })"; }
      { plugin = nvim-lspconfig;    type = "lua"; config = "require('lsp-config')"; }
      friendly-snippets
      {
        plugin = luasnip;
        type = "lua";
        config = "require('luasnip.loaders.from_vscode').lazy_load()";
      }
      {
        plugin = blink-cmp;
        type = "lua";
        config = ''
          require("blink.cmp").setup({
            keymap = { preset = "default" },
            appearance = { nerd_font_variant = "mono" },
            completion = { documentation = { auto_show = true } },
            sources = { default = { "lsp", "path", "snippets", "buffer" } },
            snippets = { preset = "luasnip" },
            fuzzy = { implementation = "prefer_rust_with_warning" },
          })
        '';
      }
      {
        plugin = lspsaga-nvim;
        type = "lua";
        config = "require('lspsaga').setup({})"; 
      }
      # Colorscheme + statusline + winbar
      {
        plugin = gruvbox-material;
        type = "lua";
        config = ''
          vim.g.gruvbox_material_better_performance = 1
          vim.cmd([[colorscheme gruvbox-material]])
        '';
      }
      {
        plugin = lualine-nvim;
        type = "lua";
        config = ''
          require("lualine").setup({
            options = {
              theme = "gruvbox-material",
              always_show_tabline = true,
            },
            tabline = {
              lualine_b = {{
                function()
                  local dot_git = vim.fs.find({ ".git" }, { upward = true, stop = vim.loop.os_homedir() })[1]
                  if dot_git then
                    return vim.fn.fnamemodify(dot_git, ":h:t")
                  else
                    return " " .. vim.fn.fnamemodify(vim.fn.getcwd(), ":p:~")
                  end
                end,
              }},
              lualine_x = { "branch" },
            },
            sections = {
              lualine_a = { "mode" },
              lualine_b = { "diff", "diagnostics" },
              lualine_c = {{ "filename", path = 1 }},
              lualine_x = { "encoding", "fileformat" },
              lualine_y = { "progress" },
              lualine_z = { "location" },
            },
            inactive_sections = {
              lualine_a = {}, lualine_b = {},
              lualine_c = {{ "filename", path = 1 }},
              lualine_x = { "location" },
              lualine_y = {}, lualine_z = {},
            },
          })
        '';
      }
      telescope-fzf-native-nvim
      telescope-project-nvim
      {
        plugin = telescope-nvim;
        type = "lua";
        config = ''
          -- Defer telescope setup and extension loading to VimEnter so they don't block startup
          vim.api.nvim_create_autocmd("VimEnter", {
            callback = function()
              require("telescope").setup({
                pickers = {
                  live_grep  = { find_command = { "rg", "--hidden", "--glob", "!**/.git/*", "-L" } },
                  find_files = {
                    find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*", "-L" },
                    mappings = {
                      n = {
                        ["cd"] = function(prompt_bufnr)
                          local selection = require("telescope.actions.state").get_selected_entry()
                          local dir = vim.fn.fnamemodify(selection.path, ":p:h")
                          require("telescope.actions").close(prompt_bufnr)
                          vim.cmd(string.format("silent lcd %s", dir))
                        end,
                      },
                    },
                  },
                },
                extensions = {
                  project = {
                    hidden_files = true,
                    theme = "dropdown",
                    order_by = "asc",
                    search_by = "title",
                    sync_with_nvim_tree = true,
                    on_project_selected = function(prompt_bufnr)
                      local project_actions = require("telescope._extensions.project.actions")
                      project_actions.change_working_directory(prompt_bufnr, false)
                      local localconf = io.open("./.nvim.lua", "r")
                      if localconf ~= nil then
                        local selection = vim.fn.input("Found .nvim.lua \nChoose action: [l]oad [i]gnore: ")
                        if selection == "l" then dofile("./.nvim.lua") end
                      end
                    end,
                  },
                },
              })
              require("telescope").load_extension("fzf")
              require("telescope").load_extension("project")
            end,
            once = true,
          })
          -- TelescopeResults filetype setup
          vim.api.nvim_create_autocmd("FileType", { pattern = "TelescopeResults", command = "setlocal nofoldenable" })
        '';
      }
      {
        plugin = dropbar-nvim;
        type = "lua";
        config = ''
          vim.api.nvim_create_autocmd("VimEnter", {
            callback = function()
              require("dropbar").setup()
              local dropbar_api = require("dropbar.api")
              vim.keymap.set("n", "<Leader>;", dropbar_api.pick,                { desc = "Pick symbols in winbar" })
              vim.keymap.set("n", "[;",        dropbar_api.goto_context_start,  { desc = "Go to start of current context" })
              vim.keymap.set("n", "];",        dropbar_api.select_next_context, { desc = "Select next context" })
            end,
            once = true,
          })
        '';
      }
      # Mini suite
      {
        plugin = mini-nvim;
        type = "lua";
        config = ''
          require("mini.align").setup()
          require("mini.comment").setup()
          require("mini.pairs").setup()
          require("mini.surround").setup()
          require("mini.icons").setup({})
          require("mini.bufremove").setup()
          vim.keymap.set("n", "<leader>x", function() MiniBufremove.delete() end, { desc = "Close buffer" })
        '';
      }
      # File manager
      { plugin = oil-nvim; type = "lua"; config = "require('oil').setup({})"; }
      # Editing / UI tools
      {
        plugin = nvim-neoclip-lua;
        type = "lua";
        config = ''
          require("neoclip").setup()
          require("telescope").load_extension("neoclip")
        '';
      }
      { plugin = twilight-nvim;     type = "lua"; config = "require('twilight').setup()"; }
      { plugin = fzf-vim; }
      {
        plugin = nvim-bqf;
        type = "lua";
        config = ''
          vim.api.nvim_create_autocmd("FileType", {
            pattern = "qf",
            callback = function()
              require("bqf").setup()
            end,
            once = true,
          })
        '';
      }
      {
        plugin = flash-nvim;
        type = "lua";
        config = ''
          require("flash").setup({ labels = "arstgmneioqwfpbjluyzxcdvkh" })
          vim.keymap.set({"n","x","o"}, "<leader>s", function() require("flash").jump() end,              { desc = "Flash" })
          vim.keymap.set({"n","x","o"}, "<leader>S", function() require("flash").treesitter() end,       { desc = "Flash Treesitter" })
          vim.keymap.set("o",           "<leader>r", function() require("flash").remote() end,            { desc = "Remote Flash" })
          vim.keymap.set({"o","x"},     "<leader>R", function() require("flash").treesitter_search() end, { desc = "Treesitter Search" })
          vim.keymap.set("c",           "<c-s>",     function() require("flash").toggle() end,            { desc = "Toggle Flash Search" })
        '';
      }
      {
        plugin = which-key-nvim;
        type = "lua";
        config = ''
          vim.o.timeout = true
          vim.o.timeoutlen = 300
          require("which-key").setup({})
          require("which-key").add({
            { "<leader>f", group = "find" },
            { "<leader>l", group = "lsp" },
            { "<leader>r", group = "run" },
            { "<leader>o", group = "output" },
            { "<leader>d", group = "daily/notes" },
          })
        '';
      }
      { plugin = zen-mode-nvim; type = "lua"; config = "require('zen-mode').setup({ window = { width = 0.85 } })"; }
      {
        plugin = nvim-ufo;
        type = "lua";
        config = ''
          vim.o.foldcolumn = "0"
          vim.o.foldlevel = 99
          vim.o.foldlevelstart = 99
          vim.o.foldenable = true
          vim.keymap.set("n", "zR", require("ufo").openAllFolds)
          vim.keymap.set("n", "zM", require("ufo").closeAllFolds)
          require("ufo").setup({
            provider_selector = function(bufnr, filetype, buftype)
              return { "treesitter", "indent" }
            end,
          })
        '';
      }
      {
        plugin = toggleterm-nvim;
        type = "lua";
        config = ''
          require("toggleterm").setup({
            size = function(term)
              if term.direction == "horizontal" then return 15
              elseif term.direction == "vertical" then return vim.o.columns * 0.4
              end
            end,
            shade_terminals = false,
            hide_numbers = true,
            autochdir = false,
            start_in_insert = false,
            insert_mappings = true,
            terminal_mappings = true,
            persist_size = true,
            persist_mode = true,
            close_on_exit = true,
            clear_env = false,
            auto_scroll = true,
            winbar = { enabled = false },
            responsiveness = { horizontal_breakpoint = 135 },
          })
        '';
      }
      {
        plugin = neogen;
        type = "lua";
        config = "require('neogen').setup({ input_after_comment = true, jump_map = \"<Tab>\" })";
      }
      { plugin = todo-comments-nvim; type = "lua"; config = "require('todo-comments').setup({})"; }
      # Git plugins
      { plugin = vim-fugitive; }
      { plugin = gitsigns-nvim; type = "lua"; config = "require('gitsigns').setup()"; }
      neogit
      diffview-nvim
      fzf-lua
      {
        plugin = pkgs.vimUtils.buildVimPlugin {
          pname = "diffs.nvim";
          version = "2026-06-05";
          src = pkgs.fetchFromGitHub {
            owner = "barrettruth";
            repo = "diffs.nvim";
            rev = "d280baf3e937a487038766f51156dd41ceb0f8e7";
            hash = "sha256-KDT6smaU1tUHMd3UkLt1IqX1N7nv74L0ffnKLCFuckA=";
          };
        };
        type = "lua";
        config = ''
          vim.g.diffs = {
            integrations = {
              fugitive = true,
              neogit = true,
              neojj = true,
              gitsigns = true,
            },
          }
        '';
      }
      # --- Jupyter / notebook plugins ---
      {
        plugin = pkgs.vimPlugins.jupytext-nvim;
        type = "lua";
        config = ''
          require("jupytext").setup({
            style = "markdown",
            output_extension = "md",
            force_ft = "markdown",
          })
        '';
      }
      {
        plugin = pkgs.vimPlugins.iron-nvim;
        type = "lua";
        config = ''
          local iron = require("iron.core")
          local view = require("iron.view")
          local common = require("iron.fts.common")
          iron.setup {
            config = {
              scratch_repl = true,
              repl_definition = {
                python = {
                  command = { "python3" },
                  format = common.bracketed_paste_python,
                },
              },
              repl_open_cmd = view.split.vertical.botright(0.4),
            },
            ignore_blank_lines = true,
          }
        '';
      }
      {
        plugin = pkgs.vimPlugins.molten-nvim;
        type = "lua";
        config = ''
          vim.g.molten_image_provider = "image.nvim"
          vim.g.molten_wrap_output = true
          vim.g.molten_virt_text_output = true
          vim.g.molten_virt_lines_off_by_1 = true
          vim.g.molten_enter_output_behavior = "open_and_enter"
        '';
      }
      pkgs.vimPlugins.vim-textobj-user
      {
        plugin = pkgs.vimUtils.buildVimPlugin {
          pname = "vim-textobj-hydrogen";
          version = "2024-01-01";
          src = pkgs.fetchFromGitHub {
            owner = "GCBallesteros";
            repo = "vim-textobj-hydrogen";
            rev = "e6f9a6b26a3524615bac347503c35327636fab72";
            hash = "sha256-uYsgVhCjF/AyUO/sfnUDYaAbB1Fm3u+5O60v2bN6Fs4=";
          };
        };
        type = "lua";
        config = "";
      }
      {
        plugin = pkgs.vimPlugins.otter-nvim;
        type = "lua";
        config = "require('otter').setup({})";
      }
      {
        plugin = pkgs.vimPlugins.quarto-nvim;
        type = "lua";
        config = ''
          require("quarto").setup({
            lspFeatures = {
              languages = { "r", "python", "rust", "html" },
              chunks = "all",
              diagnostics = {
                enabled = true,
                triggers = { "BufWritePost" },
              },
              completion = {
                enabled = true,
              },
            },
            keymap = {
              hover = "H",
              definition = "gd",
              rename = "<leader>rn",
              references = "gr",
              format = "<leader>gf",
            },
            codeRunner = {
              enabled = true,
              default_method = "iron",
              ft_runners = {},
              never_run = { "yaml" },
            },
          })
        '';
      }
      {
        plugin = pkgs.vimPlugins.image-nvim;
        type = "lua";
        config = ''
          require("image").setup({
            backend = "kitty",
            integrations = {
              markdown = {
                enabled = true,
                filetypes = { "markdown" },
              },
              html = {
                enabled = true,
                filetypes = { "markdown", "html" },
              },
            },
            max_width = 100,
            max_height = 12,
            max_height_window_percentage = math.huge,
            max_width_window_percentage = math.huge,
            window_overlap_clear_enabled = true,
            window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
          })
        '';
      }
      {
        plugin = pkgs.vimPlugins.render-markdown-nvim;
      }
      # --- Complex / conditional plugins (#8) ---
      # vimtex self-limits to tex/latex/plaintex filetypes — no explicit guard needed
      {
        plugin = pkgs.vimPlugins.vimtex;
        type = "viml";
        config = "";
      }
      {
        plugin = pkgs.vimPlugins.conform-nvim;
        type = "lua";
        config = ''
          require("conform").setup({
            formatters_by_ft = {
              lua = { "stylua" },
              python = { "ruff_format" },
              rust = { "rustfmt", lsp_format = "fallback" },
              javascript = { "prettierd", "prettier", stop_after_first = true },
            },
            format_on_save = function()
              local ignore_filetypes = { "lua" }
              if vim.tbl_contains(ignore_filetypes, vim.bo.filetype) then
                vim.notify("range formatting for " .. vim.bo.filetype .. " not working properly.")
                return
              end
              local hunks = require("gitsigns").get_hunks()
              if hunks == nil then return end
              local format = require("conform").format
              local function format_range()
                if next(hunks) == nil then
                  vim.notify("Done formatting git hunks!", "info", { title = "formatting" })
                  return
                end
                local hunk = nil
                while next(hunks) ~= nil and (hunk == nil or hunk.type == "delete") do
                  hunk = table.remove(hunks)
                end
                if hunk ~= nil and hunk.type ~= "delete" then
                  local start = hunk.added.start
                  local last = start + hunk.added.count
                  local last_hunk_line = vim.api.nvim_buf_get_lines(0, last - 2, last - 1, true)[1]
                  local range = { start = { start, 0 }, ["end"] = { last - 1, last_hunk_line:len() } }
                  format({ range = range, async = true, lsp_format = "fallback" }, function()
                    vim.defer_fn(function() format_range() end, 1)
                  end)
                end
              end
              format_range()
            end,
          })
        '';
      }
      {
        plugin = pkgs.vimPlugins.obsidian-nvim;
        type = "lua";
        config = ''
          local home = vim.loop.os_homedir()
          if vim.uv.fs_stat(home .. "/vaults/personal") or vim.uv.fs_stat(home .. "/vaults/phd") then
            local ws = {}
            if vim.uv.fs_stat(home .. "/vaults/personal") then
              table.insert(ws, { name = "personal", path = "~/vaults/personal" })
            end
            if vim.uv.fs_stat(home .. "/vaults/phd") then
              table.insert(ws, { name = "phd", path = "~/vaults/phd" })
            end
            require("obsidian").setup({
              ui = { enable = false },
              workspaces = ws,
              daily_notes = { folder = "Daily" },
              note_path_func = function(spec)
                return (spec.dir / spec.title):with_suffix(".md")
              end,
              completion = { nvim_cmp = false, min_chars = 2 },
              new_notes_location = "current_dir",
              wiki_link_func = "prepend_note_path",
              search = {
                sort_by = "modified",
                sort_reversed = true,
              },
              legacy_commands = false,
            })
          end
        '';
      }
      {
        plugin = pkgs.vimUtils.buildVimPlugin {
          pname = "hawtkeys.nvim";
          version = "2026-06-10";
          src = pkgs.fetchFromGitHub {
            owner = "tris203";
            repo = "hawtkeys.nvim";
            rev = "27495e633c071ab0881d337e0f59bfbbb19e0ac2";
            hash = "sha256-NJHvxR068KzBeHV6BGt408zAgZMbUfVq/Emh9Ai4cLg=";
          };
          # these modules require nvim-treesitter at load time
          nvimSkipModules = [ "hawtkeys.duplicates" "hawtkeys.score" "hawtkeys.show_all" "hawtkeys.ts" "hawtkeys.ui" ];
        };
        type = "lua";
        config = ''
          require("hawtkeys").setup({
            leader = ",",
            keyboardLayout = "qwerty",
            ["wk.register"] = { method = "which_key" },
            ["lazy"] = { method = "lazy" },
          })
        '';
      }
      {
        plugin = pkgs.vimUtils.buildVimPlugin {
          pname = "pastify.nvim";
          version = "2026-06-10";
          src = pkgs.fetchFromGitHub {
            owner = "TobinPalmer";
            repo = "pastify.nvim";
            rev = "4a1d1e03c3ae725ee4af796deca8c7c169ef626e";
            hash = "sha256-EFRq0IzSS66dE75/gi6RrdqZV9laUhNNpTIer6dNz2A=";
          };
        };
        type = "lua";
        config = ''
          require("pastify").setup({ opts = { save = "local_file" } })
        '';
      }
      # --- Plugins not in nixpkgs (custom builds) ---
      {
        plugin = pkgs.vimUtils.buildVimPlugin {
          pname = "highlight-current-n.nvim";
          version = "2026-06-10";
          src = pkgs.fetchFromGitHub {
            owner = "rktjmp";
            repo = "highlight-current-n.nvim";
            rev = "1225d1ad3fee74c3e6a6d258f25a1952b927cb76";
            hash = "sha256-Bel83ytJCgQ6MK4qWKU557b+OI/HdMSriFoqYoCgpzA=";
          };
        };
        type = "lua";
        config = ''
          vim.keymap.set("n", "n", "<Plug>(highlight-current-n-n)")
          vim.keymap.set("n", "N", "<Plug>(highlight-current-n-N)")
        '';
      }
      {
        plugin = pkgs.vimUtils.buildVimPlugin {
          pname = "beacon.nvim";
          version = "2026-06-10";
          src = pkgs.fetchFromGitHub {
            owner = "danilamihailov";
            repo = "beacon.nvim";
            rev = "098ff96c33874339d5e61656f3050dbd587d6bd5";
            hash = "sha256-x/79mRkwwT+sNrnf8QqocsaQtM+Rx6BUvVj5Nnv5JDY=";
          };
        };
        type = "lua";
        config = "";
      }
      {
        plugin = pkgs.vimUtils.buildVimPlugin {
          pname = "scrollEOF.nvim";
          version = "2026-06-10";
          src = pkgs.fetchFromGitHub {
            owner = "Aasim-A";
            repo = "scrollEOF.nvim";
            rev = "e462b9a07b8166c3e8011f1dcbc6bf68b67cd8d7";
            hash = "sha256-y7yOCRSGTtQcFyWVkGe3xQqstHZMQKayxtqkOVlZ4PM=";
          };
        };
        type = "lua";
        config = "require('scrollEOF').setup()";
      }
    ];
    extraLuaPackages = ps: [
      ps.magick
      ps.luarocks
    ];
    extraPackages = [
      pkgs.imagemagick
      pkgs.ghostscript
      pkgs.pyright
      pkgs.gcc_multi
      pkgs.nodejs_24
      pkgs.texlab
    ];
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
      require("keybindings")
    '';
  };

  programs.starship = {
    enable = true;
    enableNushellIntegration = true;
  };

  home.activation.cleanupNushellVendor = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
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
      $env.EDITOR = "nvim"
      $env.VISUAL = "nvim"
      $env.NPM_CONFIG_PREFIX = ($env.HOME | path join ".npm-global")
      $env.PATH = ($env.PATH | prepend ($env.HOME | path join ".npm-global" "bin"))
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
