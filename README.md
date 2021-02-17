# Ansible WebServer

[![License](https://img.shields.io/github/license/vitkuz573/Ansible-WebServer)](https://github.com/vitkuz573/Ansible-WebServer/blob/master/LICENSE)
[![Help Wanted](https://img.shields.io/github/issues/vitkuz573/Ansible-WebServer/help%20wanted?color=green)](https://github.com/vitkuz573/Ansible-WebServer/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22)
[![Lines Of Code](https://tokei.rs/b1/github/vitkuz573/Ansible-WebServer?category=code)](https://github.com/vitkuz573/Ansible-WebServer)
[![Version](https://img.shields.io/github/v/release/vitkuz573/Ansible-WebServer?include_prereleases)](https://github.com/vitkuz573/Ansible-WebServer/releases/latest)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit)
[![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)

Playbook for fully automated deployment of one or more web servers (Nginx + Apache)

## Usage

1) Install Ansible:

   Debian:

   ```bash
   sudo apt install ansible
   ```

2) Run init.sh and follow the instructions:

   ```bash
   ./init.sh
   ```

WARNING: Do not run the playbook directly from the server on which you plan to deploy!

NOTE: In case of deploying a web server with HTTPS (option 1), the certificate
and key files must be on the server at the time of deployment!

## Deployment options

- HTTP
- HTTPS
  - With a pre-prepared certificate (option 1)
  - With a certificate obtained from Let's Encrypt (option 2)
  - With a self-signed certificate (option 3)

## What will be installed and configured?

- Nginx (Frontend)
- Apache (Backend)
- Apache Modules
  - mod_fastcgi
  - mod_remoteip
- PHP-FPM
- DBMS (optional)
  - MariaDB
  - MySQL
  - PostgreSQL (in development)
- phpMyAdmin (optional)
- Knockd (optional)
- SFTP Server (optional)
- Fail2ban (optional) (in development)
- Firewall (optional)
  - UFW
  - Firewalld (in development)

## What will be done to improve security?

- Hiding Nginx and Apache versions
- Blocking access to the Apache port
- Blocking access to DBMS from outside
- Protecting Nginx from slow requests
- SSH protection with Port-Knocking (optional)
- Blocking access to phpMyAdmin via .htpasswd and .htaccess (optional)

## Roadmap

- [X] Adding HTTPS support
- [ ] Code optimization
- [X] Adding the ability to select the DBMS
- [ ] Adding support for pgAdmin
- [ ] GUI development for easier deployment
- [ ] Adding support for other OSes
