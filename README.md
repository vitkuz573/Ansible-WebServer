# Ansible-WebServer PLAYBOOK
Playbook for fully automated deployment of one or more web servers (Nginx + Apache)

## Usage

First, install ansible:
```
sudo apt install ansible
```

Then run init.sh and follow the instructions:
```
./init.sh
```
WARNING: For correct playbook operation, do not run it directly from the server where the deployment is planned. Instead, use another server (your PC or virtual machine).

NOTE (1): To save access to a web server without specifying a port, specify port 80 for Nginx.

NOTE (2): In case of deploying a web server with HTTPS, the *.crt and *.key files must be on the server at the time of deployment!

## What will be installed and configured?
- Nginx
- Apache
- PHP-FPM
- mod_fastcgi
- mod_remoteip
- MariaDB
- phpMyAdmin
- Knockd
- SFTP Server
- UFW

## What will be done to improve security?
- Hiding Nginx and Apache versions
- Blocking access to the Apache port
- Blocking access to MariaDB from outside
- Protecting Nginx from slow requests
- SSH protection with Port-Knocking
- Blocking access to phpMyAdmin via .htpasswd and .htaccess

# Roadmap

- [X] Adding HTTPS support
- [ ] GUI development for easier deployment
- [ ] Adding support for other OSes
