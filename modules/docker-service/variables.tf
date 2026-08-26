variable "name" {
  type        = string
  description = "Container name and Traefik router name."
}

variable "image" {
  type        = string
  description = "Full reference with tag, e.g. traefik/whoami:v1.11."
}

variable "ports" {
  type = list(object({
    internal = number
    external = number
    protocol = optional(string, "tcp")
  }))
  default = []
}

variable "data_path" {
  type        = string
  description = "the path inside the container where the service stores data; omit for services with none"
  default     = null
}

variable "bind_mounts" {
  type = list(object({
    host_path      = string
    container_path = string
    read_only      = optional(bool, false)
  }))
  description = "Host directories to expose inside the container."
  default     = []
}

variable "devices" {
  type = list(object({
    host_path      = string
    container_path = string
  }))
  description = "Host devices to expose inside the container."
  default     = []
}

variable "network_mode" {
  type    = string
  default = "bridge"
}

variable "env" {
  type        = list(string)
  description = "env variables needed for container"
  default     = []
}

variable "volume_name" {
  type    = string
  default = null
}

variable "restart" {
  type        = string
  description = "Options whether the container comes back on its own and when"
  default     = "always"
}

variable "user" {
  type    = string
  default = null
}

variable "device_requests" {
  type = list(object({
    driver       = optional(string)
    count        = optional(number)
    capabilities = optional(list(string))
  }))
  default = []
}

variable "privileged" {
  type    = bool
  default = false
}

variable "labels" {
  type    = map(string)
  default = {}
}

variable "shm_size" {
  type    = number
  default = null
}

variable "networks" {
  type = list(object({
    name    = string
    aliases = optional(list(string), [])
  }))
  default = []
}