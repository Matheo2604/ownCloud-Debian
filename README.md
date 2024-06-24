# ownCloud-SMB Installation Script

This repository contains a bash script to install and configure ownCloud with Apache, MariaDB, and PHP on a Debian-based system. Additionally, it sets up an SMB service to share user directories and provides a convenient user creation script.

## Features

- Automated installation of Apache, MariaDB, PHP, and ownCloud.
- Configuration of MariaDB and Apache for ownCloud.
- Setup of a periodic scanning service for ownCloud files.
- User creation script (`ocu`) to add users to both ownCloud and SMB.

## Prerequisites

- A fresh installation of Debian 12.
- Root or sudo access.

## Installation

1. **Clone this repository:**

    ```
    $ git clone https://github.com/matheo2604/ownCloud-SMB
    $ cd ownCloud-SMB 
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

### Creating Users

To create a new user for both ownCloud and SMB, use the `ocu` (ownCloud create user) command:

```
# ocu
````

This will prompt you to enter a username and password. The script will then:

    - Create a user in ownCloud.
    - Add the user to the system.
    - Configure SMB for the user.
    - Set the correct permissions.

Important Configuration

After installation, you need to update the ownCloud configuration to specify the accessible network. Edit the following file:

```
# nano /var/www/owncloud/config/config.php
# systemctl restart apache2
```

Notes

    The script automatically sets up a service to periodically scan ownCloud files.
    Ensure that your firewall settings allow access to the necessary services (HTTP, HTTPS, SMB).
    The script assumes a clean Debian 12 installation and may not account for existing configurations or installations.