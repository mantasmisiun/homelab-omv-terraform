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

resource "cloudflare_dns_record" "netbird" {
  zone_id = var.zone_id
  name    = "netbird"
  type    = "A"
  content = "92.5.186.226"
  proxied = false
  ttl     = 300
  comment = "NetBird control plane on the Oracle VM"
}
