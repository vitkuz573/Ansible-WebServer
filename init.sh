#!/bin/bash

read -p "Continuing will erase the current configuration! Continue? [yes, no]: " continue_answer
if [[ $continue_answer == "yes" ]]; then
  rm -R {host_vars,group_vars}
  rm hosts.ini
  rm ansible.cfg

  read -p "Create an SSH key? NOTE: Only accept if the key has not been created yet! [yes, no]: " answer_ssh_key

  if [[ $answer_ssh_key == "yes" ]]; then
    ssh-keygen
  else
    echo "You refused to create a key!"
  fi

  read -p "Enter the number of hosts: " hosts_number
  echo " "

  count=0

  mkdir {host_vars,group_vars}
  touch hosts.ini
  echo "[debian]" > hosts.ini

  while [ $count -lt $hosts_number ]
  do
    echo " "
    echo "Configure host" $(($count + 1))
    echo " "

    read -p "Enter IP: " server_ip
    read -p "Enter domain name: " domain_name

    read -p "Enable HTTPS? [yes, no]: " answer_https
    if [[ $answer_https == "yes" ]]; then
      read -p "Enter SSL Certificate Path: " ssl_certificate_path
      read -p "Enter SSL Certificate Key Path: " ssl_certificate_key_path
    fi

    read -p "Enter MariaDB password: " mariadb_password
    read -p "Enter hostname: " hostname

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
  read -p "Enter PHP version (example: 7.3): " php_version
  echo " "
  echo "Nginx protection"
  read -p "Enter client body timeout (example: 5): " client_body_timeout
  read -p "Enter client header timeout (example: 5): " client_header_timeout

  read -p "Install phpMyAdmin? [yes, no]: " install_phpmyadmin_answer
  if [[ $install_phpmyadmin_answer == "yes" ]]; then
    read -p "Enter phpMyAdmin version (example: 5.0.4): " phpmyadmin_version
    read -p "Securing phpMyAdmin? [yes, no]: " phpmyadmin_secure_answer
    if [[ $phpmyadmin_secure_answer == "yes" ]]; then
      read -p "Enter .htpasswd Username: " htpasswd_username
      read -p "Enter .htpasswd Password: " htpasswd_password
    else
      skip_tags+="protecting_phpmyadmin,"
    fi
  else
    skip_tags+="phpmyadmin,protecting_phpmyadmin,"
  fi

  read -p "Install knockd? [yes, no]: " install_knockd_answer
  if [[ $install_knockd_answer == "yes" ]]; then
    read -p "Enter port sequence (example: 500,1001,456): " port_sequence
  else
    skip_tags+="knockd,"
  fi

  read -p "Configure sftp? [yes, no]: " configure_sftp_answer
  if [[ $configure_sftp_answer == "yes" ]]; then
    read -p "Enter sftp root directory: " sftp_root
    read -p "Enter sftp username: " sftp_user
    read -p "Enter sftp password: " sftp_password
  else
    skip_tags+="sftp,"
  fi

cat <<EOF> group_vars/vars.yml
---
apache_port: "$apache_port"
nginx_port: "$nginx_port"

php_version: "$php_version"

client_body_timeout: "$client_body_timeout"
client_header_timeout: "$client_header_timeout"

phpmyadmin_install: "$install_phpmyadmin_answer"
phpmyadmin_version: "$phpmyadmin_version"

phpmyadmin_secure: "$phpmyadmin_secure_answer"
htpasswd_username: "$htpasswd_username"
htpasswd_password: "$htpasswd_password"

knockd_install: "$install_knockd_answer"
port_sequence: "$port_sequence"

sftp_configure: "$configure_sftp_answer"
sftp_root: "$sftp_root"
sftp_user: "$sftp_user"
sftp_password: "$sftp_password"
EOF

touch ansible.cfg
cat <<EOF>> ansible.cfg
[defaults]
inventory = hosts.ini
remote_user = root

[tags]
skip=${skip_tags// /}
EOF

  read -p "To start deploying? [yes, no]: " answer_deploy
  if [[ $answer_deploy == "yes" ]]; then
    ansible-playbook playbook.yml
  else
    echo "The deployment was aborted. To start the process, run ansible-playbook playbook.yml"
  fi
else
  echo "Execution interrupted. To restart, run ./init.sh"
fi
