#!/bin/bash

read -p "Create an SSH key? NOTE: Only accept if the key has not been created yet! [yes, no]: " answer_ssh_key

if [[ $answer_ssh_key == "yes" ]] || [[ -z $answer_ssh_key ]]; then
  ssh-keygen
else
  echo "You refused to create a key!"
fi

read -p "Enter the number of hosts: " hosts_number
echo " "

rm -R vars
mkdir vars

count=0

while [ $count -lt $hosts_number ]
do
  read -p "Enable HTTPS? [yes, no]: " answer_https
  if [[ $answer_https == "yes" ]] || [[ -z $answer_https ]]; then
    read -p "Enter SSL Certificate Path: " ssl_certificate_path
    read -p "Enter SSL Certificate Key Path: "ssl_certificate_key_path
  fi
  read -p "Enter IP: " server_ip
  read -p "Enter domain name: " domain_name
  read -p "Enter hostname: " hostname
  read -p "Enter MariaDB password: " mariadb_password

rm hosts.ini
touch hosts.ini
cat <<EOF> hosts.ini
[debian]
$server_ip
EOF

touch vars/$server_ip.yml
cat <<EOF> vars/$server_ip.yml
---
  https_enabled: "$answer_https"
  ssl_certificate_path: "$ssl_certificate_path"
  ssl_certificate_key_path: "$ssl_certificate_key_path"

  domain_name: "$domain_name"

  hostname: "$hostname"

  mariadb_password: "$mariadb_password"
EOF

echo "Enter your account password on the destination host to copy the public key to it!"

ssh-copy-id root@$server_ip

echo "Host $server_ip successfully configured!"
echo " "
(( count++ ))
done

echo "Web-Server Ports"
read -p "Enter Apache port: " apache_port
read -p "Enter Nginx port: " nginx_port
echo " "
echo "PHP Configuration"
read -p "Enter PHP version: (example: 7.3): " php_version
echo " "
echo "Nginx Secure"
read -p "Enter client body timeout: (example: 5): " client_body_timeout
read -p "Enter client header timeout: (example: 5): " client_header_timeout

cat <<EOF> vars/vars.yml
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
