---
title: "Building a Private Cloud: A DevOps Approach"
date: 2024-06-11T13:58:02+02:00
draft: False
ShowToc: true
author: "Jonathan Styles"
description: "Discover how Hack@UCF's private cloud empowers students with hands-on experience in cybersecurity and cloud computing. Learn about the hardware, networking, and software that drive our private cloud, and explore upcoming projects aimed at enhancing our infrastructure. Join us on this journey to build a resilient, innovative private cloud using a DevOps approach."
tags: ["devops", "hack@ucf", "ansible", "openstack"]
---
For the past year I have been involved in running a private cloud for [Hack@UCF](https://hackucf.org) a student-run cybersecurity club at [The Unversity of Central Florida](https://ucf.com). All members are given access to this cloud as a place to experiment and learn without the fear of massive cloud bills. We also use the cloud to host our very own defensive cybersecurity competition [Horse Plinko](https://plinko.horse).

This began is spring 2019 when the [Lockheed Martin Cyber Innovation Lab](https://www.ucf.edu/pegasus/ucf-opens-lockheed-martin-cyber-innovation-lab/) was opened. Along with this Hack@UCF also gained access to a fund for equipping and upkeep of the lab. The decision was made to invest in server hardware in order to provide the club with a private cloud platform. I have been involved since September 2023, and I am now in charge of the project.

{{< alert class="success" >}}
### Support Hack@UCF: Empower the Next Generation of Cybersecurity Experts

At Hack@UCF, we are dedicated to fostering a dynamic learning environment where students can explore and excel in the field of cybersecurity. By sponsoring Hack@UCF, you become a vital part of our mission to develop skilled cybersecurity professionals. Together, we can create opportunities for learning, growth, and innovation.

For more information on sponsorship opportunities, please contact us [here](https://www.hackucf.org/sponsorship).
{{< /alert >}}

# The Hardware

{{< bundle-image caption="A picture of a UCF datacenter [source](https://arcc.ist.ucf.edu/)." altText="a picture of a datacenter" name="Cluster.png">}}

The hardware is a bit of a mess with four generations of people making purchasing decision each with their own vision of what the cloud should be.

## Networking

Our network infrastructure features 10 Gigabit Ethernet (GbE) backbone, with all servers connected via a bonded 2x10 GbE link for maximum uptime and redundancy. Our main router and firewall is a EdgeRouter Infinity, which not only provides routing capabilities but also hosts a WireGuard server for secure admin access. For switching needs, we rely on a combination of Edgeswitch and Mikrotik switches.

{{< svg-figure caption="A Network Diagram" altText="Network Diagram" name="Infra-Network-Diagram.svg">}}

## Servers

### Manager Nodes
All these servers are fairly new (purchased within the last year). Our manager nodes run RabbitMQ, a MariaDB cluster, HAProxy, and Horizon web UI, as well as other management daemons for various OpenStack services. These servers have a single SSD drive and AMD EPYC 7313P 16 Core, and 64GB of RAM.

### Compute Nodes
These nodes run the Nova compute service; all virtual machines run on these hosts. A few of these hosts also house some of the cluster's NVMe storage.

Compute 1a-1d are all in a single 2U Supermicro chassis. They have an AMD EPYC 7702P 64-Core processor, 512GB of memory, a SATA boot drive, and one NVMe storage drive.

Compute 2 is a relic from when the private cloud only had one server. It has two AMD EPYC 7451 24-Core processors with 256GB of memory.

### Storage Nodes
These nodes house most of our Ceph OSDs.
Storage 1 is a 2U server with all the rust drives in our cluster—12 drives with a combined capacity of 134.1 TiB.
Storage 2-4 are our NVMe storage servers, each with 12 drives.

### Deployment Node
This is a old Dell Poweredege from UCF's surplus. This node runs the software used to deploy the rest of the nodes.

# Initial Setup
Once a server is in the rack, it is PXE booted from [MAAS](https://maas.io/). MAAS (metal-as-a-service) is a product from Canonical. We use it to quickly install operating systems and do a small amount of configuration with cloud-init. Once we install the operating system (always the most recent LTS Ubuntu) we run our baseline ansible playbook. The baseline script creates users, installs necessary packages, and sets up the firewall.

Once all the servers are provisioned we run Kolla Ansible. Kolla Ansible is a Openstack project that deploys openstack fully containerized using ansible. Much better details of how to use Kolla Ansible is found in their documentation and is this [blog post](https://blog.gr4ytech.net/posts/Automating-Openstack-Deployment/) by another one of the sysadmins on the project.

After Kolla has finished running we deploy Ceph using a playbook built on [cephadm-ansible](https://github.com/ceph/cephadm-ansible).

# The Other Stuff

{{< svg-figure caption="A dependency graph showing most services running on our cloud." altText="A dependency graph showing most services running on our cloud." name="Dependency-graph.svg">}}

## Assorted VMs
The virtual machines in our admin tenant are deployed using [Terrafrom](https://www.terraform.io/) from our self hosted github runner. These vms include a [Portainer](https://www.portainer.io) host, a [Zabbix](https://www.zabbix.com) server, a [Wazuh](https://wazuh.com) cluster, Windows Active Directory servers, and a OpenVPN server. These vms are configured using a mix of manual steps and ansible playbooks.

## OKD
[OKD](https://www.okd.io/) describes itself as "The Community Distribution of Kubernetes that powers Red Hat OpenShift." We use OKD to run [Planka](https://github.com/plankanban/planka) our trello replacement, [Keycloak](https://www.keycloak.org/) for our Auth 2.0 project and AWX for upcoming projects. OKD is deployed using their official ansible install scripts.


# Upcoming Projects

## 1. Horse Plinko
Horse Plinko will use our new AWX install in order to deploy competitor machines and supporting infrastructure. Horse Plinko will also use Auth 2.0 in order to provided themed single sign on for the competition.

## 2. Auth 2.0
Currently, different services we use all have different logins. In order to increase usability, we are going to move to SSO wherever we can. This will involve integrating into OnboardLite, OpenStack, OpenVPN, and RADIUS auth for the Wi-Fi. [blog post](https://blog.gr4ytech.net/posts/Using-Keycloak-With-Openstack/)

## 3. AWX
Ansible playbook are currently run from developer laptops or the deployment node. We plan to move to deploying everything from AWX, to provide full CI/CD and configuration drift prevention.

# Glossary of Terms

**Admin Tenant:** A virtualized administrative space where IT management tasks are performed.

**Ansible:** An open-source automation tool used for IT tasks such as configuration management, application deployment, and provisioning.

**AWX:** An open-source web application that provides a user interface, REST API, and task engine for Ansible.

**Ceph:** A distributed storage system that provides object, block, and file storage in a unified system.

**Ceph OSD (Object Storage Daemon):** A service that stores data and handles data replication, recovery, rebalancing, and provides some monitoring information to Ceph Monitors.

**CI/CD (Continuous Integration/Continuous Deployment):** A method to frequently deliver apps to customers by introducing automation into the stages of app development.

**Cloud-init:** A package that handles early initialization of a cloud instance.

**Compute Node:** A server that runs the virtual machines in a cloud environment.

**EdgeRouter Infinity:** A high-performance router designed for large-scale network applications.

**EdgeSwitch:** A series of managed network switches designed by Ubiquiti Networks.

**GitHub Runner:** A virtual machine that runs workflows defined in a repository on GitHub.

**HAProxy:** A free, open-source software that provides a high availability load balancer and proxy server for TCP and HTTP-based applications.

**Kolla Ansible:** An OpenStack project that provides production-ready containers and deployment tools for operating OpenStack clouds.

**MAAS (Metal-as-a-Service):** A service from Canonical that enables quick installation and configuration of physical servers.

**NVMe (Non-Volatile Memory Express):** A storage interface designed to allow modern SSDs to operate at high speeds.

**OpenStack:** An open-source software platform for cloud computing, typically deployed as infrastructure-as-a-service (IaaS).

**OpenVPN:** An open-source VPN protocol that provides secure point-to-point or site-to-site connections.

**PXE (Preboot Execution Environment):** A standard that describes a way to boot computers using a network interface independently of available data storage devices or installed operating systems.

**RabbitMQ:** An open-source message broker software that implements the Advanced Message Queuing Protocol (AMQP).

**RADIUS (Remote Authentication Dial-In User Service):** A networking protocol that provides centralized Authentication, Authorization, and Accounting (AAA) management for users who connect and use a network service.

**SATA (Serial ATA):** An interface used to connect ATA hard drives to a computer's motherboard.

**SSO (Single Sign-On):** A user authentication process that permits a user to use one set of login credentials to access multiple applications.

**SSD (Solid State Drive):** A type of mass storage device similar to a hard disk drive (HDD) but with no moving parts.

**Supermicro:** A company that manufactures servers, motherboards, and other computing hardware.

**Terraform:** An open-source infrastructure as code software tool created by HashiCorp.

**VM (Virtual Machine):** A software-based simulation of a physical computer.

**WireGuard:** A modern VPN that is simpler, faster, and more secure than traditional VPN protocols.

**Zabbix:** An open-source monitoring software tool for various IT components, including networks, servers, virtual machines, and cloud services.
