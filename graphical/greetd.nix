{
  config,
  lib,
  pkgs,
  ...
}:
let
  # sway-run = pkgs.writeShellScriptBin "sway-run" (builtins.readFile ./sway-run.sh);
  sway-run = pkgs.writeShellScriptBin "sway-run" ''
      #!/bin/sh

      # Session
      export XDG_SESSION_TYPE=wayland
      export XDG_SESSION_DESKTOP=sway
      export XDG_CURRENT_DESKTOP=sway

      # Wayland stuff
      export MOZ_ENABLE_WAYLAND=1
      export QT_QPA_PLATFORM=wayland
      export SDL_VIDEODRIVER=wayland
      export _JAVA_AWT_WM_NONREPARENTING=1
      export GDK_BACKEND=wayland

      exec systemd-cat --identifier=sway sway ${lib.concatStringsSep " " config.graphical.swayOptions} $@
  '';
  sway-greetd-config = pkgs.writeText "sway-greetd-config" ''
    include /etc/sway/config.d/*
    exec systemctl --user import-environment WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP SWAYSOCK I3SOCK XCURSOR_SIZE XCURSOR_THEME
    exec dbus-update-activation-environment WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP SWAYSOCK I3SOCK XCURSOR_SIZE XCURSOR_THEME
    exec "${pkgs.gtkgreet}/bin/gtkgreet -l; swaymsg exit"
    exec ${pkgs.swayidle}/bin/swayidle -w timeout 60 'swaymsg "output * dpms off"' resume 'swaymsg "output * dpms on"'

    bindsym Mod4+shift+e exec swaynag \
    -t warning \
    -m 'What do you want to do' \
    -b 'Poweroff' 'systemctl poweroff' \
    -b 'Reboot' 'systemctl reboot'

  '';
in
{
  environment.systemPackages = [
    pkgs.greetd
    sway-run
  ];
  security.polkit.enable = true; # needed for seat management; couldn't get seatd to work
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.sway}/bin/sway ${lib.concatStringsSep " " config.graphical.swayOptions} --config ${sway-greetd-config}";
      };
    };
  };
  programs.regreet.enable = true;
  environment.etc."greetd/environments".text = lib.mkDefault ''
    sway-run
    zsh
    bash
  '';
}
