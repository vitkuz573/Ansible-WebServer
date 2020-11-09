# Ansible-WebServer
Playbook for fully automated deployment of one or more web servers (Nginx+Apache)

____

## Usage

Before starting the playbook, specify the Apache port in the group_vars/vars.yml file. You can also specify the port for Nginx, but in order for the server to be available without specifying the port, you must leave the standard value - 80.

You also need to fill in the hosts.ini file with the ip addresses of the hosts that you want to configure and create files in the group_vars folder with the name containing this ip address for each of the specified hosts, for example: 192.168.18.112.yml and define variables that are unique for this host. The format of this file is given in the group_vars/host_vars_template.yml file.

## What will be installed and configured?
- Nginx
- Apache
- PHP-FPM
- mod_fastcgi
- mod_rpaf
- MariaDB
- UFW

There will also be some actions taken to ensure security:
- Hiding Nginx and Apache versions
- Blocking access to the Apache port
- Blocking access to MariaDB from outside
- Blocking access by IP address
- Protecting Nginx from slow requests
