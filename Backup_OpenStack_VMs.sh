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
                
                if ! nova image-create --poll "$ID" "$i"; then
                    echo "[ERROR] ERROR EXISTED IN CREATION OF IMAGE...."
                    continue
                fi
            fi
        done
    done
}


function Download_Images () {
# debug
#    echo "$GET_IMAGE_NAMEs"
    for i in $GET_IMAGE_NAMEs; do
        IMAGE_ID=$(openstack image list | grep "$i" | awk 'NR<=1 {print$2}')
        echo "$IMAGE_ID"
        echo "[INFO] Downloading $i ..."
# Try to downloaded an image until it is downloaded, then continue to the next.  
# This helps with any glance issues/bugs not allowing to download due to errors.
        until glance image-download --file "$i".raw "$IMAGE_ID"; do
        echo "[ERROR] Transfer disrupted/error, retrying ($i) in 10 seconds ..."
        sleep 10
        done
    done
}

function usage () {
  echo ""
  echo "Missing parameter. Please Enter one of the following options"
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
