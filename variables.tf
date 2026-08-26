variable "zone_id" {
  type        = string
  description = "Zone ID of the domain for which the DNS records are being created."
  validation {
    condition     = length(var.zone_id) == 32
    error_message = "Wrong zone id. Zone ID can be found in Cloudflare DNS overview page. Check for 32 digit code."
  }
}

variable "tunnel_id" {
  type        = string
  description = "Cloudflare tunnel ID"
}

variable "ssh_subdomain" {
  type        = string
  description = "subdomain of the DDNS"
}

locals {
  tunnel_target = "${var.tunnel_id}.cfargotunnel.com"
  lab_instances = {
    immich       = "photo library"
    cloud        = "file sync"
    vault        = "passwords"
    minio        = "souply staging storage"
    souply-api   = "souply staging server subdomain"
    souply       = "souply staging website"
    souply-minio = "souply dev minio storage"
  }
}

variable "papra_auth_secret" {
  type      = string
  sensitive = true
}

variable "glance_ha_token" {
  type      = string
  sensitive = true
}

variable "glance_immich_key" {
  type      = string
  sensitive = true
}

variable "vaultwarden_admin_token" {
  type      = string
  sensitive = true
}

variable "vaultwarden_smtp_from" {
  type      = string
  sensitive = true
}

variable "vaultwarden_smtp_username" {
  type      = string
  sensitive = true
}

variable "vaultwarden_smtp_password" {
  type      = string
  sensitive = true
}

variable "immich_db_password" {
  type      = string
  sensitive = true
}

variable "raid_root" {
  type        = string
  description = "Location for data that needs to be redundant"
}

variable "ssd_root" {
  type        = string
  description = "Location on ssd for data that can be easily generated but benefit for better drive speeds"
}

variable "domain" {
  type        = string
  description = "Owned domain"
}

variable "omv_ip" {
  type        = string
  description = "IP of the server where docker containers will be hosted"
}

variable "timezone" {
  type        = string
  description = "Timezone where the server is located"
}

variable "traefik_cf_token" {
  type        = string
  description = "Cloudflare token for DNS API"
  sensitive   = true
}

variable "traefik_dashboard_credentials" {
  type        = string
  description = "Dashboard login credentials"
  sensitive   = true
}

variable "dockerhub_username" {
  type        = string
  description = "Account username on docker hub"
  sensitive   = true
}

variable "dockerhub_token" {
  type        = string
  description = "Personal access token created on docker hub for reading public repositories"
  sensitive   = true
}