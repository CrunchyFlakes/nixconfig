{
  config,
  pkgs,
  lib,
  ...
}:

{
  # mautrix-whatsapp depends on libolm (marked insecure in nixpkgs due to deprecation,
  # but no replacement exists for the bridge use-case yet)
  nixpkgs.config.permittedInsecurePackages = [ "olm-3.2.16" ];

  age.secrets."mautrix-whatsapp" = {
    file = ../secrets/mautrix-whatsapp.age;
    owner = "mautrix-whatsapp";
    group = "mautrix-whatsapp";
  };

  services.mautrix-whatsapp = {
    environmentFile = config.age.secrets."mautrix-whatsapp".path;
    enable = true;
    # continuwuity handles appservice registration via admin commands,
    # not via the synapse app_service_config_files mechanism.
    registerToSynapse = false;
    settings = {
      homeserver = {
        # Connect via the nginx reverse proxy (continuwuity only exposes a unix socket)
        address = "https://matrix.jmtoepperwien.com";
        domain = "matrix.jmtoepperwien.com";
      };
      appservice = {
        # continuwuity will push events to the bridge at this address
        address = "http://localhost:29318";
        hostname = "127.0.0.1";
        port = 29318;
      };
      bridge = {
        permissions = {
          "@jmtoepperwien:matrix.jmtoepperwien.com" = "admin";
        };
      };
      network = {
        displayname_template = "{{or .FullName .PushName .Phone}} (WA)";
      };
      encryption = {
        allow = true;
        default = true;
        require = true;
        pickle_key = "$PICKLE_KEY";
      };
    };
  };

  # After first deploy, register the bridge with continuwuity:
  # 1. cat /var/lib/mautrix-whatsapp/whatsapp-registration.yaml
  # 2. In the Matrix admin room, send:
  #    !admin appservices register
  #    (paste the YAML contents in a code block)
}
