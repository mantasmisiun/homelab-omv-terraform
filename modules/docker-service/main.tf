resource "docker_image" "this" {
  name         = var.image
  keep_locally = true
}

resource "docker_volume" "data" {
  count = var.data_path == null ? 0 : 1
  name  = var.volume_name == null ? "${var.name}-data" : var.volume_name
}

resource "docker_container" "this" {
  name    = var.name
  image   = docker_image.this.image_id
  restart = var.restart

  dynamic "networks_advanced" {
    for_each = var.networks
    content {
      name    = networks_advanced.value.name
      aliases = networks_advanced.value.aliases
    }
  }
  network_mode = var.network_mode
  user         = var.user

  dynamic "ports" {
    for_each = var.ports
    content {
      internal = ports.value.internal
      external = ports.value.external
      protocol = ports.value.protocol
    }
  }

  dynamic "volumes" {
    for_each = var.bind_mounts
    content {
      host_path      = volumes.value.host_path
      container_path = volumes.value.container_path
      read_only      = volumes.value.read_only
    }
  }

  dynamic "volumes" {
    for_each = var.data_path == null ? [] : [var.data_path]
    content {
      volume_name    = docker_volume.data[0].name
      container_path = volumes.value
    }
  }
  dynamic "device_requests" {
    for_each = var.device_requests
    content {
      driver       = device_requests.value.driver
      count        = device_requests.value.count
      capabilities = device_requests.value.capabilities
    }
  }
  env = var.env

  shm_size = var.shm_size

  privileged = var.privileged

  dynamic "devices" {
    for_each = var.devices
    content {
      host_path      = devices.value.host_path
      container_path = devices.value.container_path
    }
  }

  dynamic "labels" {
    for_each = var.labels
    content {
      label = labels.key
      value = labels.value
    }
  }
}
