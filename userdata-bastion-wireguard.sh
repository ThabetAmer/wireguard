#!/bin/bash

S3_BUCKET_NAME=MY_S3_BUCKET
VPN_URL=MY_VPN_DOMAIN
VPN_PEER=MY_VPN_PEER

# init
OS_USER=ec2-user
sudo yum update -y
sudo yum install -y git

# docker
sudo yum install docker -y
sudo service docker start
sudo chkconfig docker on

# docker permissions
sudo groupadd docker
sudo usermod -aG docker $OS_USER
newgrp docker

# modprobe for wireguard
sudo yum upgrade -y
sudo amazon-linux-extras install -y epel
sudo curl -Lo /etc/yum.repos.d/wireguard.repo \
  https://copr.fedorainfracloud.org/coprs/jdoss/wireguard/repo/epel-7/jdoss-wireguard-epel-7.repo
sudo yum install -y wireguard-dkms wireguard-tools
sudo modprobe wireguard

# docker compose
sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# get into folder
sudo mkdir /opt/wireguard
sudo chown $OS_USER.$OS_USER /opt/wireguard/
cd /opt/wireguard/

# envs
cat > .env << EOL
S3_BUCKET=$S3_BUCKET_NAME
SERVERURL=$VPN_URL
SERVERPORT=51820
PEERS=$VPN_PEER
PEERDNS=auto
ALLOWEDIPS=0.0.0.0/0
TZ=America/Los_Angeles
PUID=1000
PGID=1000
EOL

# docker preps
cat > docker-compose.yml << EOL
services:
  wireguard:
    image: lscr.io/linuxserver/wireguard:latest
    container_name: wireguard
    env_file: ".env"
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    volumes:
      - /opt/wireguard/config:/config
      - /lib/modules:/lib/modules
    ports:
      - 51820:51820/udp
    sysctls:
      - net.ipv4.conf.all.src_valid_mark=1
    restart: unless-stopped
EOL

# cron
#
sudo yum install cronie -y
sudo systemctl enable crond.service
sudo systemctl start crond.service

# cron synced
cat > sync.sh << EOL
#!/bin/bash

cd /opt/wireguard/
sudo chown $OS_USER.$OS_USER config/ -R
source .env

VAL="\$(aws s3 sync --delete s3://\$S3_BUCKET/wireguard/config/ config/ | wc -l)"
if [ "\$VAL" = "0" ];
then
  echo "No updates to configuraiton \$(date)" > /tmp/sync.last
else
  echo "\$(date)\n\$VAL" > /tmp/sync.last.good
  docker-compose restart
fi
EOL

chmod 755 /opt/wireguard/sync.sh
echo "*/5 * * * * /opt/wireguard/sync.sh" | sudo crontab -

# IP forwarding
#
echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

docker-compose up -d
