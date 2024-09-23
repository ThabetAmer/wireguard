#!/bin/bash

# Function to generate a WireGuard client configuration
generate_client_config() {
    SERVER_PUBLIC_KEY="$(cat $PROFILE/config/server/publickey-server)"

    CLIENT_CONF_PATH="$PROFILE/config/$PEER_NAME"
    mkdir -p "$CLIENT_CONF_PATH"

    CLIENT_PRIVATE_KEY=$(wg genkey | \
        tee $CLIENT_CONF_PATH/privatekey-$PEER_NAME)

    CLIENT_PUBLIC_KEY=$(echo "$CLIENT_PRIVATE_KEY" | wg pubkey | \
        tee $CLIENT_CONF_PATH/publickey-$PEER_NAME)

    CLIENT_CONF="$CLIENT_CONF_PATH/$PEER_NAME.conf"

    echo "" >> $CLIENT_CONF
    echo "[Interface]" > $CLIENT_CONF
    echo "PrivateKey = $CLIENT_PRIVATE_KEY" >> $CLIENT_CONF
    echo "Address = $CLIENT_IP" >> $CLIENT_CONF
    echo "ListenPort = $SERVER_PORT" >> $CLIENT_CONF
    echo "DNS = $GATEWAY_IP" >> $CLIENT_CONF
    echo "" >> $CLIENT_CONF
    echo "[Peer]" >> $CLIENT_CONF
    echo "PublicKey = $SERVER_PUBLIC_KEY" >> $CLIENT_CONF
    echo "Endpoint = $SERVER_ENDPOINT:$SERVER_PORT" >> $CLIENT_CONF
    echo "AllowedIPs = $ALLOWED_IPS" >> $CLIENT_CONF

    echo $CLIENT_PUBLIC_KEY
}

# Function to add a new client to the server
add_client_to_server() {
    CLIENT_PUBLIC_KEY=$1

    echo "" >> $WG_CONFIG
    echo "### begin ${PEER_NAME} ###" >> $WG_CONFIG 
    echo "[Peer]" >> $WG_CONFIG
    echo "PublicKey = $CLIENT_PUBLIC_KEY" >> $WG_CONFIG
    echo "AllowedIPs = $CLIENT_IP/32" >> $WG_CONFIG
    echo "### end ${PEER_NAME} ###" >> $WG_CONFIG
}

# Function to get the next available IP address
get_next_ip() {
    LAST_IP=$(grep 'AllowedIPs' $WG_CONFIG | tail -n 1 | awk '{print $3}' | cut -d '/' -f 1)
    
    # or get next IP following gateway IP
    if [[ -z "$LAST_IP" ]]; then
        LAST_IP=$GATEWAY_IP
    fi

    IFS='.' read -r i1 i2 i3 i4 <<< "$LAST_IP"
    i4=$((i4 + 1))
    echo "$i1.$i2.$i3.$i4"
}

# Main script
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 profile peer"
    echo "Example: $0 aws alex"
    exit 1
fi

# Inputs
PROFILE=$1
CLIENT_NAME=$2

# Quit when profile folder doesn't exists
if [ ! -d $PROFILE ]; then
    echo "ERROR: folder $PROFILE doesn't exist"
    exit 2
fi

# Load envs for profile
source $(dirname "$0")/sync-s3.sh
source $(dirname "$0")/$PROFILE/.env
WG_CONFIG="$PROFILE/config/wg0.conf"
PEER_NAME="peer_${PROFILE}_$CLIENT_NAME"

# Sync back from AWS - skip for first user
if grep -q "^\[Peer\]$" $WG_CONFIG; then
    s3_sync from
fi

# Quit when user exists
if grep -q "^### begin $PEER_NAME ###$" $WG_CONFIG; then
    echo "ERROR: client $PEER_NAME already exists in $WG_CONFIG"
    exit 3
fi

# Assign IP for the new client
CLIENT_IP=$(get_next_ip)

# Generate client config
KEY=$(generate_client_config)

# Add client to the server
add_client_to_server $KEY

# Support for older releases
yes | cp -rf $WG_CONFIG $PROFILE/config/wg_confs/

# Sync changes to AWS
s3_sync to

# Closing
echo "Client ($CLIENT_NAME) with IP ($CLIENT_IP) has been added to ($PROFILE) WireGuard."
