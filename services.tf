module "glance_agent" {
  source = "./modules/docker-service"

  name  = "glance-agent-tf"
  image = "glanceapp/agent@sha256:f57ee10cd2f23e66ae6a8325fb6106e12878e1f985a88aaa914687d14489017c"


  ports = [
    { external = 37973, internal = 27973 },
  ]

  bind_mounts = [
    { host_path = "/", container_path = "/mnt/root", read_only = true },
    { host_path = var.raid_root, container_path = "/mnt/raid1", read_only = true },
  ]

  networks = [
    { name = docker_network.internal.name },
  ]
}

module "flaresolverr" {
  source = "./modules/docker-service"

  name        = "flaresolverr-tf"
  image       = "ghcr.io/flaresolverr/flaresolverr:v3.5.0"
  volume_name = "flaresolverr-config"

  ports = [
    { external = 18191, internal = 8191 },
  ]

  data_path = "/config"

  networks = [
    { name = docker_network.internal.name },
  ]

  env = ["LOG_LEVEL=info", "TZ=${var.timezone}"]
}

module "pi_stats" {
  source = "./modules/docker-service"

  name    = "pi-stats-tf"
  image   = "nginx@sha256:db35bfc6b2951e7f8a72db5db120288c127ffaeeb4a6d4b95a26fead017d5913" # 1.31.4-alpine
  restart = "unless-stopped"

  networks = [
    { name = "proxy" },
  ]

  bind_mounts = [
    { host_path = "${var.raid_root}/docker/glance", container_path = "/usr/share/nginx/html", read_only = true },
  ]
}

module "papra" {
  source = "./modules/docker-service"

  name    = "papra"
  image   = "ghcr.io/papra-hq/papra@sha256:a7a42e228f73f229d1e2dcd53de7b67503f1756d1aa3a894ab175dba8030c0e8"
  restart = "unless-stopped"
  bind_mounts = [
    { host_path = "${var.raid_root}/docker/papra/app-data", container_path = "/app/app-data" },
  ]
  user = "1000:100"

  ports = [
    { external = 1221, internal = 1221 },
  ]

  networks = [
    { name = "proxy" },
  ]

  env = [
    "AUTH_SECRET=${var.papra_auth_secret}",
    "APP_BASE_URL=http://${var.omv_ip}:1221",
    "TRUSTED_ORIGINS=http://${var.omv_ip}:1221,https://papra.${var.domain}",
    "AUTH_IS_REGISTRATION_ENABLED=true",
    "AUTH_IP_ADDRESS_HEADERS=x-forwarded-for",
    "DOCUMENTS_OCR_LANGUAGES=lit,eng",
    "DOCUMENT_STORAGE_MAX_UPLOAD_SIZE=104857600",
  ]

  labels = {
    "traefik.enable"                                       = "true",
    "traefik.docker.network"                               = "proxy",
    "traefik.http.routers.papra.entrypoints"               = "https",
    "traefik.http.routers.papra.rule"                      = "Host(`papra.${var.domain}`)",
    "traefik.http.routers.papra.middlewares"               = "https-redirectscheme@file",
    "traefik.http.routers.papra.tls"                       = "true",
    "traefik.http.services.papra.loadbalancer.server.port" = "1221",
  }
}

module "ollama" {
  source = "./modules/docker-service"

  name    = "ollama"
  image   = "ollama/ollama@sha256:08ddf4b4dbfdc4fc1f5b0fe535915998581085402e307b57bb308db68460e372"
  restart = "always"

  networks = [
    { name = docker_network.internal.name },
  ]

  ports = [
    { external = 11434, internal = 11434 },
  ]

  data_path = "/root/.ollama"

  env = [
    "OLLAMA_KEEP_ALIVE=5m",
    "OLLAMA_GPU_OVERHEAD=0",
  ]
  device_requests = [
    { driver = "nvidia", count = -1, capabilities = ["gpu"] }
  ]
}

module "homeassistant" {
  source = "./modules/docker-service"

  name    = "homeassistant"
  image   = "ghcr.io/home-assistant/home-assistant@sha256:14931c6b13756317849f46da1d01b45937a1150db66c081cfe529d48215943fe" # 2026.8.3
  restart = "always"

  network_mode = "host"

  bind_mounts = [
    { host_path = "${var.raid_root}/docker/homeassistant", container_path = "/config" },
    { host_path = "/etc/localtime", container_path = "/etc/localtime", read_only = true },
    { host_path = "/run/dbus", container_path = "/run/dbus", read_only = true },
  ]

  env = [
    "TZ=${var.timezone}",
  ]

  devices = [
    { host_path = "/dev/serial/by-id/usb-SONOFF_SONOFF_Dongle_Plus_MG24_4821f2605da4ef1199b4ae8086a24396-if00-port0", container_path = "/dev/ttyUSB0" },
  ]
}

module "prowlarr" {
  source = "./modules/docker-service"

  name    = "prowlarr"
  image   = "lscr.io/linuxserver/prowlarr@sha256:ab91301778251f82a31bbfc87f0497376d59e84439d9a1ceff6a61d594d1e3d7"
  restart = "always"

  networks = [
    { name = "proxy" },
  ]

  ports = [
    { external = 9696, internal = 9696 },
  ]

  bind_mounts = [
    { host_path = "${var.raid_root}/docker/prowlarr", container_path = "/config" },
  ]

  env = [
    "PUID=1000",
    "PGID=1000",
    "TZ=${var.timezone}",
  ]
  labels = {
    "traefik.enable"                                          = "true",
    "traefik.docker.network"                                  = "proxy",
    "traefik.http.routers.prowlarr.entrypoints"               = "https",
    "traefik.http.routers.prowlarr.rule"                      = "Host(`prowlarr.${var.domain}`)",
    "traefik.http.routers.prowlarr.middlewares"               = "https-redirectscheme@file",
    "traefik.http.routers.prowlarr.tls.certresolver"          = "cloudflare",
    "traefik.http.services.prowlarr.loadbalancer.server.port" = "9696",
  }
}

module "sonarr" {
  source = "./modules/docker-service"

  name    = "sonarr"
  image   = "lscr.io/linuxserver/sonarr@sha256:c19aa4ecdf03d73e1d5c901da33744cb7eb4d921f89bafed1ca264601d7fa224"
  restart = "always"

  networks = [
    { name = "proxy" },
  ]

  ports = [
    { external = 8989, internal = 8989 },
  ]

  bind_mounts = [
    { host_path = "${var.raid_root}/docker/sonarr", container_path = "/config" },
    { host_path = "${var.raid_root}/data/media/tvshows", container_path = "/tvshows" },
    { host_path = "${var.raid_root}/data/media/downloads", container_path = "/downloads" },
  ]

  env = [
    "PUID=1000",
    "PGID=1000",
    "TZ=${var.timezone}",
  ]
  labels = {
    "traefik.enable"                                        = "true",
    "traefik.docker.network"                                = "proxy",
    "traefik.http.routers.sonarr.entrypoints"               = "https",
    "traefik.http.routers.sonarr.rule"                      = "Host(`sonarr.${var.domain}`)",
    "traefik.http.routers.sonarr.middlewares"               = "https-redirectscheme@file",
    "traefik.http.routers.sonarr.tls.certresolver"          = "cloudflare",
    "traefik.http.services.sonarr.loadbalancer.server.port" = "8989",
  }
}

module "radarr" {
  source = "./modules/docker-service"

  name    = "radarr"
  image   = "lscr.io/linuxserver/radarr@sha256:119aaa4a4f7349bcd2a136c5373a0d7925b5479915c7dfe0c0ad352db2a6d438"
  restart = "always"

  networks = [
    { name = "proxy" },
  ]
  ports = [
    { external = 7878, internal = 7878 },
  ]

  bind_mounts = [
    { host_path = "${var.raid_root}/docker/radarr", container_path = "/config" },
    { host_path = "${var.raid_root}/data/media/movies", container_path = "/movies" },
    { host_path = "${var.raid_root}/data/media/downloads", container_path = "/downloads" },
  ]

  env = [
    "PUID=1000",
    "PGID=1000",
    "TZ=${var.timezone}",
  ]
  labels = {
    "traefik.enable"                                        = "true",
    "traefik.docker.network"                                = "proxy",
    "traefik.http.routers.radarr.entrypoints"               = "https",
    "traefik.http.routers.radarr.rule"                      = "Host(`radarr.${var.domain}`)",
    "traefik.http.routers.radarr.middlewares"               = "https-redirectscheme@file",
    "traefik.http.routers.radarr.tls.certresolver"          = "cloudflare",
    "traefik.http.services.radarr.loadbalancer.server.port" = "7878",
  }
}

module "qbittorrent" {
  source = "./modules/docker-service"

  name    = "qbittorrent"
  image   = "lscr.io/linuxserver/qbittorrent@sha256:304b19cf94bf4fda534e0b086cab9c5f1a9e139a8180c05c0ad7d2ba1526fa99" # 5.2.3_v2.0.14
  restart = "always"

  networks = [
    { name = "proxy" },
  ]

  ports = [
    { external = 8090, internal = 8090 },
    { external = 6881, internal = 6881 },
    { external = 6881, internal = 6881, protocol = "udp" },
  ]

  bind_mounts = [
    { host_path = "${var.raid_root}/docker/qbittorrent", container_path = "/config" },
    { host_path = "${var.raid_root}/data/media/downloads", container_path = "/downloads" },
  ]

  env = [
    "PUID=1000",
    "PGID=1000",
    "TZ=${var.timezone}",
    "WEBUI_PORT=8090"
  ]
  labels = {
    "traefik.enable"                                             = "true",
    "traefik.docker.network"                                     = "proxy",
    "traefik.http.routers.qbittorrent.entrypoints"               = "https",
    "traefik.http.routers.qbittorrent.rule"                      = "Host(`torrent.${var.domain}`)",
    "traefik.http.routers.qbittorrent.middlewares"               = "https-redirectscheme@file",
    "traefik.http.routers.qbittorrent.tls.certresolver"          = "cloudflare",
    "traefik.http.services.qbittorrent.loadbalancer.server.port" = "8090",
  }
}

module "jellyfin" {
  source = "./modules/docker-service"

  name    = "jellyfin"
  image   = "lscr.io/linuxserver/jellyfin@sha256:4f6d8dfc53ec5a1ddf7a90e4338972d57d7b0adff6dc88b53184f8285d0b594f"
  restart = "always"

  networks = [
    { name = "proxy" },
  ]

  ports = [
    { external = 8096, internal = 8096 }
  ]

  bind_mounts = [
    { host_path = "${var.raid_root}/docker/jellyfin", container_path = "/config" },
    { host_path = "${var.raid_root}/data/media/movies", container_path = "/data/movies" },
    { host_path = "${var.raid_root}/data/media/tvshows", container_path = "/data/tvshows" },
  ]

  env = [
    "PUID=1000",
    "PGID=1000",
    "TZ=${var.timezone}",
  ]

  labels = {
    "traefik.enable"                                          = "true",
    "traefik.docker.network"                                  = "proxy",
    "traefik.http.routers.jellyfin.entrypoints"               = "https",
    "traefik.http.routers.jellyfin.rule"                      = "Host(`jellyfin.${var.domain}`)",
    "traefik.http.routers.jellyfin.middlewares"               = "https-redirectscheme@file",
    "traefik.http.routers.jellyfin.tls.certresolver"          = "cloudflare",
    "traefik.http.services.jellyfin.loadbalancer.server.port" = "8096",
  }
}

module "glance" {
  source  = "./modules/docker-service"
  name    = "glance"
  image   = "glanceapp/glance@sha256:32ab73d80f2b8b5fb0735b0431deb36b93fbb6b2fb43592449b0178c8b83e350"
  restart = "unless-stopped"

  ports = [
    { external = 8888, internal = 8080 }
  ]

  networks = [
    { name = "proxy" },
  ]

  bind_mounts = [
    { host_path = "${var.raid_root}/docker/glance", container_path = "/app/config" }
  ]

  env = [
    "TZ=${var.timezone}",
    "HA_TOKEN=${var.glance_ha_token}",
    "IMMICH_KEY=${var.glance_immich_key}",
  ]

  labels = {
    "traefik.enable"                                        = "true",
    "traefik.docker.network"                                = "proxy",
    "traefik.http.routers.glance.entrypoints"               = "https",
    "traefik.http.routers.glance.rule"                      = "Host(`glance.${var.domain}`)",
    "traefik.http.routers.glance.tls"                       = "true",
    "traefik.http.services.glance.loadbalancer.server.port" = "8080",

  }
}

module "adguard" {
  source = "./modules/docker-service"

  name    = "adguard"
  image   = "adguard/adguardhome@sha256:aba9e3bf0613be3ba3755e1fc311b126e2c24bec25e18b6483894a88283074f0" # v0.107.79
  restart = "always"

  ports = [
    { external = 53, internal = 53, protocol = "tcp" },
    { external = 53, internal = 53, protocol = "udp" },
    { external = 81, internal = 80, protocol = "tcp" },
  ]

  networks = [
    { name = "proxy" },
  ]

  bind_mounts = [
    { host_path = "${var.raid_root}/docker/adguard/conf", container_path = "/opt/adguardhome/conf" },
    { host_path = "${var.ssd_root}/adguard/work", container_path = "/opt/adguardhome/work" },
  ]

  env = [
    "TZ=${var.timezone}"
  ]

  labels = {
    "traefik.enable"                                             = "true",
    "traefik.docker.network"                                     = "proxy",
    "traefik.http.middlewares.ag-redirect.redirectscheme.scheme" = "https",
    "traefik.http.routers.ag-http.entrypoints"                   = "http",
    "traefik.http.routers.ag-http.middlewares"                   = "ag-redirect",
    "traefik.http.routers.ag-http.rule"                          = "Host(`adguard.${var.domain}`)",
    "traefik.http.routers.ag-https.entrypoints"                  = "https",
    "traefik.http.routers.ag-https.rule"                         = "Host(`adguard.${var.domain}`)",
    "traefik.http.routers.ag-https.service"                      = "ag-svc",
    "traefik.http.routers.ag-https.tls"                          = "true",
    "traefik.http.routers.ag-https.tls.certresolver"             = "cloudflare",
    "traefik.http.services.ag-svc.loadbalancer.server.port"      = "80",
  }
}

module "mailpit_souply_staging" {
  source = "./modules/docker-service"

  name    = "mailpit-staging"
  image   = "axllent/mailpit@sha256:c96991d9bef73594c246d89ca81411d4e916f03e76a7d2d72fa2ab5dd3c9ce24"
  restart = "unless-stopped"

  networks = [
    { name = docker_network.internal.name },
  ]
  ports = [
    { external = 1025, internal = 1025, protocol = "tcp" },
    { external = 8025, internal = 8025, protocol = "tcp" },
  ]
}

module "vaultwarden" {
  source = "./modules/docker-service"

  name  = "vaultwarden"
  image = "vaultwarden/server@sha256:094b5689ed81549bd293418395c7cf495ae9d960fc2d4928cef2083ef913d912" # 1.37.2

  restart = "always"

  networks = [
    { name = "proxy" },
  ]

  ports = [
    { external = 8080, internal = 80 },
  ]

  bind_mounts = [
    { host_path = "${var.raid_root}/docker/vaultwarden", container_path = "/data" },
  ]

  env = [
    "DOMAIN=https://vault.${var.domain}",
    "ADMIN_TOKEN=${var.vaultwarden_admin_token}",
    "SIGNUPS_VERIFY=false",
    "SIGNUPS_ALLOWED=false",
    "WEBSOCKET_ENABLED=true",
    "SMTP_HOST=smtp.gmail.com",
    "SMTP_FROM=${var.vaultwarden_smtp_from}",
    "SMTP_PORT=587",
    "SMTP_SECURITY=starttls",
    "SMTP_USERNAME=${var.vaultwarden_smtp_username}",
    "SMTP_PASSWORD=${var.vaultwarden_smtp_password}",
    "IP_HEADER=X-Real-IP",
  ]

  labels = {
    "traefik.enable"                                                                  = "true",
    "traefik.docker.network"                                                          = "proxy",
    "traefik.http.routers.vaultwarden.entrypoints"                                    = "https",
    "traefik.http.routers.vaultwarden.rule"                                           = "Host(`vault.${var.domain}`)",
    "traefik.http.routers.vaultwarden.tls.certresolver"                               = "cloudflare",
    "traefik.http.services.vaultwarden.loadbalancer.server.port"                      = "80",
    "traefik.http.services.vaultwarden.loadbalancer.responseforwarding.flushinterval" = "100ms",
  }
}

module "immich_postgres" {
  source = "./modules/docker-service"

  name    = "immich_postgres"
  image   = "ghcr.io/immich-app/postgres@sha256:bcf63357191b76a916ae5eb93464d65c07511da41e3bf7a8416db519b40b1c23"
  restart = "always"

  networks = [
    { name = docker_network.immich.name, aliases = ["database"] },
  ]

  bind_mounts = [
    { host_path = "${var.ssd_root}/immich/db", container_path = "/var/lib/postgresql/data" },
  ]

  shm_size = 128

  env = [
    "POSTGRES_PASSWORD=${var.immich_db_password}",
    "POSTGRES_USER=postgres",
    "POSTGRES_DB=immich",
    "POSTGRES_INITDB_ARGS=--data-checksums",
    "DB_STORAGE_TYPE=HDD",
  ]
}

module "immich_redis" {
  source = "./modules/docker-service"

  name    = "immich_redis"
  image   = "docker.io/valkey/valkey@sha256:81db6d39e1bba3b3ff32bd3a1b19a6d69690f94a3954ec131277b9a26b95b3aa"
  restart = "always"

  networks = [
    { name = docker_network.immich.name, aliases = ["redis"] },
  ]

  data_path = "/data"
}

module "immich_machine_learning" {
  source = "./modules/docker-service"

  name    = "immich_machine_learning"
  image   = "ghcr.io/immich-app/immich-machine-learning@sha256:82d3f6a093455964508052e0b3bc55a91075b48b65be35e78b40774a72c1ebb3"
  restart = "always"

  networks = [
    { name = docker_network.immich.name, aliases = ["immich-machine-learning"] },
  ]

  data_path = "/cache"

  env = [
    "TZ=${var.timezone}",
    "IMMICH_VERSION=v3",
    "DB_USERNAME=postgres",
    "DB_DATABASE_NAME=immich",
    "DB_PASSWORD=${var.immich_db_password}",
    "UPLOAD_LOCATION=${var.raid_root}/data/immich",
    "DB_DATA_LOCATION=${var.ssd_root}/immich/db",
  ]
}

module "immich_server" {
  source = "./modules/docker-service"

  name       = "immich_server"
  image      = "ghcr.io/immich-app/immich-server@sha256:b434cb9287eea1471c9974845914d4dd328c9c2d652e446ed4930f99944f0ceb"
  restart    = "always"
  depends_on = [module.immich_postgres, module.immich_redis]

  networks = [
    { name = docker_network.immich.name, aliases = ["immich-server"] },
    { name = "proxy" },
  ]

  ports = [
    { external = 2283, internal = 2283 },
  ]

  bind_mounts = [
    { host_path = "${var.raid_root}/data/immich", container_path = "/data" },
    { host_path = "${var.ssd_root}/immich/thumbs", container_path = "/data/thumbs" },
    { host_path = "/etc/localtime", container_path = "/etc/localtime", read_only = true },
  ]

  device_requests = [
    { driver = "nvidia", count = -1, capabilities = ["gpu", "compute", "video"] },
  ]

  env = [
    "IMMICH_HELMET_FILE=true",
    "TZ=${var.timezone}",
    "IMMICH_VERSION=v3",
    "DB_USERNAME=postgres",
    "DB_DATABASE_NAME=immich",
    "DB_PASSWORD=${var.immich_db_password}",
    "UPLOAD_LOCATION=${var.raid_root}/data/immich",
    "DB_DATA_LOCATION=${var.ssd_root}/immich/db",
  ]

  labels = {
    "traefik.enable"                                        = "true",
    "traefik.docker.network"                                = "proxy",
    "traefik.http.routers.immich.entrypoints"               = "https",
    "traefik.http.routers.immich.rule"                      = "Host(`immich.${var.domain}`)",
    "traefik.http.routers.immich.middlewares"               = "https-redirectscheme@file,immich-buffering@file",
    "traefik.http.routers.immich.tls.certresolver"          = "cloudflare",
    "traefik.http.services.immich.loadbalancer.server.port" = "2283",
  }
}

module "traefik" {
  source = "./modules/docker-service"

  name    = "traefik"
  image   = "traefik@sha256:5203c3f39ca70de6790d964624e042463ffbd57715bc82be155cf224c0dd5144" # v3.7.11
  restart = "always"

  networks = [
    { name = "proxy" },
  ]

  ports = [
    { external = 80, internal = 80 },
    { external = 443, internal = 443 },
  ]

  bind_mounts = [
    { host_path = "${var.raid_root}/docker/traefik/cf-token", container_path = "/run/secrets/cf-token", read_only = true },
    { host_path = "${var.raid_root}/docker/traefik/traefik.yml", container_path = "/traefik.yml", read_only = true },
    { host_path = "${var.raid_root}/docker/traefik/config.yaml", container_path = "/config.yaml", read_only = true },
    { host_path = "${var.raid_root}/docker/traefik/acme.json", container_path = "/acme.json" },
    { host_path = "${var.raid_root}/docker/traefik/logs", container_path = "/var/log/traefik" },
    { host_path = "/var/run/docker.sock", container_path = "/var/run/docker.sock", read_only = true },
    { host_path = "/etc/localtime", container_path = "/etc/localtime", read_only = true },
  ]

  env = [
    "CF_DNS_API_TOKEN=${var.traefik_cf_token}",
    "TRAEFIK_DASHBOARD_CREDENTIALS=${var.traefik_dashboard_credentials}",
  ]

  labels = {
    "traefik.enable"                                                   = "true",
    "traefik.http.middlewares.redirect-to-https.redirectscheme.scheme" = "https",
    "traefik.http.middlewares.traefik-auth.basicauth.users"            = "${var.traefik_dashboard_credentials}",
    "traefik.http.routers.traefik-secure.entrypoints"                  = "https",
    "traefik.http.routers.traefik-secure.middlewares"                  = "traefik-auth",
    "traefik.http.routers.traefik-secure.rule"                         = "Host(`traefik-siauliai.${var.domain}`)",
    "traefik.http.routers.traefik-secure.service"                      = "api@internal",
    "traefik.http.routers.traefik-secure.tls"                          = "true",
    "traefik.http.routers.traefik-secure.tls.certresolver"             = "cloudflare",
    "traefik.http.routers.traefik-secure.tls.domains[0].main"          = "${var.domain}",
    "traefik.http.routers.traefik-secure.tls.domains[0].sans"          = "*.${var.domain}",
    "traefik.http.routers.traefik.entrypoints"                         = "http",
    "traefik.http.routers.traefik.middlewares"                         = "redirect-to-https",
    "traefik.http.routers.traefik.rule"                                = "Host(`traefik-siauliai.${var.domain}`)",
    "traefik.ping.entrypoint"                                          = "http",
    "traefik.ping.manualRouting"                                       = "true"
  }
}