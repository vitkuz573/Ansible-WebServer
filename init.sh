#!/bin/bash

read -p "Continuing will erase the current configuration! Continue? [yes, no]: " continue
if [[ $continue == "yes" ]]; then
    if [[ -e host_vars ]]; then
        rm -R host_vars
    fi
    if [[ -e group_vars ]]; then
        rm -R group_vars
    fi
    if [[ -e hosts.ini ]]; then
        rm hosts.ini
    fi

    while [[ true ]]; do
        read -p "Create an SSH key? NOTE: Only accept if the key has not been created yet! [yes, no]: " generate_ssh_key
        case $generate_ssh_key in
            [Yy]* )
                ssh-keygen;
                break ;;
            [Nn]* )
                echo -e "You refused to create a key!\n";
                break ;;
            * )
                echo "Incorrect answer!" ;;
        esac
    done

    read -p "Enter the number of hosts: " hosts_number

    count=0

    mkdir {host_vars,group_vars}
    echo "[debian]" > hosts.ini

    while [ $count -lt $hosts_number ]
    do
        echo -e "\nConfigure host" $(($count + 1)) "\n"

        read -p "Enter IP: " server_ip
        echo ""

        read -p "Enter domain name: " domain_name
        echo ""

        read -p "Enter hostname: " hostname
        echo ""

        while [[ true ]]; do
            read -p "Enable HTTPS? [yes, no]: " https_enable
            case $https_enable in
                [Yy]* )
                    https_enable=yes;
                    echo -e "\n1) Use a certificate obtained in advance\n2) Generate a Let's Encrypt certificate\n";
                    read -p "Choose the right option: " ssl_option;
                    if [[ $ssl_option == "1" ]]; then
                        read -p "Enter SSL Certificate Path (chain): " ssl_certificate_path
                        read -p "Enter SSL Trusted Certificate Path (fullchain): " ssl_trusted_certificate
                        read -p "Enter SSL Certificate Key Path: " ssl_certificate_key_path
                    fi
                    if [[ $ssl_option == "2" ]]; then
                        ssl_certificate_path="/etc/letsencrypt/live/{{ domain_name }}/fullchain.pem"
                        ssl_trusted_certificate="/etc/letsencrypt/live/{{ domain_name }}/chain.pem"
                        ssl_certificate_key_path="/etc/letsencrypt/live/{{ domain_name }}/privkey.pem"
                        echo ""
                        while [[ true ]]; do
                            read -p "Enable OCSP Must Staple? [yes, no]: " ocsp_must_staple
                            case $ocsp_must_staple in
                                [Yy]* )
                                    ocsp_must_staple=true;
                                    break ;;
                                [Nn]* )
                                    ocsp_must_staple=false;
                                    break ;;
                                * )
                                    echo "Incorrect answer!" ;;
                            esac
                        done
                    fi

                    echo "";
                    break ;;
                [Nn]* )
                    https_enable=no;
                    echo "";
                    break ;;
                * )
                    echo "Incorrect answer!";
            esac
        done

        while [[ true ]]; do
            read -p "Install phpMyAdmin? [yes, no]: " phpmyadmin_install
            case $phpmyadmin_install in
                [Yy]* )
                    phpmyadmin_install=yes;
                    read -p "Enter phpMyAdmin version (example: 5.0.4): " phpmyadmin_version;
                    read -p "Protecting phpMyAdmin? [yes, no]: " phpmyadmin_protect;
                    if [[ $phpmyadmin_protect == "yes" ]]; then
                        read -p "Enter .htpasswd Username: " htpasswd_username
                        read -p "Enter .htpasswd Password: " htpasswd_password
                    fi;
                    echo "";
                    break ;;
                [Nn]* )
                    phpmyadmin_install=no;
                    echo "";
                    break ;;
                * )
                    echo "Incorrect answer!" ;;
            esac
        done

        while [[ true ]]; do
            read -p "Install knockd? [yes, no]: " knockd_install
            case $knockd_install in
                [Yy]* )
                    knockd_install=yes;
                    read -p "Enter port sequence (example: 500,1001,456): " port_sequence;
                    read -p "Enter command timeout (example: 10): " command_timeout;
                    echo "";
                    break ;;
                [Nn]* )
                    knockd_install=no;
                    echo "";
                    break ;;
                * )
                    echo "Incorrect answer!" ;;
            esac
        done

        while [[ true ]]; do
            read -p "Configure sftp? [yes, no]: " sftp_configure
            case $sftp_configure in
                [Yy]* )
                    sftp_configure=yes;
                    read -p "Enter sftp root directory: " sftp_root;
                    read -p "Enter sftp username: " sftp_user;
                    read -p "Enter sftp password: " sftp_password;
                    break;
                    echo "" ;;
                [Nn]* )
                    sftp_configure=no;
                    echo "";
                    break ;;
                * )
                    echo "Incorrect answer!" ;;
            esac
        done

        read -p "Enter old MariaDB password (if exists): " mariadb_old_password
        read -p "Enter MariaDB password: " mariadb_password
        echo ""

        echo $server_ip >> hosts.ini

        cat <<EOF> host_vars/$server_ip.yml
---
host:
  name: "$hostname"

domain:
  name: "$domain_name"

https:
  enable: "$https_enable"
  option: "$ssl_option"
  ssl:
    certificate: "$ssl_certificate_path"
    trusted_certificate: "$ssl_trusted_certificate"
    certificate_key: "$ssl_certificate_key_path"
    ocsp:
      must_staple: "$ocsp_must_staple"

phpmyadmin:
  install: "$phpmyadmin_install"
  version: "$phpmyadmin_version"
  protect:
    enable: "$phpmyadmin_protect"
    credentials:
      user: "$htpasswd_username"
      password: "$htpasswd_password"

knockd:
  install: "$knockd_install"
  port_sequence: "$port_sequence"
  port_sequence_spaces: "${port_sequence//,/ }"
  command_timeout: "$command_timeout"

sftp:
  configure: "$sftp_configure"
  root: "$sftp_root"
  credentials:
    user: "$sftp_user"
    password: "$sftp_password"

mariadb:
  password:
    old: "$mariadb_old_password"
    new: "$mariadb_password"
EOF

        echo "Enter your account password on the destination host to copy the public key to it!"

        ssh-copy-id root@$server_ip

        echo "Host $server_ip ($domain_name) successfully configured!"
        echo " "
        (( count++ ))
    done

    echo -e "\n[debian:vars]\nansible_python_interpreter=/usr/bin/python3" >> hosts.ini

    echo -e "\nConfiguration of global parameters\n\nWeb-Server Ports"
    read -p "Enter Apache port: " apache_port
    echo -e "\nPHP configuration"
    read -p "Enter PHP version (example: 7.3): " php_version
    echo -e "\nNginx protection"
    read -p "Enter client body timeout (example: 5): " client_body_timeout
    read -p "Enter client header timeout (example: 5): " client_header_timeout
    echo ""

    cat <<EOF> group_vars/vars.yml
---
apache:
  port: "$apache_port"

nginx:
  timeout:
    client:
      body: "$client_body_timeout"
      header: "$client_header_timeout"

php:
  version: "$php_version"
EOF

    while [[ true ]]; do
        read -p "To start deploying? [yes, no]: " deploy
        case $deploy in
            [Yy]* )
                ansible-playbook playbook.yml;
                break ;;
            [Nn]* )
                echo "The deployment was aborted. To start the process, run ansible-playbook playbook.yml";
                break ;;
            * )
                echo "Incorrect answer!" ;;
        esac
    done

else
    echo "Execution interrupted. To restart, run ./init.sh"
fi
