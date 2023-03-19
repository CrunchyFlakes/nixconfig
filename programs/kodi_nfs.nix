{ config, lib, pkgs, ...}:

{
  fileSystems."/export/movies" = {
    device = "/mnt/kodi_lib/movies";
    options = [ "bind" ];
  };
  fileSystems."/export/series" = {
    device = "/mnt/kodi_lib/series";
    options = [ "bind" ];
  };

  services.nfs.server.enable = true;
  services.nfs.server.exports = ''
    /export/series  192.168.1.244(ro,async,insecure,subtree_check,all_squash)
    /export/movies  192.168.1.244(ro,async,insecure,subtree_check,all_squash)
  '';

}
