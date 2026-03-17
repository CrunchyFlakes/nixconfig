{
  config,
  pkgs,
  nixpkgs-unstable,
  lib,
  inputs,
  ...
}:
let
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
  imports = [ ./devel.nix ../common/ssh.nix ];

  home.packages = (import ../common/packages.nix { inherit pkgs nixpkgs-unstable lib; });

  home.sessionVariables = {
    VISUAL = "nvim";
    NIXOS_OZONE_WL = "1";
  };

  home.file.".config/sway/nix-managed" = {
    text = ''
      set $run-cwd ${run-cwd-sway}
    '';
  };

  # Rest of the configuration is moved to other files or kept as needed
  # The SSH configuration is now in common/ssh.nix
  # Other configurations are kept in the respective files
}