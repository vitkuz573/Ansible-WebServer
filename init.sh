#!/bin/bash

read -p "Create an SSH key? NOTE: Only accept if the key has not been created yet! [yes, no]: " answer_ssh_key

if [[ $answer_ssh_key == "yes" ]] || [[ -z $answer_ssh_key ]]; then
  ssh-keygen
else
  echo "You refused to create a key!"
fi

read -p "Enter the number of hosts: " hosts_number
echo " "

rm -R host_vars
rm -R group_vars
mkdir host_vars
mkdir group_vars

count=0

rm hosts.ini
touch hosts.ini
cat <<EOF> hosts.ini
[debian]
EOF

while [ $count -lt $hosts_number ]
do
  echo "Configure host" $(($count + 1))
  echo " "

  read -p "Enable HTTPS? [yes, no]: " answer_https
  if [[ $answer_https == "yes" ]] || [[ -z $answer_https ]]; then
    read -p "Enter SSL Certificate Path: " ssl_certificate_path
    read -p "Enter SSL Certificate Key Path: " ssl_certificate_key_path
  fi

  read -p "Enter IP: " server_ip
  read -p "Enter domain name: " domain_name
  read -p "Enter hostname: " hostname
  read -p "Enter MariaDB password: " mariadb_password

  read -p "Enter phpMyAdmin version (example: 5.0.4): " phpmyadmin_version
  read -p "Securing phpMyAdmin? [yes, no]: " phpmyadmin_secure_answer
  read -p "Enter .htpasswd Username: " htpasswd_username
  read -p "Enter .htpasswd Password: " htpasswd_password

  read -p "Enter port sequence (example: 500,1001,456): " port_sequence

echo $server_ip >> hosts.ini

touch host_vars/$server_ip.yml
cat <<EOF> host_vars/$server_ip.yml
---
https_enabled: "$answer_https"
ssl_certificate_path: "$ssl_certificate_path"
ssl_certificate_key_path: "$ssl_certificate_key_path"

domain_name: "$domain_name"

hostname: "$hostname"

mariadb_password: "$mariadb_password"

phpmyadmin_version: "$phpmyadmin_version"
phpmyadmin_secure: "$phpmyadmin_secure_answer"
htpasswd_username: "$htpasswd_username"
htpasswd_password: "$htpasswd_password"

port_sequence: "$port_sequence"
EOF

echo "Enter your account password on the destination host to copy the public key to it!"

ssh-copy-id root@$server_ip

echo "Host $server_ip successfully configured!"
echo " "
(( count++ ))
done

echo "" >> hosts.ini
echo "[debian:vars]" >> hosts.ini
echo "ansible_python_interpreter=/usr/bin/python3" >> hosts.ini

echo "Configuration of global parameters"
echo " "
echo "Web-Server Ports"
read -p "Enter Apache port: " apache_port
read -p "Enter Nginx port: " nginx_port
echo " "
echo "PHP configuration"
read -p "Enter PHP version: (example: 7.3): " php_version
echo " "
echo "Nginx protection"
read -p "Enter client body timeout: (example: 5): " client_body_timeout
read -p "Enter client header timeout: (example: 5): " client_header_timeout

cat <<EOF> group_vars/vars.yml
---
apache_port: "$apache_port"
nginx_port: "$nginx_port"

php_version: "$php_version"

client_body_timeout: "$client_body_timeout"
client_header_timeout: "$client_header_timeout"
EOF

read -p "To start deploying? [yes, no]: " answer_deploy

if [[ $answer_deploy == "yes" ]] || [[ -z $answer_deploy ]]; then
  ansible-playbook playbook.yml
else
  echo "The deployment was aborted. To start the process, run ansible-playbook playbook.yml"
fi
