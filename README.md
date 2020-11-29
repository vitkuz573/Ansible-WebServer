# Ansible-WebServer PLAYBOOK
Playbook for fully automated deployment of one or more web servers (Nginx + Apache)

## Usage

Run the init.sh script, and then follow the instructions.
```
chmod +x init.sh
./init.sh
```
WARNING: For correct playbook operation, do not run it directly from the server where the deployment is planned. Instead, use another server (your PC or virtual machine).

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
- Protecting Nginx from slow requests

# Into the plan

- [X] Adding HTTPS support
- [ ] Adding support for other OSes
