---
title: "Selfhostingv3"
date: 2023-03-26T15:03:14-04:00
draft: true
---
Here are my goals for my selfhosting setup v3.
- All containers updated with gitops
- All containers scanned for cves
- All apps that support use federated auth (ouath openidc ldap etc.)
- All containers that don't receive frequent updates are built locally instead 
- Container engine runs without root (maybe a v4)
- All databases dumped before backup
- Backups
- Local backups for devices
- Logging containers logs
- Altering 

Here is the basic plan of how to achieve this
- Gitea for git server
- Rennovatebot for updates

- Docker-compose 
- Quay for image registry 
- Woodpecker for ci

- Clair for scanning 

- Traefik for reverse proxy

- Tailscale for local services

- Tailscale funnels for public

- Podman for rootless 

- Keycloak for auth


## Comments
{{< chat selfhostingv3 >}}