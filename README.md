# Ansible-WebServer
Playbook for fully automated deployment of one or more web servers (Nginx+Apache)

____

## Usage

Before running playbook, specify the Apache port (apache_port) and the PHP version (php_fpm_version) in the vars/vars.yml file. The value of the Nginx port (nginx_port) must be left at 80 to save access to the web server without specifying the port.

Also create a file with individual host variables (the template is in the file vars/host_vars_template.yml) in which you specify:
- domain name
- hostname
- password to access the DBMS
The file name format should be: ip_address.yml
For example: 192.168.52.129.yml

Finally, specify the ip addresses of hosts in the hosts.ini file.

NOTE: before running playbook you need to set up ssh authorization by keys!

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
