resource "cloudflare_zero_trust_tunnel_cloudflared_config" "main" {
  account_id = var.cloudflare_account_id
  config = {
    ingress = [
      {
        hostname = "immich.manofoto.dpdns.org"
        origin_request = {
          access                   = null
          ca_pool                  = null
          connect_timeout          = null
          disable_chunked_encoding = null
          http2_origin             = null
          http_host_header         = null
          keep_alive_connections   = null
          keep_alive_timeout       = null
          match_sn_ito_host        = null
          no_happy_eyeballs        = null
          no_tls_verify            = null
          origin_server_name       = "immich.manofoto.dpdns.org"
          proxy_type               = null
          tcp_keep_alive           = null
          tls_timeout              = null
        }
        path    = null
        service = "https://192.168.1.212:443"
      },
      {
        hostname = "vault.manofoto.dpdns.org"
        origin_request = {
          access                   = null
          ca_pool                  = null
          connect_timeout          = null
          disable_chunked_encoding = null
          http2_origin             = null
          http_host_header         = null
          keep_alive_connections   = null
          keep_alive_timeout       = null
          match_sn_ito_host        = null
          no_happy_eyeballs        = null
          no_tls_verify            = null
          origin_server_name       = "vault.manofoto.dpdns.org"
          proxy_type               = null
          tcp_keep_alive           = null
          tls_timeout              = null
        }
        path    = null
        service = "https://192.168.1.212:443"
      },
      {
        hostname = "cloud.manofoto.dpdns.org"
        origin_request = {
          access                   = null
          ca_pool                  = null
          connect_timeout          = null
          disable_chunked_encoding = null
          http2_origin             = null
          http_host_header         = null
          keep_alive_connections   = null
          keep_alive_timeout       = null
          match_sn_ito_host        = null
          no_happy_eyeballs        = null
          no_tls_verify            = null
          origin_server_name       = "cloud.manofoto.dpdns.org"
          proxy_type               = null
          tcp_keep_alive           = null
          tls_timeout              = null
        }
        path    = null
        service = "https://192.168.1.212:443"
      },
      {
        hostname = "minio.manofoto.dpdns.org"
        origin_request = {
          access                   = null
          ca_pool                  = null
          connect_timeout          = null
          disable_chunked_encoding = null
          http2_origin             = null
          http_host_header         = null
          keep_alive_connections   = null
          keep_alive_timeout       = null
          match_sn_ito_host        = null
          no_happy_eyeballs        = null
          no_tls_verify            = null
          origin_server_name       = "minio.manofoto.dpdns.org"
          proxy_type               = null
          tcp_keep_alive           = null
          tls_timeout              = null
        }
        path    = null
        service = "https://192.168.1.212:443"
      },
      {
        hostname = "souply.manofoto.dpdns.org"
        origin_request = {
          access                   = null
          ca_pool                  = null
          connect_timeout          = null
          disable_chunked_encoding = null
          http2_origin             = null
          http_host_header         = null
          keep_alive_connections   = null
          keep_alive_timeout       = null
          match_sn_ito_host        = null
          no_happy_eyeballs        = null
          no_tls_verify            = null
          origin_server_name       = "souply.manofoto.dpdns.org"
          proxy_type               = null
          tcp_keep_alive           = null
          tls_timeout              = null
        }
        path    = null
        service = "https://192.168.1.212:443"
      },
      {
        hostname = "souply-api.manofoto.dpdns.org"
        origin_request = {
          access                   = null
          ca_pool                  = null
          connect_timeout          = null
          disable_chunked_encoding = null
          http2_origin             = null
          http_host_header         = null
          keep_alive_connections   = null
          keep_alive_timeout       = null
          match_sn_ito_host        = null
          no_happy_eyeballs        = null
          no_tls_verify            = null
          origin_server_name       = "souply-api.manofoto.dpdns.org"
          proxy_type               = null
          tcp_keep_alive           = null
          tls_timeout              = null
        }
        path    = null
        service = "https://192.168.1.212:443"
      },
      {
        hostname = "souply-minio.manofoto.dpdns.org"
        origin_request = {
          access                   = null
          ca_pool                  = null
          connect_timeout          = null
          disable_chunked_encoding = null
          http2_origin             = null
          http_host_header         = null
          keep_alive_connections   = null
          keep_alive_timeout       = null
          match_sn_ito_host        = null
          no_happy_eyeballs        = null
          no_tls_verify            = null
          origin_server_name       = "souply-minio.manofoto.dpdns.org"
          proxy_type               = null
          tcp_keep_alive           = null
          tls_timeout              = null
        }
        path    = null
        service = "https://192.168.1.212:443"
      },
      {
        hostname = "ssh-siauliai.manofoto.dpdns.org"
        origin_request = {
          access                   = null
          ca_pool                  = null
          connect_timeout          = null
          disable_chunked_encoding = null
          http2_origin             = null
          http_host_header         = null
          keep_alive_connections   = null
          keep_alive_timeout       = null
          match_sn_ito_host        = null
          no_happy_eyeballs        = null
          no_tls_verify            = null
          origin_server_name       = null
          proxy_type               = null
          tcp_keep_alive           = null
          tls_timeout              = null
        }
        path    = null
        service = "ssh://192.168.1.212:22"
      },
      {
        hostname = "obsidian.manofoto.dpdns.org"
        origin_request = {
          access                   = null
          ca_pool                  = null
          connect_timeout          = null
          disable_chunked_encoding = null
          http2_origin             = null
          http_host_header         = null
          keep_alive_connections   = null
          keep_alive_timeout       = null
          match_sn_ito_host        = null
          no_happy_eyeballs        = null
          no_tls_verify            = null
          origin_server_name       = "obsidian.manofoto.dpdns.org"
          proxy_type               = null
          tcp_keep_alive           = null
          tls_timeout              = null
        }
        path    = null
        service = "https://192.168.1.212:443"
      },
      {
        hostname       = null
        origin_request = null
        path           = null
        service        = "http_status:404"
      },
    ]
    origin_request = null
  }
  source    = "cloudflare"
  tunnel_id = var.tunnel_id
}
