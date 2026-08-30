provider "docker" {
  host = "ssh://root@${var.omv_ip}"
  registry_auth {
    address  = "registry-1.docker.io"
    username = var.dockerhub_username
    password = var.dockerhub_token
  }
}

resource "docker_network" "internal" {
  name   = "internal"
  driver = "bridge"
}

resource "docker_network" "immich" {
  name   = "immich"
  driver = "bridge"
}

resource "docker_network" "nextcloud" {
  name   = "nextcloud"
  driver = "bridge"
}