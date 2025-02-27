#!/bin/bash

# Function to check if a package is installed
check_install() {
    if ! dpkg -l | grep -q "$1"; then
        echo "Installing $1..."
        sudo apt update -y
        sudo apt install -y "$1"
    else
        echo "$1 is already installed."
    fi
}

echo "==== Installing Ansible ===="
check_install "ansible"
check_install "git"

echo "==== End of Ansible Installation! ===="
