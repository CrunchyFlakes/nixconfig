{
  config,
  lib,
  pkgs,
  ...
}:

{
  age.secrets.ldap = {
    file = ../secrets/ldap.age;
    owner = "lldap";
    group = "lldap";
  };
  users.groups."lldap" = {};
  users.users."lldap" = {
    isSystemUser = true;
    group = "lldap";
  };
  services.lldap = {
    enable = true;
    settings = {
      ldap_base_dn = "dc=mosi,dc=com";
      ldap_user_email = "m.toepperwien@protonmail.com";
      ldap_user_pass = "lldapdefaultpassword";
      ldap_user_dn = "admin";
      database_url = "postgres://%2Frun%2Fpostgresql/lldap";
      http_url = "http://ldap.mosi.me";
      http_port = 17170;
      http_host = "0.0.0.0";
    };
  };
}
