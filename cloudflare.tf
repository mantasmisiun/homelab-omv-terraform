provider "cloudflare" {
  # Configuration options
}

resource "cloudflare_dns_record" "lab_instance" {
  for_each = local.lab_instances
  content  = local.tunnel_target
  proxied  = true
  ttl      = 1
  type     = "CNAME"
  zone_id  = var.zone_id
  name     = each.key
}

resource "cloudflare_dns_record" "ssh_siauliai" {
  content = local.tunnel_target
  proxied = true
  ttl     = 1
  type    = "CNAME"
  zone_id = var.zone_id
  name    = var.ssh_subdomain
  lifecycle {
    prevent_destroy = true
  }
}