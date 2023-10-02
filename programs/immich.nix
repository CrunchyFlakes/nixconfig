{ config, lib, pkgs, agenix, ... }:
let
  composeFile = pkgs.writeText "immich-composeFile.yml" ''
    version: "3.8"

    services:
      immich-server:
        container_name: immich_server
        image: ghcr.io/immich-app/immich-server:${IMMICH_VERSION:-release}
        command: [ "start.sh", "immich" ]
        volumes:
          - ${UPLOAD_LOCATION}:/usr/src/app/upload
        env_file:
          - .env
        depends_on:
          - redis
          - database
          - typesense
        restart: always

      immich-microservices:
        container_name: immich_microservices
        image: ghcr.io/immich-app/immich-server:${IMMICH_VERSION:-release}
        # extends:
        #   file: hwaccel.yml
        #   service: hwaccel
        command: [ "start.sh", "microservices" ]
        volumes:
          - ${UPLOAD_LOCATION}:/usr/src/app/upload
        env_file:
          - .env
        depends_on:
          - redis
          - database
          - typesense
        restart: always

      immich-machine-learning:
        container_name: immich_machine_learning
        image: ghcr.io/immich-app/immich-machine-learning:${IMMICH_VERSION:-release}
        volumes:
          - model-cache:/cache
        env_file:
          - .env
        restart: always

      immich-web:
        container_name: immich_web
        image: ghcr.io/immich-app/immich-web:${IMMICH_VERSION:-release}
        env_file:
          - .env
        restart: always

      typesense:
        container_name: immich_typesense
        image: typesense/typesense:0.24.1@sha256:9bcff2b829f12074426ca044b56160ca9d777a0c488303469143dd9f8259d4dd
        environment:
          - TYPESENSE_API_KEY=${TYPESENSE_API_KEY}
          - TYPESENSE_DATA_DIR=/data
          # remove this to get debug messages
          - GLOG_minloglevel=1
        volumes:
          - tsdata:/data
        restart: always

      redis:
        container_name: immich_redis
        image: redis:6.2-alpine@sha256:70a7a5b641117670beae0d80658430853896b5ef269ccf00d1827427e3263fa3
        restart: always

      database:
        container_name: immich_postgres
        image: postgres:14-alpine@sha256:28407a9961e76f2d285dc6991e8e48893503cc3836a4755bbc2d40bcc272a441
        env_file:
          - .env
        environment:
          POSTGRES_PASSWORD: ${DB_PASSWORD}
          POSTGRES_USER: ${DB_USERNAME}
          POSTGRES_DB: ${DB_DATABASE_NAME}
        volumes:
          - pgdata:/var/lib/postgresql/data
        restart: always

      immich-proxy:
        container_name: immich_proxy
        image: ghcr.io/immich-app/immich-proxy:${IMMICH_VERSION:-release}
        environment:
          # Make sure these values get passed through from the env file
          - IMMICH_SERVER_URL
          - IMMICH_WEB_URL
        ports:
          - 2283:8080
        depends_on:
          - immich-server
          - immich-web
        restart: always

    volumes:
      pgdata:
      model-cache:
      tsdata:
  '';
in {
  users.groups."immich" = {};
  users.users."immich" = {
    isSystemUser = true;
    group = "immich";
  };
  systemd.tmpfiles.rules = [ "d /var/lib/immich 0751 immich immich" "d /mnt/kodi_lib/photos 0751 immich immich" ];

  age.secrets."immichenv" = {
    file = ../secrets/immich_env.age;
    owner = "immich";
    group = "immich";
  };
  systemd.services."immich" = {
    enable = true;
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "forking";
      User = "immich";
      Group = "immich";
      WorkingDirectory = "/var/lib/immich";
      ExecStart = "${pkgs.podman-compose}/bin/podman-compose --env-file ${config.age.secrets.immichenv.path} --file ${composeFile} -p immich up --detach --pull";
      ExecStop = "${pkgs.podman-compose}/bin/podman-compose --env-file ${config.age.secrets.immichenv.path} --file ${composeFile} -p immich down";
    };
  };
}
