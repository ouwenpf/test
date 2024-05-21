#!/bin/bash

function fetch_os_series() {

if command -v apt &> /dev/null; then
    echo 'Debian'
    bash ./scripts/os_debian.sh
elif command -v yum &> /dev/null; then
    bash ./scripts/os_centos.sh
elif command -v zypper &> /dev/null; then
    echo 'SUSE' 
else
    echo "Unknown system"
fi

}

fetch_os_series