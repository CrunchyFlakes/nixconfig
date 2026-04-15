let
  maltepc = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEMq7G/30vynsSVY3P+F8XNe9h8/QdRP5R/TWw+jaKnr cardno:32_239_307";
  maltexps = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGOBi7azxnZ0RhYXaIoE/axNkfuxnbaJ8Gs3CvLc3OT6 mtoepperwien@maltexps";

  maltepchost = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII2uFpFcaacIH9yLyyABE0u2K1zuV/fph7RDA76zZ0wJ";
  maltexpshost = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ92znHGW5UwpOfOJD/fejUKrsQLpSwSh4dt1xtIrLLs";
  pi3host = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGTx5o298UgZ3gIBzFWwE+eOW3ACy0gXtdx71fcLdNvS";
  serverhost = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEbDhNXRckcZW2FoQmR6CQFNG6XANuLcijh2vc3i1C3O";
  workpchost = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPxXGDX0EgpRRDeO3lxVZ7W6k4/vDOmXTrZ8NWXs0Be+";
  worknotebookhost = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGQLUJ+HHfsKHO2rqvj8ubCXoxZhCxlAG8i4bg8l1i1+";
in
{
  "wifipassword.age".publicKeys = [
    maltepc
    maltepchost
    maltexps
    maltexpshost
    pi3host
    serverhost
  ];
  "nextcloud-adminpass.age".publicKeys = [
    maltepc
    serverhost
  ];
  "protonvpn.age".publicKeys = [
    maltepc
    maltexps
    serverhost
  ];
  "unpackerrConfig.age".publicKeys = [
    maltepc
    maltexps
    serverhost
  ];
  "autobrrConfig.age".publicKeys = [
    maltepc
    maltexps
    serverhost
  ];
  "znc_config.age".publicKeys = [
    maltepc
    maltexps
    serverhost
  ];
  "immich_env.age".publicKeys = [
    maltepc
    maltexps
    serverhost
  ];
  "ldap.age".publicKeys = [
    maltepc
    serverhost
  ];
  "ldap_bind_passwd.age".publicKeys = [
    maltepc
    serverhost
  ];
  "cross-seed.age".publicKeys = [
    maltepc
    maltexps
    serverhost
  ];
  "webdav.age".publicKeys = [
    maltepc
    maltexps
    serverhost
  ];
  "mautrix-whatsapp.age".publicKeys = [
    maltepc
    serverhost
  ];
  "mungeKey.age".publicKeys = [
    maltepc
    workpchost
  ];
}
