# WireGuard Setup

WireGuard is a fast and secure VPN protocol, easy to configure and deploy.
This repository automates the setup of WireGuard VPN on a Linux server over AWS EC2.

## Features

- Automatic installation of WireGuard.
- Configuration of WireGuard server interface.
- Generation of server and peer keys.
- Hot pluggable via s3 bucket for persistant storage of configs
- Many-to-Many client-server mapping

## Prerequisites

Before you begin, ensure you have the following:

- AWS CLI 2+
- (optional) AWS CDK 2+ or Terraform 1.9+ with hashicorp/aws provider 4+

## Initiation

You need to set functional Wireguard on a server, here EC2, with method to sync configs to server.

- Create S3 bucket - where the VPN configs for server and peers are stored
  - Versioning would be in benefit to track changes to configs over time
- Create EC2 instance
  - Preferably T3/T4 burstable small size - no need for the more expensive allocations
  - Linux based - _of course_, here we use the AMAZON_LINUX_2 AMI image
  - A persistant IP is needed as address for public access
- Link the EC2 with a security group with UDP 51820 port is publically open
- Link the EC2 with S3 access via IAM policy statement
- Install necessary apps and configs on operating system
  - Docker and Docker compose
  - cronjob daemon
  - modprobe and IP forwarding
  - files and scripts: cron sync script, compose file and its env file.

### CDK Automotion for infrastructure as code
In smoother way for automation, a CDK stack template is attached in file [WireGuardEc2Stack.java](WireGuardEc2Stack.java), with inititation script for ec2 userdata attached as will [userdata-bastion-wireguard.sh](userdata-bastion-wireguard.sh), where few variables have to be set in advance.


Variables in _WireGuardEc2Stack.java_
```java
private final String bastionWireguardBucketName = "your-s3-bucket-name";
private final String bastionWireguardKeyPairName = "your-key-pair-name";

private final String ec2InstanceType = "BURSTABLE2";
private final String ec2InstanceSize = "SMALL";
```

Variables in _userdata-bastion-wireguard.sh_
```bash
S3_BUCKET_NAME=MY_S3_BUCKET
VPN_URL=MY_VPN_DOMAIN
VPN_PEER=MY_VPN_PEER
```

### Terraform Automotion for infrastructure as code

Same as in the CDK sample, a separate module for Terraform has been embedded in folder `terraform-module`, make sure to set variables before calling the resource, not only in `variables.tf` but also for the user-data file in root file `userdata-bation-wireguard.sh`
```
environment_name
vpc_id
vpc_subnet_id
allowed_security_groups_ingress
dns_zone_id
dns_name
ssh_key_name
s3_bucket_name
instance_profile
```

With default values for:
```bash
port_number=51820
ami=ami-031b673f443c2172c
instance_type=t3a.small
private_subnet_cidr=10.1.0.0/16
```

## Server Setup

To set configs for a server, follow the procedure:

- Run script below with the server profile name
```bash
./set-profile.sh profile_name
```
- It will creates a env file template for the profile, go ahead and edit the provided file, namely `profile_name.env`
  - `SERVER_ENDPOINT` is the public IP/DNS name for the server
  - `ALLOWED_IPS` are the CIDR for internal server network to access, ie "192.168.1.0/16 10.0.0.0/24"
  - `PEERS` is a list of clients allowed to connect - here we use generic prefix for all
  - `BUCKET_NAME` s3 bucket name to store configs on
  - `SERVER_PORT` mainly 51820
  - `GATEWAY_IP` mainly is the internal IP of VPN server 10.0.0.1

- Rerun the same script again `./set-profile.sh profile_name` to enject the configs you've just set in previous step.
  - Creates dedicated folder under profile/configs/ with server keys and configs in
  - It also takes care of internal DNS resolution via coreDNS


## Manage Clients

### User Addition

To add a peer (client) to your WireGuard server, run the script below, it will ask for your confirmation on submitting the new addition to s3 bucket folder

```bash
./adduser.sh profile_name peer_name
```
- Creates new client public/private keys for new auto incremented internal IP address.
- Syncs from S3 bucket as the soruce of configs, then syncs back to when the new client is added.

Make sure to securely distribute the client’s private key and connection configuration for them to connect to the server.

### User Deletion

To delete a peer (client), run the scipt below, it will automatically sync with s3 for permanent removal of client

```bash
./deluser.sh profile_name peer_name
```

## License

This project is licensed under the MIT License.

---

### Contributions

Feel free to contribute by submitting a pull request or opening an issue to suggest improvements or report bugs.
