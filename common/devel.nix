{
  config,
  lib,
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    # man pages for linux api not there by default
    man
    man-pages
    man-pages-posix
    gnumake
    cmake
    git
    conform
    pre-commit
    gnused
    xz
    zip
    gnutar
    llvmPackages.libunwind
    llvmPackages.libcxxStdenv
    llvmPackages.libcxxClang
    libcxx
    gcc
    gdb
    lua
    lua51Packages.lua
    luajit
  ];
  documentation.dev.enable = true;
  documentation.man.cache.enable = true;

  # allow on the fly editing of hosts file
  # will be overwritten on reboot
  environment.etc.hosts.mode = "0744";
}
