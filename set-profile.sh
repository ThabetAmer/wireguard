#!/bin/bash

# Function to create an env file for profile
set_env_file() {
    FILE_PATH=$1
    echo "SERVER_ENDPOINT=$SERVER_ENDPOINT" >> $FILE_PATH
    echo "ALLOWED_IPS=$ALLOWED_IPS" >> $FILE_PATH
    echo "PEERS=$PEERS" >> $FILE_PATH
    echo "BUCKET_NAME=$BUCKET_NAME" >> $FILE_PATH
    echo "SERVER_PORT=$SERVER_PORT" >> $FILE_PATH
    echo "GATEWAY_IP=$GATEWAY_IP" >> $FILE_PATH
}

# Function to create an files for DNS
set_coredns() {
    DNS_PATH=$1
    mkdir $DNS_PATH
    cat > $DNS_PATH/Corefile << EOL
. {
    loop
    forward . /etc/resolv.conf
}
EOL
}

# Function to create keys for server
set_server_keys() {
    KEYS_PATH=$1
    umask 077
    mkdir $KEYS_PATH
    wg genkey | tee $KEYS_PATH/privatekey-server | wg pubkey > $KEYS_PATH/publickey-server
}

# Function to create server config file and paths
set_configs() {
    SERVER_CONFIG=$1
    mkdir $SERVER_CONFIG
    WG_CONFIG=$SERVER_CONFIG/wg0.conf

    echo "[Interface]" >> $WG_CONFIG
    echo "Address = $GATEWAY_IP" >> $WG_CONFIG
    echo "ListenPort = $SERVER_PORT" >> $WG_CONFIG
    echo "PrivateKey = $(cat $CONFIG/server/privatekey-server)" >> $WG_CONFIG
    echo "PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE" >> $WG_CONFIG
    echo "PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE" >> $WG_CONFIG
}

# Main script
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 profile"
    echo "Example: $0 aws1"
    exit 1
fi

# Inputs
PROFILE=$1
CONFIG=$PROFILE/config

# Quit when profile folder doesn't exists
if [ -d $PROFILE ]; then
    echo "ERROR: folder $PROFILE already exists"
    exit 2
fi

# init configs
if [ ! -f $PROFILE.env ]; then
    echo "set initial env file $PROFILE.env"
    echo "please fill and revert"
    set_env_file $PROFILE.env
    exit 3
fi

mkdir -p $CONFIG \
    && mv $PROFILE.env $PROFILE/.env \
    && source $PROFILE/.env

set_coredns $CONFIG/coredns

set_server_keys $CONFIG/server

set_configs $CONFIG/wg_confs

# sync for older wireguard releases
cp $CONFIG/wg_confs/wg0.conf $CONFIG/wg0.conf

echo "done on dir $CONFIG"
echo "now you can add your first user via script add-user.sh"
