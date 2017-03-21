#!/bin/bash
source openrc

# This script will create and download all available images in an openstack cluster under a specific username.
# This script has been tested against shellcheck and verified to the best of my abilities to work under any version of shell.
# All that is required to run is an openrc file.

GET_INSTANCE_NAMEs=$(openstack server list --all-projects --long | awk 'NR>=4 {print $4}')
GET_IMAGE_NAMEs=$(openstack image list | grep active | awk '{print $4}')

# Get all instances that are active and not in a deleting state...
# Create an snapshot/image.
function Create_Images () {
    for i in $GET_INSTANCE_NAMEs; do
        ID=$(nova list --all-tenants --status=Active | grep "$i" | awk 'NR<=1 {print $2}')
        wait
        for w in $(nova list --all-tenants --status=Active | grep "$i" | awk 'NR<=1 {print $8}')
        do
            if [ "$w" == "deleting" ]
            then
                echo "[INFO] $i is in deleting state... skipping"
                break 1
            else
                echo "[INFO] Creating an image of <$i>, ID of <$ID>"
# If an error happens in the creation of the image, echo error message and continue to next VM.
                if ! nova image-create --poll "$ID" "$i"; then
                    echo "[ERROR] ERROR IN CREATION OF IMAGE...."
                    continue
                fi
            fi
        done
    done
}


function Download_Images () {
    echo "$GET_IMAGE_NAMEs"
    for i in $GET_IMAGE_NAMEs; do
        IMAGE_ID=$(openstack image list | grep "$i" | awk 'NR<=1 {print$2}')
        VARS_DEFAULT="y"
        read -r -n 2 -t 10 -p "Do you wish to try to download this image/snapshot ($i)?" vars
        vars="${vars:-$VARS_DEFAULT}"
        case "$vars" in
            [yY] ) echo "[INFO] Downloading $i ..."
            until glance image-download --file "$i".raw "$IMAGE_ID"; do
                echo "[ERROR] Transfer disrupted/error for $i ..."
                read -r -n 2 -t 10 -p "Do you wish to try to download this image/snapshot ($i) again?" vars2
                vars2="${vars2:-$VARS_DEFAULT}"
                case "$vars2" in
                    [yY] ) sleep 5
                    ;;
                    [nN] ) break
                    ;;
                esac
            done
            ;;
            [nN] ) continue
            ;;
        esac
    done
}

function usage () {
    echo ""
    echo "Missing parameter. Please enter one of the following options"
    echo ""
    echo "Usage: $0 {Any of the options below}"
    echo ""
    echo "  Download_Images"
    echo "  Create_Images"
    echo ""		
    echo "THESE ARE THE IMAGES THAT WILL BE DOWNLOADED: (Download_Images)"		
    echo "$GET_IMAGE_NAMEs"		
    echo ""		
    echo ""		
    echo "THESE ARE THE VM'S THAT CAN BE SNAPSHOTTED: (Create_Images)"		
    echo "$GET_INSTANCE_NAMEs"		
}

function main () {
    echo ""
    echo "Welcome to Image Backup Script"
    echo ""

    if [ -z "$1" ]; then
        usage
        exit 1
    fi

    case $1 in
    "Download_Images")
        Download_Images
        ;;
    "Create_Images")
        Create_Images
        ;;
    *)
        usage
        exit 1
    esac

}

main "$1"
