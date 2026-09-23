module "glance_agent" {
  source = "./modules/docker-service"

  name  = "glance-agent-tf"
  image = "glanceapp/agent:v0.1.0@sha256:f57ee10cd2f23e66ae6a8325fb6106e12878e1f985a88aaa914687d14489017c"


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
  image       = "ghcr.io/flaresolverr/flaresolverr:v3.5.2@sha256:4ad0ed7de64622f9823594bf7bc237149158fca881f875aafbdd8456f6467134"
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
  image   = "nginx:1.31.6-alpine@sha256:adad2ae9204d0fd7a34f40299bc838c3782be1293b10005eac4315ff5a1abf4e" # 1.31.4-alpine
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

  name  = "papra"
  image = "ghcr.io/papra-hq/papra:26.6.2-rootless@sha256:a281cb44176dbe5323e0f7ea2d6fd34d58914a3a8525c36437a086d1d7c4fef8"

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
    "APP_BASE_URL=https://papra.${var.domain}",
    "TRUSTED_ORIGINS=http://${var.omv_ip}:1221,https://papra.${var.domain}",
    "AUTH_IS_REGISTRATION_ENABLED=false",
    "AUTH_IP_ADDRESS_HEADERS=x-forwarded-for",
    "DOCUMENTS_OCR_LANGUAGES=lit,eng",
    "DOCUMENT_STORAGE_MAX_UPLOAD_SIZE=104857600",
    "INTAKE_EMAILS_IS_ENABLED=true",
    "INTAKE_EMAILS_DRIVER=owlrelay",
    "OWLRELAY_API_KEY=${var.owlrelay_api_key}",
    "INTAKE_EMAILS_WEBHOOK_SECRET=${var.email_webhook_secret}",
    "OWLRELAY_WEBHOOK_URL=https://papra.${var.domain}/api/intake-emails/ingest",
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
  image   = "ollama/ollama:0.33.2@sha256:020e4134285e2ef4d8fd801234176de3b4faadc992a3eb06c8e66a2f9d4c4ba2"
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
    "OLLAMA_FLASH_ATTENTION=1",
    "OLLAMA_KV_CACHE_TYPE=q8_0",

  ]
  device_requests = [
    { driver = "nvidia", device_ids = ["GPU-9a425c82-9352-6223-6816-8ad979aaa531"], capabilities = ["gpu"] },
  ]
}

module "homeassistant" {
  source = "./modules/docker-service"

  name    = "homeassistant"
  image   = "ghcr.io/home-assistant/home-assistant:2026.9.3@sha256:1aeeebfba2a977182dfc60495ebf24460ac8f0710cac34d86e83aaad53ee4892"
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
  image   = "lscr.io/linuxserver/prowlarr:2.6.5.5623-ls162@sha256:f2b26429893d4c4cb71941b7ee50b1bdecd9d5f9f9e02d5410615e9f4f7c8d95"
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
  image   = "lscr.io/linuxserver/sonarr:4.0.20.3014-ls325@sha256:a5c1a5fecbef946927ab90ad68df319ac5fe644057e5fc18cd993f01ac07b2b2"
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
  image   = "lscr.io/linuxserver/radarr:6.3.0.10514-ls314@sha256:119aaa4a4f7349bcd2a136c5373a0d7925b5479915c7dfe0c0ad352db2a6d438"
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
  image   = "lscr.io/linuxserver/qbittorrent:5.2.3_v2.0.14-ls473@sha256:304b19cf94bf4fda534e0b086cab9c5f1a9e139a8180c05c0ad7d2ba1526fa99"
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
  image   = "lscr.io/linuxserver/jellyfin:12.1ubu2604-ls49@sha256:6212319152eef0a44bf0ec34536df164c5d358e2cc27e7409d2f26138e73ad8e"
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

  device_requests = [
    { driver = "nvidia", device_ids = ["GPU-0e39a53c-6dc4-24c6-24b2-d351604aa6c4"], capabilities = ["gpu", "compute", "video", "utility"] },
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
  image   = "glanceapp/glance:v0.8.6@sha256:9dfb09470b207dcb67ac715994bdb1929374ba3f9c0d7df7462c24adf10fd073"
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
  image   = "adguard/adguardhome:v0.107.79@sha256:aba9e3bf0613be3ba3755e1fc311b126e2c24bec25e18b6483894a88283074f0" # v0.107.79
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
  image   = "axllent/mailpit:v1.31.2@sha256:74d609a42ec279aa63c6b4622a6fa9b5408d1ad5b1d76a1c4be40a265ce0863d"
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
  image = "docker.io/vaultwarden/server:1.37.3@sha256:4ecafc9049c7d878c7717d1ce4f9059d706758c78b8fa42e5ead21f4b2dfc770"

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
  image   = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0@sha256:bcf63357191b76a916ae5eb93464d65c07511da41e3bf7a8416db519b40b1c23"
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
  image   = "docker.io/valkey/valkey:9@sha256:70739f85ad2ee01a726a965584a0f94895f01b0c60b3cc8b0aeef11eaa6888cf"
  restart = "always"

  networks = [
    { name = docker_network.immich.name, aliases = ["redis"] },
  ]

  data_path = "/data"
}

module "immich_machine_learning" {
  source = "./modules/docker-service"

  name    = "immich_machine_learning"
  image   = "ghcr.io/immich-app/immich-machine-learning:v3.2.2-cuda@sha256:38001e84ce46206e9e019d8ee7f567bf55914f019dff8f6a70d02fd93bb14073"
  restart = "always"

  networks = [
    { name = docker_network.immich.name, aliases = ["immich-machine-learning"] },
  ]

  data_path = "/cache"

  device_requests = [
    { driver = "nvidia", device_ids = ["GPU-0e39a53c-6dc4-24c6-24b2-d351604aa6c4"], capabilities = ["gpu", "compute", "utility"] },
  ]

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
  image      = "ghcr.io/immich-app/immich-server:v3.2.2@sha256:79cc1623323d5894922686d8743b4780181428f98eecbfb58ce12c41ef02d1ea"
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
    { driver = "nvidia", device_ids = ["GPU-0e39a53c-6dc4-24c6-24b2-d351604aa6c4"], capabilities = ["gpu", "compute", "video"] },
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
  image   = "traefik:v3.7.12@sha256:9c2a54d87f76f5c2f5f2682c68394af92fb12c0a2686798d6462a3f84bd78eaf"
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
    "traefik.http.middlewares.traefik-auth.basicauth.users"            = var.traefik_dashboard_credentials,
    "traefik.http.routers.traefik-secure.entrypoints"                  = "https",
    "traefik.http.routers.traefik-secure.middlewares"                  = "traefik-auth",
    "traefik.http.routers.traefik-secure.rule"                         = "Host(`traefik-siauliai.${var.domain}`)",
    "traefik.http.routers.traefik-secure.service"                      = "api@internal",
    "traefik.http.routers.traefik-secure.tls"                          = "true",
    "traefik.http.routers.traefik-secure.tls.certresolver"             = "cloudflare",
    "traefik.http.routers.traefik-secure.tls.domains[0].main"          = var.domain,
    "traefik.http.routers.traefik-secure.tls.domains[0].sans"          = "*.${var.domain}",
    "traefik.http.routers.traefik.entrypoints"                         = "http",
    "traefik.http.routers.traefik.middlewares"                         = "redirect-to-https",
    "traefik.http.routers.traefik.rule"                                = "Host(`traefik-siauliai.${var.domain}`)",
    "traefik.ping.entrypoint"                                          = "http",
    "traefik.ping.manualRouting"                                       = "true"
  }
}

module "couchdb_obsidian" {
  source = "./modules/docker-service"

  name    = "couchdb-obsidian"
  image   = "couchdb:3.5.2.1@sha256:8cf5f8442585c346d2717ff0ad95605731d2f19f67b8367840baa8d3b24ebc31"
  restart = "always"

  networks = [{ name = "proxy" }]

  bind_mounts = [
    { host_path = "${var.raid_root}/docker/couchdb/couchdb-data", container_path = "/opt/couchdb/data" },
    { host_path = "${var.raid_root}/docker/couchdb/couchdb-etc", container_path = "/opt/couchdb/etc/local.d" },
  ]

  env = [
    "COUCHDB_USER=${var.couchdb_user}",
    "COUCHDB_PASSWORD=${var.couchdb_password}",
  ]

  labels = {
    "traefik.enable"                                         = "true"
    "traefik.docker.network"                                 = "proxy"
    "traefik.http.routers.couchdb.entrypoints"               = "https"
    "traefik.http.routers.couchdb.rule"                      = "Host(`obsidian.${var.domain}`)"
    "traefik.http.routers.couchdb.tls"                       = "true"
    "traefik.http.services.couchdb.loadbalancer.server.port" = "5984"

  }
}

module "paperless" {
  source  = "./modules/docker-service"
  name    = "paperless_ngx"
  image   = "ghcr.io/paperless-ngx/paperless-ngx:v3.2.1@sha256:7391e75706d9dafe84dd2235df12c932c0034a4f453725437d07918eee7a35b8"
  restart = "always"

  depends_on = [module.paperless_postgres, module.paperless_redis, module.paperless_gotenberg, module.paperless_tika]

  ports = [
    { external = 8000, internal = 8000 },
  ]

  networks = [
    { name = docker_network.paperless.name, aliases = ["paperless"] },
    { name = "proxy" },
  ]

  bind_mounts = [
    { host_path = "${var.raid_root}/docker/paperless/data", container_path = "/usr/src/paperless/data" },
    { host_path = "${var.raid_root}/data/paperless/media", container_path = "/usr/src/paperless/media" },
    { host_path = "${var.raid_root}/docker/paperless/export", container_path = "/usr/src/paperless/export" },
    { host_path = "${var.raid_root}/docker/paperless/consume", container_path = "/usr/src/paperless/consume" },
  ]

  env = [
    "TZ=${var.timezone}",
    "USERMAP_UID=1000",
    "USERMAP_GID=1000",
    "PAPERLESS_URL=https://paperless.${var.domain}",
    "PAPERLESS_SECRET_KEY=${var.paperless_secret_key}",
    "PAPERLESS_REDIS=redis://redis:6379",
    "PAPERLESS_DBHOST=postgres",
    "PAPERLESS_DBNAME=${var.paperless_postgres_db}",
    "PAPERLESS_DBUSER=${var.paperless_postgres_user}",
    "PAPERLESS_DBPASS=${var.paperless_postgres_password}",
    "PAPERLESS_TIKA_ENABLED=1",
    "PAPERLESS_TIKA_GOTENBERG_ENDPOINT=http://gotenberg:3000",
    "PAPERLESS_TIKA_ENDPOINT=http://tika:9998",
    "PAPERLESS_OCR_LANGUAGE=lit+eng",
    "PAPERLESS_OCR_LANGUAGES=lit",
  ]

  labels = {
    "traefik.enable"                                           = "true",
    "traefik.docker.network"                                   = "proxy",
    "traefik.http.routers.paperless.entrypoints"               = "https",
    "traefik.http.routers.paperless.rule"                      = "Host(`paperless.${var.domain}`)",
    "traefik.http.routers.paperless.middlewares"               = "https-redirectscheme@file",
    "traefik.http.routers.paperless.tls"                       = "true",
    "traefik.http.services.paperless.loadbalancer.server.port" = "8000",
  }
}

module "paperless_postgres" {
  source  = "./modules/docker-service"
  name    = "paperless_postgres"
  image   = "docker.io/library/postgres:18.6@sha256:86c951e05bf56c93d95d397747fb8820ac76cc3bedb78f43abd83eedbe3666ae"
  restart = "always"

  networks = [{ name = docker_network.paperless.name, aliases = ["postgres"] }]

  bind_mounts = [
    { host_path = "${var.ssd_root}/paperless/db", container_path = "/var/lib/postgresql" },
  ]
  env = [
    "TZ=${var.timezone}",
    "POSTGRES_DB=${var.paperless_postgres_db}",
    "POSTGRES_USER=${var.paperless_postgres_user}",
    "POSTGRES_PASSWORD=${var.paperless_postgres_password}"
  ]
}

module "paperless_redis" {
  source  = "./modules/docker-service"
  name    = "paperless_redis"
  image   = "docker.io/library/redis:8.8.3@sha256:5c625b86e04d109e4df082723ddbe3064187c27272f2c1c1787dc70c02d1b4d2"
  restart = "always"

  networks = [{ name = docker_network.paperless.name, aliases = ["redis"] }]

  bind_mounts = [
    { host_path = "${var.ssd_root}/paperless/redis", container_path = "/data" },
  ]

  env = [
    "TZ=${var.timezone}"
  ]
}

module "paperless_gotenberg" {
  source = "./modules/docker-service"

  name    = "paperless_gotenberg"
  image   = "docker.io/gotenberg/gotenberg:8.37.0@sha256:f29984bd1e226bf1b93ba90af06000afa8b315853e99d27b9aaa41b93f15c769"
  restart = "always"

  networks = [{ name = docker_network.paperless.name, aliases = ["gotenberg"] }]

  command = [
    "gotenberg",
    "--chromium-disable-javascript=true",
    "--chromium-allow-list=file:///tmp/.*",
  ]

  env = [
    "TZ=${var.timezone}"
  ]
}

module "paperless_tika" {
  source  = "./modules/docker-service"
  name    = "paperless_tika"
  image   = "docker.io/apache/tika:3.3.1.0@sha256:90b7fa1dc018434075fce9e1d9b88b1e3d0ea6979d0cf86e116c79a8073ae973"
  restart = "always"

  networks = [{ name = docker_network.paperless.name, aliases = ["tika"] }]

  env = [
    "TZ=${var.timezone}"
  ]
}

module "open_webui" {
  source = "./modules/docker-service"

  name    = "open_webui"
  image   = "ghcr.io/open-webui/open-webui:v0.11.4@sha256:9591b13f13843c7721c2b8eaf7382846c81b3ffe126526d1888d1fed50c6a33f"
  restart = "always"

  depends_on = [module.ollama]

  networks = [
    { name = docker_network.internal.name },
    { name = "proxy" },
  ]

  ports = [
    { external = 3001, internal = 8080 },
  ]

  bind_mounts = [
    { host_path = "${var.raid_root}/docker/open-webui/data", container_path = "/app/backend/data" },
  ]

  env = [
    "TZ=${var.timezone}",
    "OLLAMA_BASE_URL=http://ollama:11434"
  ]

  labels = {
    "traefik.enable"                                      = "true",
    "traefik.docker.network"                              = "proxy",
    "traefik.http.routers.chat.entrypoints"               = "https",
    "traefik.http.routers.chat.rule"                      = "Host(`chat.${var.domain}`)",
    "traefik.http.routers.chat.middlewares"               = "https-redirectscheme@file",
    "traefik.http.routers.chat.tls"                       = "true",
    "traefik.http.services.chat.loadbalancer.server.port" = "8080",
  }
}

module "paperless_ai" {
  source  = "./modules/docker-service"
  name    = "paperless_ai"
  image   = "docker.io/clusterzx/paperless-ai:3.0.9@sha256:2b65888163fd59716f1c8285b31c5bd0b30c9c3c192c42b516688e3887d4ba60"
  restart = "always"

  depends_on = [module.ollama, module.paperless]

  networks = [
    { name = docker_network.paperless.name },
    { name = docker_network.internal.name },
  ]

  ports = [
    { external = 3000, internal = 3000 },
  ]

  bind_mounts = [
    { host_path = "${var.raid_root}/docker/paperless/ai", container_path = "/app/data" },
  ]

  env = [
    "TZ=${var.timezone}",
    "PAPERLESS_API_URL=http://paperless:8000/api",
    "PAPERLESS_API_TOKEN=${var.paperless_api_token}",
    "PAPERLESS_USERNAME=${var.paperless_admin_user}",
    "AI_PROVIDER=ollama",
    "OLLAMA_API_URL=http://ollama:11434",
    "OLLAMA_MODEL=qwen3.5:4b",
    "RAG_SERVICE_URL=http://localhost:8000",
    "RAG_SERVICE_ENABLED=true",
    "SCAN_INTERVAL=*/30 * * * *",
    "PAPERLESS_URL=http://paperless:8000",
  ]

}

module "paperless_gpt" {
  source = "./modules/docker-service"

  name       = "paperless_gpt"
  image      = "docker.io/icereed/paperless-gpt:v0.28.0@sha256:413af73ff5415e1f61327ccb1c63cb14e84e86b761969be6eaaee61b4f39bef4"
  restart    = "always"
  depends_on = [module.ollama, module.paperless]

  networks = [
    { name = docker_network.paperless.name },
    { name = docker_network.internal.name },
  ]

  ports = [
    { external = 3002, internal = 8080 },
  ]

  bind_mounts = [
    { host_path = "${var.raid_root}/docker/paperless/gpt", container_path = "/app/prompts" },
  ]

  env = [
    "PAPERLESS_BASE_URL=http://paperless:8000",
    "PAPERLESS_API_TOKEN=${var.paperless_api_token}",
    "LLM_PROVIDER=ollama",
    "LLM_MODEL=qwen3.5:4b",
    "OLLAMA_HOST=http://ollama:11434",
    "OLLAMA_CONTEXT_LENGTH=8192",
    "TOKEN_LIMIT=1000",
    "LLM_LANGUAGE=Lithuanian",
    "OCR_PROVIDER=llm",
    "VISION_LLM_PROVIDER=ollama",
    "VISION_LLM_MODEL=qwen3.5:4b",
    "AUTO_OCR_TAG=paperless-gpt-ocr-auto",
    "AUTO_TAG=paperless-gpt-auto",
    "MANUAL_TAG=paperless-gpt-manual",
    "PDF_OCR_TAGGING=true",
    "PDF_OCR_COMPLETE_TAG=paperless-gpt-ocr-complete",
    "PDF_UPLOAD=false",
    "LOG_LEVEL=INFO",
  ]

}