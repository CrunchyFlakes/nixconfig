{
  config,
  pkgs,
  lib,
  modulesPath,
  inputs,
  ...
}:

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

  # Enable luks decryption via ssh
  # This will not activate Wake-on-LAN as it is more system specific
  boot.initrd.network = {
    enable = lib.mkDefault true;
    udhcpc.enable = true;
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
    postCommands = let
      disk = "cryptroot";  # [TODO: this should be dynamically acquired]
      # disk = config.disko.devices.disk.main.content.luks.name;
    in ''
      echo 'cryptsetup open /dev/disk/by-partlabel/luks ${disk} --type luks && echo > /tmp/continue' >> /root/.profile
      echo 'starting sshd...'
    '';

  };
}
