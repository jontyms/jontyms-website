---
title: "Selfhosting v3"
date: 2023-03-26T15:03:14-04:00
draft: false
---
### Here are my goals for my selfhosting setup v3.
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

### Here is the basic plan of how to achieve this
- Gitea for git server
- Rennovatebot for updates
- Quay for image registry 
- Woodpecker for ci
- Clair for scanning 
- Traefik for reverse proxy
- Tailscale for networking
- Tailscale funnels for public access
- Podman for rootless 
- Keycloak for auth

Overall I hope this setup will decrease the amount of ongoing maintenance, alert me to problems before they break stuff, and make sure my apps are up to date. 

### Ongoing Questions
- How to keep up with projects changelogs?
- Which logging framework to use?
- Which alerting and monitoring stack to use?
- How to backup databases in containers safely?

## Comments
{{< chat selfhostingv3 >}}