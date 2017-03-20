#!/bin/bash
MYARCHIVE=archive-$(date +%Y%m%d)-$(date +%HH%MM%SS).tar.bz2

function backup (){
    echo "[INFO] Creating a new backup file: $MYARCHIVE"
    tar cvfj "$MYARCHIVE" public_html/
    wait
}

function verify () {
    MYARCHIVE=$1
    echo ""
    echo "[INFO] List archive files for verification"
    echo ""
    tar -tz -f "$MYARCHIVE" #> /dev/null
    wait

    echo ""
    echo "[INFO] Verify checksum is accurate"
    echo ""
    shasum -a 256 -c "$MYARCHIVE".sha256
}

function calculate_SHA256 () {
    echo ""
    echo "[INFO] Calculate the SHA-256 Checksum"
    echo ""
    shasum -a 256 "$MYARCHIVE" > "$MYARCHIVE".sha256
}

function extract () {
    MYARCHIVE=$1
    echo ""
    echo "[INFO] Extracting files to /public_html/BACKUP/public_html/..."
    echo ""
    mkdir ~/public_html/BACKUP
    tar -xvzf "$MYARCHIVE" -C ~/public_html/BACKUP
    echo ""
    echo ""
    echo "[INFO] PLEASE REMEMBER TO DELETE BACKUP FOLDER WHEN COMPELTE"
    echo ""
    echo ""
}

function dropbox () {
    MYARCHIVE=$1
    echo ""
    echo "[INFO] Backing up data to dropbox..."
    echo ""
    ./dropbox/dropbox_uploader.sh upload "$MYARCHIVE" /
}

function usage () {
    echo ""
    echo "Missing paramter. "
    echo ""
    echo "Usage $0 {Any of the options below}"
    echo ""
    echo " backup"
    echo "    will execute all of the commands below except for extract and dropbox"
    echo "    This may take some time...."
    echo " calculate_SHA256"
    echo " verify <FILENAME>  #Note: Verify archive, not sha256 file."
    echo ""
    echo " extract <FILENAME>"
    echo " dropbox <FILENAME>"
    echo ""
    }




function main () {
    echo ""
    echo "Welcome to your Backup Script"
    echo ""

    if [ -z "$1" ]; then
        usage
        exit 1
    fi

    if [ "$1" == "backup" ]; then
        backup
        calculate_SHA256
        verify "$MYARCHIVE"
    fi
    if [ "$1" == "verify" ]; then
        verify "$2"
    fi
    if [ "$1" == "extract" ]; then
        extract "$2"
    fi
    if [ "$1" == "dropbox" ]; then
        dropbox "$2"
    fi
}

main "$1" "$2"
