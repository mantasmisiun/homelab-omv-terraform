# Homelab infrastructure as code

Terraform configuration for a single-host Docker estate: **20 containers**, their networks, volumes
and Traefik routing, plus the public DNS records that point at them.

This replaced a hand-managed Docker Compose setup. The migration was done in place, service by
service, without rebuilding any data, including a 1.5 TB photo library and its Postgres database.

## What it manages

| | |
|---|---|
| **Photos** | Immich (server, machine learning, Postgres, Valkey) |
| **Media** | Jellyfin |
| **Home** | Home Assistant (Zigbee coordinator passed through), AdGuard Home |
| **Documents & secrets** | Papra, Vaultwarden |
| **Platform** | Traefik, Glance dashboard and its metrics agent, Ollama, a static stats page |
| **DNS** | Cloudflare records for every internet-facing service |

Plus a handful of supporting containers not listed individually.

## Design decisions

**Replace, don't import.** The host ran ~19 Docker Compose projects. Importing them would have left
two tools believing they owned the same containers, and the compose plugin's web UI could recreate a
stack at any time, and Terraform would then plan to revert it, permanently. Instead each service was
taken down from Compose and brought back up under Terraform, one at a time, with its data left
untouched on disk.

**Every image is pinned by digest.** Not `:latest`, and mostly not even a tag. A digest is a content
address: it cannot silently become different bytes, and it keeps `terraform plan` stable. With a
mutable tag, an upstream retag shows up as an unrequested replacement. Updates are therefore an
explicit edit to this repository, which is the point.

**One module, twenty services.** They are all the same shape: a container with mounts, ports,
environment and labels. So `modules/docker-service` expresses that shape once. Variable-length
parts (`networks`, `ports`, `bind_mounts`, `devices`, `device_requests`) are lists of objects
unpacked by `dynamic` blocks; optional single values (`user`, `shm_size`, `privileged`) default to
`null` so Terraform simply omits them.

**Storage is tiered by purpose, and the tier is visible in the path.**

```
<raid>/docker/<service>    configuration and application state, must be backed up
<raid>/data/<service>      bulk content
<ssd>/<service>            fast and losable
```

The SSD holds the Immich database and thumbnails: small files read randomly, which is where the
seek penalty of spinning disks actually hurts. Transcoded video stays on the array: it is bulk,
read sequentially, and expensive to regenerate despite being derived data. "Regenerable" and "cheap
to regenerate" are not the same test.

**Routing is container labels, with one deliberate exception.** Traefik discovers services from
Docker labels emitted by the module. Two routes remain in Traefik's file provider because labels
cannot express them: Home Assistant runs with host networking and so has no address on any Docker
network, and one route points at a service that isn't a container at all.

## Deliberately not managed

- **`cloudflared`** carries SSH into this host over a Cloudflare Tunnel. It is the way in when the
  VPN is down, and it must not depend on the tool being used to rebuild the host around it.
- **`wireguard`** is the other way in, for the same reason.
- **A monitoring agent** that mounts the host root filesystem and both container sockets. Managing
  it would mean declaring that level of access in a public repository.

Two container images are pinned by the upstream project's own compose file rather than independently.
Bumping them alone would mean running a combination upstream has never tested, and the failure would
look like an application bug.

## Layout

```
main.tf         provider requirements, S3-compatible remote state (partial config)
docker.tf       Docker provider, registry credentials, networks
services.tf     one module call per service
cloudflare.tf   DNS records
variables.tf    inputs and locals
modules/docker-service/
```

The module takes: `name`, `image`, `networks`, `ports`, `bind_mounts`, `data_path`, `volume_name`,
`env`, `labels`, `devices`, `device_requests`, `user`, `privileged`, `network_mode`, `shm_size`,
`restart`.

## Running it

State lives in an S3-compatible object store, configured **partially** so that the bucket and
endpoint, which identify the account, stay out of version control:

```sh
cp backend.hcl.example backend.hcl        # fill in
cp terraform.tfvars.example terraform.tfvars   # fill in
terraform init -backend-config=backend.hcl
terraform plan
```

Credentials for the object store go in the environment; everything else is in `terraform.tfvars`.
Both files, and the state itself, are gitignored.

The Docker provider connects to the host over SSH, so `terraform apply` needs an SSH key that
reaches it. Nothing is exposed on the network for Terraform's benefit, and the Docker daemon does
not listen on a socket.

## Notes

Container **names** are load-bearing: an external backup job runs `docker exec` against the Postgres
container by name, so renaming it silently breaks the nightly database dump.

`keep_locally = true` on images is not just about saving bandwidth. When a registry rate limit
interrupted an apply mid-flight, leaving containers destroyed and replacement images not yet
pulled, the previous images were still on disk. Reverting the pins restored service without any
network access at all.
