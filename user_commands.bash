#!/bin/bash

install_repo=endeavouros-hkm
repo_url="https://github.com/HKM-UNI/$install_repo.git"

if [ "$EUID" -ne 0 ]; then
    echo "You must run this script as super user."
    exit
fi

if [ ! -d "/home/liveuser" ] ; then
    echo "This script is only intended as a feature of the Endeavour OS Live CD."
    exit
fi

arg="$1"
if [[ $arg == *config ]]; then
    echo "Running in 1st phase with $arg='$2'" >> /home/liveuser/log.txt
else
    username=$1
    echo "Running in 2nd phase with user '$username'" >> /home/liveuser/log.txt

    git clone $repo_url
    cd $install_repo
    chmod +x ./custom-install.sh
    ./custom-install.sh $username
fi
