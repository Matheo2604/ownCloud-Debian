# ownCloud Installation Script

This repository contains a bash script to install and configure ownCloud with Apache, MariaDB, and PHP on a Debian-based system.

## Prerequisites

- A fresh installation of Debian 12.
- Root or sudo access.

## Installation

1. **Clone this repository:**

    ```
    $ git clone https://github.com/matheo2604/ownCloud
    $ cd ownCloud
    ```

2. **Make the script executable:**

    ```
    $ chmod +x install.sh
    ```

3. **Run the script:**

    ```
    # ./install.sh
    ```

    You will be prompted to enter and confirm a password for the ownCloud root user.

## Usage

After installation, you need to update the ownCloud configuration to specify the accessible network. Edit the following file:

```
# nano /var/www/owncloud/config/config.php
# systemctl restart apache2
```

Notes

    Ensure that your firewall settings allow access to the necessary services (HTTP, HTTPS).
    The script assumes a clean Debian 12 installation and may not account for existing configurations or installations.
