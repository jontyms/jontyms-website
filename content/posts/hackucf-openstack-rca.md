---
title: "Hack@UCF May 2025 Kubernetes Outage"
date: 2025-05-30T20:00:44-04:00
draft: false
author: "Jonathan Styles"
tags: [""]
description: A root cause analysis of the outage we had on May 17th - 18th, 2025. The outage resulted in the SSO platform Keycloak being down for most of 2 days, resulting in users not being able to log in and administer their Virtual Machines.
---


I help run a Private Cloud for my university's Cybersecurity Club, Hack@UCF. [(Details about the cloud here)](../private-cloud). This is an incident report I wrote for fun and education about the outage we had on May 17th - 18th 2025. The outage resulted in the SSO platform Keycloak being down for 2 days. This meant users could not login to OpenStack and administer their Virtual Machines.

# Timeline
In UTC because why not

- 2025-05-15 00:48Z - Engineer notices volumes stuck in detaching state after a routine OKD cluster update. No action is taken; applications were not affected at the time.

- 2025-05-17 01:00Z - Openstack cluster update procedures begin

- 2025-05-17 02:00Z - OKD cluster is shutdown in preparation for node restarts, user facing services go down

- 2025-05-17 03:00Z - OpenStack compute nodes come back online, OKD VMs started.

- 2025-05-17 03:10Z - Volumes were observed to still be stuck in detaching state

- 2025-05-17 04:00Z - Engineers go to bed

- 2025-05-17 11:00Z - IR call resumes

- 2025-05-17 11:00Z - Engineers decide to start the OKD cluster despite OpenStack volumes being stuck in detaching

- 2025-05-17 11:30Z - Application pods fail to start due to broken PVCs

- 2025-05-18 00:00Z - Engineers decide to replace the node with broken volumes; new nodes have to be manually provisioned due to bugs with OKD node deployment.

- 2025-05-18 00:40Z - Engineers decide to investigate the Cinder volume storage node the volumes are on and determine that Cinder pods were never started.

- 2025-05-18 01:10Z - Volumes successfully detach and attach to a new node. Applications come online.

- 2025-05-18 01:20Z - Worker nodes run out of RAM, application pods fail to schedule.

- 2025-05-18 01:40Z - New worker nodes are manually provisioned due to bugs with OKD node deployment.

- 2025-05-18 02:00Z - Applications successfully schedule and come back online; functionality restored.

# Root Cause

The root cause of the issue was that the Cinder volume service containers were not started on the storage nodes. This was a failure in our monitoring. Once the containers were started, the volumes were able to detach and attach to new nodes, and the applications were able to schedule and come back online.

# Tech details

Hack@UCF runs a Kubernetes cluster. We selected OKD (the community version of OpenShift Kubernetes distribution) due to its easy integration with OpenStack. OKD runs several essential services, including our Keycloak server for SSO. OKD creates a volume for each PV. When pods are scheduled, the corresponding PersistentVolume (PV) is attached to the node in OpenStack.

I did not think the volumes would present a problem and decided to proceed to upgrade the OpenStack Cluster anyway. The standard upgrade procedures involve a proper shutdown of OKD. OKD nodes are cordoned and drained, then gracefully shutdown. Once the physical servers started, we started the OKD VMs and uncorrdond the nodes. This is when we began to notice errors with the Application pods and the PVC. Our initial debugging steps were to run OpenStack CLI commands to force the OpenStack volumes to return to an available state.

```bash
openstack volume set --state available f430cbcf-ab8c-466d-86d2-9f47c5cef409
```

After this didn't work we decided the best course of action was to delete the node the volumes were attached to and spin up a new node. Replacing the node did not solve the problem. After more futile debugging steps we decided to investigate the underlying service. Checking the volume details they were scheduled on Storage-1. Upon checking the cinder volume service containers were not started, the root cause being dbus had failed on the server startup.  Upon starting dbus and the containers running the command fixed the problem with the PVs.


```bash
openstack volume set --state available --detach f430cbcf-ab8c-466d-86d2-9f47c5cef409
```

Once the application pods were working again, the worker nodes ran out of RAM. This is a problem due to the aforementioned autoscaling bugs with OKD. After manually starting 2 more workers, the applications stabilized.


{{< callout type="alert" text="The OKD developers, in their infinite wisdom, decided to switch from Fedora CoreOS to CentOS Stream CoreOS. This massive switch was made 'easy' and 'flawless' due to CoreOS being a container operating system where the entire root filesystem can be easily replaced with the new image. So, to autoscale, OKD spins up a new instance on OpenStack. This node is using a Fedora CoreOS 39 image. The instance then pulls down its configuration and starts downloading the update to CentOS Stream CoreOS. Once the update is complete, the instance restarts and the new CoreOS image attempts to boot. CoreOS will not boot because the boot filesystem has new ext4 features enabled that are not supported by the older kernel. The recovery steps are to attach the disk image to an instance running a newer kernel and disable the ext4 features. Then the node can boot normally." >}}

# Lessons Learned Follow-Up Steps

Going forward I would like to monitor to ensure all pods and dbus are started when the physical servers reboot.  Our Zabbix monitoring only catches pods that are unhealthy or stopped in error state. We could instead ensure a certain list of pods are always running. We are investigating replacing OKD, their willingness to publish a release with such a massive bug has made me reconsider the stability of the entire platform. Another problem is that Cinder was not behaving in a highly available manner; further investigation is warrented in why the volumes were move to a working Cinder volume service.
