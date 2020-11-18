# Ansible-WebServer
Playbook for fully automated deployment of one or more web servers (Nginx+Apache)

____

## Usage

Configure ssh authorization by keys on all hosts you want to deploy and run the init script, and then follow the instructions.

NOTE: To save access to a web server without specifying a port, specify port 80 for Nginx.

## What will be installed and configured?
- Nginx
- Apache
- PHP-FPM
- mod_fastcgi
- mod_rpaf
- MariaDB
- UFW

## What will be done to improve security?
- Hiding Nginx and Apache versions
- Blocking access to the Apache port
- Blocking access to MariaDB from outside
- Blocking access by IP address
- Protecting Nginx from slow requests
