# Ansible-WebServer PLAYBOOK
Playbook for fully automated deployment of one or more web servers (Nginx + Apache)

## Usage

First, install ansible:
```
pip3 install ansible
```

Then run init.sh and follow the instructions:
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

# Roadmap

- [X] Adding HTTPS support
- [ ] Adding support for other OSes
