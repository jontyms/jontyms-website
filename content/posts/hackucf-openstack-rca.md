---
title: "Hack@UCF May 2025 Kubernetes Outage"
date: 2025-05-18T20:00:44-04:00
draft: true
author: "Jonathan Styles"
tags: [""]
description: A root cause analysis of the outage we had on May 17th - 18th 2025. The outage resulted in the SSO platform keycloak being down most of 2 days their resulting in users not being able to login and administer their Virtual Machines.
---
# Introduction

I help run a Private Cloud for my university's Cybersecurity Club, Hack@UCF. (More Details Here)[]. This a incident report I wrote for fun and education about the outage we had on May 17th - 18th 2025. The outage resulted in the SSO platform keycloak being down most of 2 days their resulting in users not being able to login and administer their Virtual Machines.

# Timeline
In UTC because why not

- 2025-05-15 00:48Z - Engineer notices volumes stuck in detaching state after routine OKD cluster update. No action is taken, application were not affected at the time.

- 2025-05-17 01:00Z - Openstack cluster update procedures begin

- 2025-05-17 02:00Z - OKD cluster is shutdown in preparation for node restarts, user facing services go down

- 2025-05-17 03:00Z - Openstack compute nodes come back online, OKD vms started.

- 2025-05-17 03:10Z - Volumes were observed to still be stuck in detaching state

- 2025-05-17 04:00Z - Engineers go to bed

- 2025-05-17 11:00Z - IR Call Resumes

- 2025-05-17 11:00Z - Engineers decide to start the OKD cluster despite openstack volumes being stuck in detaching

- 2025-05-17 11:30Z - Application pods fail to start due to broken pvcs

- 2025-05-18 00:00Z - Engineers decide to replace the node with broken volumes, new nodes have to be manually provisioned due to bugs with OKD node deployment.

- 2025-05-18 00:40Z - Engineers decide to investigate the Cinder volume storage node the volumes are on and determine that Cinder pods were never started.

- 2025-05-18 01:10Z - Volumes successfully detach and attach to new node.  Application come online.

- 2025-05-18 01:20Z - Worker nodes run out of RAM, Application pods fail to schedule.

- 2025-05-18 01:40Z - New worker nodes are manually provisioned due to bugs with OKD node deployment.

- 2025-05-18 02:00Z - Application successfully schedule and come back online functionality comes online.

# Tech details

Hack@UCF runs a kubernetes cluster, we selected OKD (community version of openshift) due to its easy integration with Openstack. OKD runs several essential services including our Keycloak server for SSO.  OKD creates a volume for each PV. When pods are scheduled the corresponding PV is attached to the node in Openstack.  The reason the volumes initially got stuck in detaching is presently unknown.

I did not think the volumes would present a problem and decided to proceed to upgrade the Openstack Cluster anyway. The standard upgrade procedures  involve a proper shutdown of OKD. OKD nodes are cordoned and drained then gracefully shutdown. Once all VMs have shutdown the physical servers are restarted. For an unknown reason dbus failed to start on one of our Storage nodes (Storage-1). This caused the podman containers running the volume service (Cinder) to not start.

Once the physical servers started, we start the OKD vms and uncoroden the nodes. This is when we began to notice errors with the Application pods and the PVC. Our initial debugging steps were to run openstack CLI commands to force the openstack volumes to return to an available state.

```bash
openstack volume set --state available f430cbcf-ab8c-466d-86d2-9f47c5cef409
```
After this didn't work we decided the best course of action was to delete the node the volumes were attached to and spin up a new node. OKD is supposed to automatically auotscale this has been broken for months. OKD team decides to switch their OS to use an older kernel version, This causes the nodes to fail to mount the EXT boot partition with newer filesystem features enabled. This made debugging slower as provisioning new nodes takes 10 minuets with manually intervention required. Needless to say replacing the node did not solve the problem. After more futile debugging steps we decides to investigate the underlying service. Checking the volume details they were scheduled on Storage-1. Upon checking the cinder volume service containers were not started, the root cause being dbus had failed on the server startup.  Upon starting dbus and the containers running the command fixed the problem with the PVs.

```bash
openstack volume set --state available --detach f430cbcf-ab8c-466d-86d2-9f47c5cef409
```

Once application pods were working again the worker nodes ran out of RAM, this is a problem due to the aforementioned autoscaling bugs with OKD. After manually starting 2 more workers the applications stabilized.



# Lessons Learned Follow-Up Steps

Going forward I would like to monitor to ensure all pods and dbus are started when the physical servers reboot.  Our current monitoring only catches pods that are unhealthy or stopped in error state. We could instead ensure a certain list of pods are always running. We are investigating replacing OKD, their willingness to publish a release with such a massive bug has made me reconsider the stability of the entire platform.
