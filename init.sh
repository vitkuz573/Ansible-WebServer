#!/bin/bash

function valid_ip() {
    local ip=$1
    local stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -lt 255 && ${ip[3]} -gt 0 ]]
        stat=$?
    fi
    return $stat
}

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
    echo "";

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
                echo -e "Incorrect answer!\n" ;;
        esac
    done

    read -p "Enter the number of hosts: " hosts_number

    count=0

    mkdir {host_vars,group_vars}
    echo "[debian]" > hosts.ini

    while [ $count -lt $hosts_number ]
    do
        echo -e "\nConfigure host" $(($count + 1)) "\n"

        while [[ true ]]; do
            read -p "Enter IP: " server_ip
            valid_ip $server_ip
            if [[ $? -eq 0 ]]; then
                echo ""
                break;
            else
                echo -e "Incorrect IP address!\n"
            fi
        done

        read -p "What port do I need to connect to? (default: 22): " ansible_port
        ansible_port=${ansible_port:-22}

        read -p "What user do I need to login as? (default: root): " ansible_user
        ansible_user=${ansible_user:-root}

        echo ""

        while [[ true ]]; do
            read -p "Enter domain name: " domain_name
            if [[ -z $domain_name ]]; then
                echo -e "The field cannot be empty!\n"
            else
                echo ""
                break;
            fi
        done

        while [[ true ]]; do
            read -p "Enter hostname: " hostname
            if [[ -z $hostname ]]; then
                echo -e "The field cannot be empty!\n"
            else
                echo ""
                break;
            fi
        done

        while [[ true ]]; do
            read -p "Enable HTTPS? [yes, no]: " https_enable
            case $https_enable in
                [Yy]* )
                    https_enable=true;
                    echo -e "\n1) Use a certificate obtained in advance\n2) Get a certificate from Let's Encrypt\n";

                    while [[ true ]]; do
                        read -p "Choose the right option: " ssl_option;
                        case $ssl_option in
                            1 )
                                while [[ true ]]; do
                                    echo ""
                                    read -p "Enter SSL Certificate Path (fullchain): " ssl_certificate
                                    if [[ -z $ssl_certificate ]]; then
                                        echo -e "The field cannot be empty!\n"
                                    else
                                        break;
                                    fi
                                done
                                while [[ true ]]; do
                                    read -p "Enter SSL Trusted Certificate Path (chain): " ssl_trusted_certificate
                                    if [[ -z $ssl_trusted_certificate ]]; then
                                        echo -e "The field cannot be empty!\n"
                                    else
                                        break;
                                    fi
                                done

                                while [[ true ]]; do
                                    read -p "Enter SSL Certificate Key Path: " ssl_certificate_key
                                    if [[ -z $ssl_certificate_key ]]; then
                                        echo -e "The field cannot be empty!\n"
                                    else
                                        break;
                                    fi
                                done
                                break ;;
                            2 )
                                ssl_certificate="/etc/letsencrypt/live/{{ domain['name'] }}/fullchain.pem"
                                ssl_trusted_certificate="/etc/letsencrypt/live/{{ domain['name'] }}/chain.pem"
                                ssl_certificate_key="/etc/letsencrypt/live/{{ domain['name'] }}/privkey.pem"
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
                                break ;;
                            * )
                                echo -e "Incorrect option!\n"
                        esac
                    done
                    echo ""
                    break ;;
                [Nn]* )
                    https_enable=false;
                    echo ""
                    break ;;
                * )
                    echo -e "Incorrect answer!\n";
            esac
        done

        while [[ true ]]; do
            read -p "Install phpMyAdmin? [yes, no]: " phpmyadmin_install
            case $phpmyadmin_install in
                [Yy]* )
                    phpmyadmin_install=true;
                    read -p "Enter phpMyAdmin version (default: 5.0.4): " phpmyadmin_version;
                    phpmyadmin_version=${phpmyadmin_version:-5.0.4}
                    while [[ true ]]; do
                        read -p "Protecting phpMyAdmin? [yes, no]: " phpmyadmin_protect;
                        case $phpmyadmin_protect in
                            [Yy]* )
                                phpmyadmin_protect=true
                                read -p "Enter .htpasswd Username: " htpasswd_username
                                read -p "Enter .htpasswd Password: " htpasswd_password
                                echo "";
                                break ;;
                            [Nn]* )
                                phpmyadmin_protect=false;
                                echo ""
                                break ;;
                            * )
                                echo -e "Incorrect answer!\n" ;;
                        esac
                    done
                    break ;;
                [Nn]* )
                    phpmyadmin_install=false;
                    echo "";
                    break ;;
                * )
                    echo -e "Incorrect answer!\n" ;;
            esac
        done

        #while [[ true ]]; do
        #    read -p "Install fail2ban? [yes, no]: " fail2ban_install
        #    case $fail2ban_install in
        #        [Yy]* )
        #            fail2ban_install=true;
        #            echo "";
        #            break ;;
        #        [Nn]* )
        #            fail2ban_install=false;
        #            echo "";
        #            break ;;
        #        * )
        #            echo -e "Incorrect answer!\n" ;;
        #    esac
        #done

        while [[ true ]]; do
            read -p "Install knockd? [yes, no]: " knockd_install
            case $knockd_install in
                [Yy]* )
                    knockd_install=true;
                    read -p "Enter port sequence (default: 500,1001,456): " port_sequence;
                    port_sequence=${port_sequence:-500,1001,456}
                    read -p "Enter sequence timeout (default: 15): " sequence_timeout
                    sequence_timeout=${sequence_timeout:-15}
                    read -p "Enter command timeout (default: 10): " command_timeout;
                    command_timeout=${command_timeout:-10}
                    echo "";
                    break ;;
                [Nn]* )
                    knockd_install=false;
                    echo "";
                    break ;;
                * )
                    echo -e "Incorrect answer!\n" ;;
            esac
        done

        while [[ true ]]; do
            read -p "Configure sftp? [yes, no]: " sftp_configure
            case $sftp_configure in
                [Yy]* )
                    sftp_configure=true;
                    read -p "Enter sftp root directory: " sftp_root;
                    read -p "Enter sftp username: " sftp_user;
                    read -p "Enter sftp password: " sftp_password;
                    break;
                    echo "" ;;
                [Nn]* )
                    sftp_configure=false;
                    echo "";
                    break ;;
                * )
                    echo -e "Incorrect answer!\n" ;;
            esac
        done

        while [[ true ]]; do
            read -p "Install a firewall? [yes, no]: " firewall_install
            case $firewall_install in
                [Yy]* )
                    echo -e "\nAvailable firewalls:\n\n1) UFW\n"
                    while [[ true ]]; do
                        read -p "Choose a suitable firewall: " firewall
                        case $firewall in
                            1 )
                                firewall_name="ufw";
                                echo "";
                                break ;;
                                #2 )
                                #    firewall_name="firewalld";
                                #    echo "";
                                #    break ;;
                            * )
                                echo -e "Incorrect option!\n" ;;
                        esac
                    done
                    echo "";
                    break ;;
                [Nn]* )
                    echo "";
                    break ;;
                * )
                    echo -e "Incorrect answer!\n" ;;
            esac
        done

        read -p "Enter old MariaDB password (if exists): " mariadb_old_password

        while [[ true ]]; do
            read -p "Enter MariaDB password: " mariadb_password
            if [[ -z $mariadb_password ]]; then
                echo -e "The field cannot be empty!\n"
            else
                echo ""
                break;
            fi
        done

        echo $server_ip ansible_port=$ansible_port ansible_user=$ansible_user >> hosts.ini

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
    certificate: "$ssl_certificate"
    trusted_certificate: "$ssl_trusted_certificate"
    certificate_key: "$ssl_certificate_key"
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

fail2ban:
  install: "$fail2ban_install"

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

firewall:
  name: "$firewall_name"

ssh_log_in:
  port: "$ansible_port"
  user: "$ansible_user"
EOF

        echo "Enter your account password on the destination host to copy the public key to it!"

        ssh-copy-id -p $ansible_port $ansible_user@$server_ip

        echo "Host $server_ip ($domain_name) successfully configured!"
        echo " "
        (( count++ ))
    done

    echo -e "\n[debian:vars]\nansible_python_interpreter=/usr/bin/python3" >> hosts.ini

    echo -e "\nConfiguration of global parameters\n\nWeb-Server Ports"
    read -p "Enter Apache port: " apache_port
    echo -e "\nPHP configuration"
    read -p "Enter PHP version (default: 7.3): " php_version
    php_version=${php_version:-7.3}
    echo -e "\nNginx protection"
    read -p "Enter client body timeout (default: 5): " client_body_timeout
    client_body_timeout=${client_body_timeout:-5}
    read -p "Enter client header timeout (default: 5): " client_header_timeout
    client_header_timeout=${client_header_timeout:-5}
    echo -e "\nProtecting SSH"

    while [[ true ]]; do
        read -p "Enter the port for SSH: " ssh_port
        if [[ -z $ssh_port ]]; then
            echo -e "The field cannot be empty!\n"
        else
            break;
        fi
    done

    while [[ true ]]; do
        read -p "Enter the username: " ssh_username
        if [[ -z $ssh_username ]]; then
            echo -e "The field cannot be empty!\n"
        else
            break;
        fi
    done

    while [[ true ]]; do
        read -p "Enter the password: " ssh_password
        if [[ -z $ssh_password ]]; then
            echo -e "The field cannot be empty!\n"
        else
            break;
        fi
    done
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

ssh:
  port: "$ssh_port"
  credentials:
    user: "$ssh_username"
    password: "$ssh_password"
EOF

    while [[ true ]]; do
        read -p "To start deploying? [yes, no]: " deploy
        case $deploy in
            [Yy]* )
                ansible-playbook playbook.yml --ask-become-pass;
                break ;;
            [Nn]* )
                echo -e "\nThe deployment was aborted. To start the process, run ansible-playbook playbook.yml --ask-become-pass";
                break ;;
            * )
                echo "Incorrect answer!" ;;
        esac
    done

else
    echo "Execution interrupted. To restart, run ./init.sh"
fi
