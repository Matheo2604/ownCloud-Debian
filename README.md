# ownCloud Installation Script

This repository contains a bash script to install and configure ownCloud with Apache, MariaDB, PHP and ufw on a Debian-based system.

## Prerequisites

- A fresh installation of Debian-based system.
- Root or sudo access.

## Installation

    bash <(curl -fsSL https://raw.githubusercontent.com/matheo2604/owncloud-debian/master/install.sh)

## Notes

    The script assumes a clean Debian 12 installation and may not take count for existing configurations or installations.
    It also have a self-signed certificate & a ufw firewall included to take in consideration
