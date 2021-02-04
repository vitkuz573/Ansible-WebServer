# Ansible-WebServer PLAYBOOK
[![License](https://img.shields.io/github/license/vitkuz573/Ansible-WebServer)](https://github.com/vitkuz573/Ansible-WebServer/blob/master/LICENSE)
[![Help Wanted](https://img.shields.io/github/issues/vitkuz573/Ansible-WebServer/help%20wanted?color=green)](https://github.com/vitkuz573/Ansible-WebServer/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22)
[![Lines Of Code](https://tokei.rs/b1/github/vitkuz573/Ansible-WebServer?category=code)](https://github.com/vitkuz573/Ansible-WebServer)
[![Version](https://img.shields.io/github/v/release/vitkuz573/Ansible-WebServer?include_prereleases)](https://github.com/vitkuz573/Ansible-WebServer/releases/latest)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit)

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

NOTE: In case of deploying a web server with HTTPS, the *.crt and *.key files must be on the server at the time of deployment!

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
