{
  config,
  pkgs,
  lib,
  modulesPath,
  inputs,
  ...
}:

let
  hasLuks = config.boot.initrd.luks.devices != {};
in
{
  programs.ssh.package = pkgs.openssh_hpn;
  services.openssh = {
    enable = true;
    openFirewall = true;
    allowSFTP = true;
    settings.PasswordAuthentication = lib.mkForce false;
    settings.KbdInteractiveAuthentication = lib.mkForce false;
    settings.PermitRootLogin = lib.mkForce "no"; # nixos-generators will try to put this to true for first install
    settings.X11Forwarding = true;
    settings = {
      StreamLocalBindUnlink = "yes";
    };
  };
  networking.firewall.allowedTCPPorts = [ 22 ];
  programs.mosh.enable = true;

  # Enable luks decryption via ssh (only when LUKS is actually configured)
  # This will not activate Wake-on-LAN as it is more system specific
  boot.initrd.network = lib.mkIf hasLuks {
    enable = true;
    ssh = {
      enable = true;
      hostKeys = [
        "/etc/ssh/initrd/ssh_host_rsa_key"
        "/etc/ssh/initrd/ssh_host_ed25519_key"
      ];
      authorizedKeyFiles = [
        ./authorized_keys
      ];
    };
  };

  boot.initrd.systemd.network = lib.mkIf hasLuks {
    enable = true;
    networks."10-initrd-dhcp" = {
      matchConfig.Type = "ether";
      networkConfig.DHCP = "yes";
    };
  };

  boot.initrd.systemd.contents."/root/.profile" = lib.mkIf hasLuks {
    text = "systemd-tty-ask-password-agent --watch\n";
  };
}
