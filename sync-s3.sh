#!/bin/bash

# function to sync with S3
s3_sync() {
    SYNC=$1
    S3="s3://${BUCKET_NAME}/wireguard/config/"
    LOCAL="${PROFILE}/config/"

    if [ $SYNC == 'to' ]; then
        echo "Syncing configuration to s3"

        # confirmation
        echo "Confirmation request, tail -20 $WG_CONFIG"
        tail -20 $WG_CONFIG
        echo -e "\n\n\nDoes everything look ok? (yes/no)"
        read LOOK_OK
        if [ "${LOOK_OK}" != "yes" ];
        then
            echo "Ok, we wont commit it then"
            exit 5
        fi

        aws s3 sync --delete --profile=$PROFILE $LOCAL $S3
    else
        echo "Syncing configuration from s3"

        aws s3 sync --delete --profile=$PROFILE $S3 $LOCAL
    fi
}

# # Main script
# if [ "$#" -ne 1 ]; then
#     echo "Usage: $0 [from|to]"
#     echo "Example: $0 from"
#     exit 1
# fi

# # Execution
# s3_sync $1