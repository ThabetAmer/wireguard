#!/bin/bash

# Function to delete client from server
del_client_from_server() {
    sed_pattern="/### begin ${PEER_NAME} ###/,"
    sed_pattern="${sed_pattern}/### end ${PEER_NAME} ###/d"
    sed -e "${sed_pattern}" -i $WG_CONFIG
}

# Function to delete client files
del_client_files() {
    CLIENT_CONF_PATH="$PROFILE/config/$PEER_NAME"
    rm -rf $CLIENT_CONF_PATH
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

# Sync back from AWS
#s3_sync from

# Quit when user doesn't exists
if ! grep -q "^### begin $PEER_NAME ###$" $WG_CONFIG; then
    echo "ERROR: client $PEER_NAME does not exist in $WG_CONFIG"
    exit 3
fi

# delete server configs
del_client_from_server

# delete client files
del_client_files

# Support for older releases
yes | cp -rf $WG_CONFIG $PROFILE/config/wg_confs/

# Sync changes to AWS
s3_sync to

# Closing
echo "Client ($CLIENT_NAME) has been deleted from ($PROFILE) WireGuard."
