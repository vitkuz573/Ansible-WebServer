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

read -p "$(gettext "init" "Continuing will erase the current configuration! Continue? [yes, no]: ")" continue
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
  echo ""

  while [[ true ]]; do
    read -p "$(gettext "init" "Create an SSH key? NOTE: Only accept if the key has not been created yet! [yes, no]: ")" generate_ssh_key
    case $generate_ssh_key in
      [Yy]* )
        ssh-keygen
        break
        ;;
      [Nn]* )
        echo "$(gettext "init" "You refused to create a key!")"
        echo ""
        break
        ;;
      * )
        echo "$(gettext "init" "Incorrect answer!")"
        echo ""
        ;;
    esac
  done

  read -p "$(gettext "init" "Enter the number of hosts: ")" hosts_number

  count=0

  mkdir {host_vars,group_vars}
  echo "[debian]" > hosts.ini

  while [ "$count" -lt "$hosts_number" ]
  do
    echo ""
    echo "$(gettext "init" "Configure host")" $((count + 1))
    echo ""

    while [[ true ]]; do
      read -p "Enter IP: " server_ip
      valid_ip "$server_ip"
      if [[ $? -eq 0 ]]; then
        echo ""
        break
      else
        echo "$(gettext "init" "Incorrect IP address!")"
        echo ""
      fi
    done

    echo "$(gettext "init" "Parameters for connecting via SSH:")"
    echo ""
    read -p "$(gettext "init" "Port (default: 22): ")" ansible_port
    ansible_port=${ansible_port:-22}

    read -p "$(gettext "init" "User (default: root): ")" ansible_user
    ansible_user=${ansible_user:-root}

    while [[ true ]]; do
      read -p "$(gettext "init" "Password: ")" ansible_password
      if [[ -z $ansible_password ]]; then
        echo "$(gettext "init" "The field cannot be empty!")"
        echo ""
      else
        echo ""
        break
      fi
    done

    while [[ true ]]; do
      read -p "$(gettext "init" "Domain Name: ")" domain_name
      if [[ -z $domain_name ]]; then
        echo "$(gettext "init" "The field cannot be empty!")"
        echo ""
      else
        echo ""
        break
      fi
    done

    while [[ true ]]; do
      read -p "$(gettext "init" "Hostname: ")" hostname
      if [[ -z $hostname ]]; then
        echo "$(gettext "init" "The field cannot be empty!")"
        echo ""
      else
        echo ""
        break
      fi
    done

    while [[ true ]]; do
      read -p "$(gettext "init" "Enable HTTPS? [yes, no]: ")" https_enable
      case $https_enable in
        [Yy]* )
          https_enable=true
          echo ""
        echo "$(gettext "init" "1) Use a certificate obtained in advance")"
          echo ""
        echo "$(gettext "init" "2) Get a certificate from Let's Encrypt")"
          echo ""
        echo "$(gettext "init" "3) Generate a self-signed certificate")"
          echo ""

          while [[ true ]]; do
            read -p "$(gettext "init" "Choose the right option: ")" ssl_option;
            case $ssl_option in
              1 )
                while [[ true ]]; do
                  echo ""
                  read -p "$(gettext "init" "Enter SSL Certificate Path (fullchain): ")" ssl_certificate
                  if [[ -z $ssl_certificate ]]; then
                    echo "$(gettext "init" "The field cannot be empty!")"
                    echo ""
                  else
                    break
                  fi
                done

                while [[ true ]]; do
                  read -p "$(gettext "init" "Enter SSL Trusted Certificate Path (chain): ")" ssl_trusted_certificate
                  if [[ -z $ssl_trusted_certificate ]]; then
                    echo "$(gettext "init" "The field cannot be empty!")"
                    echo ""
                  else
                    break
                  fi
                done

                while [[ true ]]; do
                  read -p "$(gettext "init" "Enter SSL Certificate Key Path: ")" ssl_certificate_key
                  if [[ -z $ssl_certificate_key ]]; then
                    echo "$(gettext "init" "The field cannot be empty!")"
                    echo ""
                  else
                    break
                  fi
                done
                break
                ;;
              2 )
                ssl_certificate="/etc/letsencrypt/live/{{ domain['name'] }}/fullchain.pem"
                ssl_trusted_certificate="/etc/letsencrypt/live/{{ domain['name'] }}/chain.pem"
                ssl_certificate_key="/etc/letsencrypt/live/{{ domain['name'] }}/privkey.pem"
                echo ""
                while [[ true ]]; do
                  read -p "$(gettext "init" "Enable OCSP Must Staple? [yes, no]: ")" ocsp_must_staple
                  case $ocsp_must_staple in
                    [Yy]* )
                      ocsp_must_staple=true
                      break
                      ;;
                    [Nn]* )
                      ocsp_must_staple=false
                      break
                      ;;
                    * )
                      echo "$(gettext "init" "Incorrect answer!")"
                      ;;
                  esac
                done
                break
                ;;
              3 )
                ssl_certificate="/etc/ssl/self-signed/{{ domain['name'] }}/certificate.pem"
                ssl_certificate_key="/etc/ssl/self-signed/{{ domain['name'] }}/privkey.pem"
                break
                ;;
              * )
                echo "$(gettext "init" "Incorrect option!")"
                echo ""
                ;;
            esac
          done
          echo ""
          break
          ;;
        [Nn]* )
          https_enable=false
          echo ""
          break
          ;;
        * )
          echo "$(gettext "init" "Incorrect answer!")"
          echo ""
          ;;
      esac
    done

    while [[ true ]]; do
      read -p "$(gettext "init" "Install DBMS? [yes, no]: ")" dbms_install
      case $dbms_install in
        [Yy]* )
          dbms_install=true
          echo ""
          echo "$(gettext "init" "Available DBMS:")"
          echo ""
        echo "$(gettext "init" "1) MariaDB")"
          echo ""
        echo "$(gettext "init" "2) MySQL")"
          echo ""
        echo "$(gettext "init" "3) PostgreSQL")"
          echo ""

          while [[ true ]]; do
            read -p "$(gettext "init" "Choose a suitable DBMS: ")" dbms
            case $dbms in
              1 )
                dbms_name="mariadb"

                echo ""
                read -p "$(gettext "init" "Enter old MariaDB password (if exists): ")" dbms_old_password

                while [[ true ]]; do
                  read -p "$(gettext "init" "Enter MariaDB password: ")" dbms_new_password
                  if [[ -z $dbms_new_password ]]; then
                    echo "$(gettext "init" "The field cannot be empty!")"
                    echo ""
                  else
                    break
                  fi
                done

                echo ""
                break
                ;;
              2 )
                dbms_name="mysql"

                echo ""
                read -p "$(gettext "init" "Enter old MySQL password (if exists): ")" dbms_old_password

                while [[ true ]]; do
                  read -p "$(gettext "init" "Enter MySQL password: ")" dbms_new_password
                  if [[ -z $dbms_new_password ]]; then
                    echo "$(gettext "init" "The field cannot be empty!")"
                    echo ""
                  else
                    break
                  fi
                done

                echo ""
                break
                ;;
              3 )
                dbms_name="postgresql"

                echo ""
                read -p "$(gettext "init" "Enter PostgreSQL version (default: 12): ")" postgresql_version
                postgresql_version=${postgresql_version:-12}

                while [[ true ]]; do
                  read -p "$(gettext "init" "Enter PostgreSQL password: ")" dbms_new_password
                  if [[ -z $dbms_new_password ]]; then
                    echo "$(gettext "init" "The field cannot be empty!")"
                    echo ""
                  else
                    break
                  fi
                done

                echo ""
                break
                ;;
              * )
                echo "$(gettext "init" "Incorrect option!")"
                echo ""
                ;;
            esac
          done

          if [[ $dbms_name != "postgresql" ]]; then
            while [[ true ]]; do
              read -p "$(gettext "init" "Install phpMyAdmin? [yes, no]: ")" phpmyadmin_install
              case $phpmyadmin_install in
                [Yy]* )
                  phpmyadmin_install=true

                  read -p "$(gettext "init" "Enter phpMyAdmin version (default: 5.1.0): ")" phpmyadmin_version
                  phpmyadmin_version=${phpmyadmin_version:-5.1.0}

                  while [[ true ]]; do
                    read -p "$(gettext "init" "Protecting phpMyAdmin? [yes, no]: ")" phpmyadmin_protect
                    case $phpmyadmin_protect in
                      [Yy]* )
                        phpmyadmin_protect=true
                        read -p "$(gettext "init" "Enter .htpasswd Username: ")" htpasswd_username
                        read -p "$(gettext "init" "Enter .htpasswd Password: ")" htpasswd_password
                        echo ""
                        break
                        ;;
                      [Nn]* )
                        phpmyadmin_protect=false
                        echo ""
                        break
                        ;;
                      * )
                        echo "$(gettext "init" "Incorrect answer!")"
                        echo ""
                        ;;
                    esac
                  done

                  break
                  ;;
                [Nn]* )
                  phpmyadmin_install=false
                  echo ""
                  break
                  ;;
                * )
                  echo "$(gettext "init" "Incorrect answer!")"
                  echo ""
                  ;;
              esac
            done
          fi

          if [[ $dbms_name == "postgresql" ]]; then
            while [[ true ]]; do
              read -p "$(gettext "init" "Install pgAdmin? [yes, no]: ")" pgadmin_install
              case $pgadmin_install in
                [Yy]* )
                  pgadmin_install=true

                  while [[ true ]]; do
                    read -p "$(gettext "init" "Protecting pgAdmin? [yes, no]: ")" phpmyadmin_protect
                    case $pgadmin_protect in
                      [Yy]* )
                        pgadmin_protect=true
                        read -p "$(gettext "init" "Enter .htpasswd Username: ")" htpasswd_username
                        read -p "$(gettext "init" "Enter .htpasswd Password: ")" htpasswd_password
                        echo ""
                        break
                        ;;
                      [Nn]* )
                        pgadmin_protect=false
                        echo ""
                        break
                        ;;
                      * )
                        echo "$(gettext "init" "Incorrect answer!")"
                        echo ""
                        ;;
                    esac
                  done

                  break
                  ;;
                [Nn]* )
                  pgadmin_install=false
                  break
                  ;;
                * )
                  echo "$(gettext "init" "Incorrect answer!")"
                  echo ""
                  ;;
              esac
            done
          fi

          break
          ;;
        [Nn]* )
          dbms_install=false
          echo ""
          break
          ;;
        * )
          echo "$(gettext "init" "Incorrect answer!")"
          echo ""
          ;;
      esac
    done

    #while [[ true ]]; do
    #    read -p "Install fail2ban? [yes, no]: " fail2ban_install
    #    case $fail2ban_install in
    #        [Yy]* )
    #            fail2ban_install=true
    #            echo ""
    #            break
    #            ;;
    #        [Nn]* )
    #            fail2ban_install=false
    #            echo ""
    #            break
    #            ;;
    #        * )
    #            echo -e "Incorrect answer!\n"
    #            ;;
    #    esac
    #done

    while [[ true ]]; do
      read -p "$(gettext "init" "Install knockd? [yes, no]: ")" knockd_install
      case $knockd_install in
        [Yy]* )
          knockd_install=true
          read -p "$(gettext "init" "Enter port sequence (default: 500,1001,456): ")" port_sequence
          port_sequence=${port_sequence:-500,1001,456}
          read -p "$(gettext "init" "Enter sequence timeout (default: 15): ")" sequence_timeout
          sequence_timeout=${sequence_timeout:-15}
          read -p "$(gettext "init" "Enter command timeout (default: 10): ")" command_timeout
          command_timeout=${command_timeout:-10}
          echo ""
          break
          ;;
        [Nn]* )
          knockd_install=false
          echo ""
          break
          ;;
        * )
          echo "$(gettext "init" "Incorrect answer!")"
          echo ""
          ;;
      esac
    done

    while [[ true ]]; do
      read -p "$(gettext "init" "Configure sftp? [yes, no]: ")" sftp_configure
      case $sftp_configure in
        [Yy]* )
          sftp_configure=true
          read -p "$(gettext "init" "Enter sftp root directory: ")" sftp_root
          read -p "$(gettext "init" "Enter sftp username: ")" sftp_user
          read -p "$(gettext "init" "Enter sftp password: ")" sftp_password
          break
          echo ""
          ;;
        [Nn]* )
          sftp_configure=false
          echo ""
          break
          ;;
        * )
          echo "$(gettext "init" "Incorrect answer!")"
          echo ""
          ;;
      esac
    done

    while [[ true ]]; do
      read -p "$(gettext "init" "Install a firewall? [yes, no]: ")" firewall_install
      case $firewall_install in
        [Yy]* )
          firewall_install="true"
          echo ""
          echo "$(gettext "init" "Available firewalls:")"
          echo ""
        echo "$(gettext "init" "1) UFW")"
          echo ""

          while [[ true ]]; do
            read -p "$(gettext "init" "Choose a suitable firewall: ")" firewall
            case $firewall in
              1 )
                firewall_name="ufw"
                echo ""
                break
                ;;
                #2 )
                #    firewall_name="firewalld"
                #    echo ""
                #    break
                #    ;;
              * )
                echo "$(gettext "init" "Incorrect option!")"
                echo ""
                ;;
            esac
          done
          break
          ;;
        [Nn]* )
          firewall_install="false"
          echo ""
          break
          ;;
        * )
          echo "$(gettext "init" "Incorrect answer!")"
          echo ""
          ;;
      esac
    done

    echo "$server_ip" ansible_port="$ansible_port" ansible_user="$ansible_user" ansible_become_password="$ansible_password" >> hosts.ini

    cat <<EOF> host_vars/"$server_ip".yml
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

dbms:
  install: "$dbms_install"
  name: "$dbms_name"
  credentials:
    password:
      old: "$dbms_old_password"
      new: "$dbms_new_password"

postgresql:
  version: "$postgresql_version"

phpmyadmin:
  install: "$phpmyadmin_install"
  version: "$phpmyadmin_version"
  protect:
    enable: "$phpmyadmin_protect"
    credentials:
      user: "$htpasswd_username"
      password: "$htpasswd_password"

pgadmin:
  install: "$pgadmin_install"
  protect:
    enable: "$pgadmin_protect"
    credentials:
      user: "$htpasswd_username"
      password: "$htpasswd_password"

fail2ban:
  install: "$fail2ban_install"

knockd:
  install: "$knockd_install"
  port_sequence: "$port_sequence"
  port_sequence_whitespaces: "${port_sequence//,/ }"
  command_timeout: "$command_timeout"

sftp:
  configure: "$sftp_configure"
  root: "$sftp_root"
  credentials:
    user: "$sftp_user"
    password: "$sftp_password"

firewall:
  install: "$firewall_install"
  name: "$firewall_name"
EOF

    echo "$(gettext "init" "Enter your account password on the destination host to copy the public key to it!")"

    ssh-copy-id -p "$ansible_port" "$ansible_user"@"$server_ip"

    echo "$(gettext "init" "Host $server_ip ($domain_name) successfully configured!")"
    echo " "
    (( count++ ))
  done

  echo -e "\n[debian:vars]\nansible_python_interpreter=/usr/bin/python3" >> hosts.ini
  echo ""
  echo "$(gettext "init" "Configuration of global parameters")"
  echo ""
  echo "$(gettext "init" "Web-Server Ports")"
  echo ""
  read -p "$(gettext "init" "Enter Apache port: ")" apache_port
  echo ""

  # PHP Configuration
  echo "$(gettext "init" "PHP configuration")"
  echo ""
  read -p "$(gettext "init" "Enter PHP version (default: 8.0): ")" php_version
  php_version=${php_version:-8.0}
  echo ""

  # Nginx Protection
  echo "$(gettext "init" "Nginx protection")"
  echo ""
  read -p "$(gettext "init" "Enter client body timeout (default: 5): ")" client_body_timeout
  client_body_timeout=${client_body_timeout:-5}
  read -p "$(gettext "init" "Enter client header timeout (default: 5): ")" client_header_timeout
  client_header_timeout=${client_header_timeout:-5}
  echo ""

  # SSH Protection
  echo "$(gettext "init" "SSH Protection")"

  while [[ true ]]; do
    read -p "$(gettext "init" "Enter the port for SSH: ")" ssh_port
    if [[ -z $ssh_port ]]; then
      echo "$(gettext "init" "The field cannot be empty!")"
      echo ""
    else
      break
    fi
  done

  while [[ true ]]; do
    read -p "$(gettext "init" "Enter the username: ")" ssh_username
    if [[ -z $ssh_username ]]; then
      echo "$(gettext "init" "The field cannot be empty!")"
      echo ""
    else
      break
    fi
  done

  while [[ true ]]; do
    read -p "$(gettext "init" "Enter the password: ")" ssh_password
    if [[ -z $ssh_password ]]; then
      echo "$(gettext "init" "The field cannot be empty!")"
      echo ""
    else
      break
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
    read -p "$(gettext "init" "To start deploying? [yes, no]: ")" deploy
    case $deploy in
      [Yy]* )
        ansible-playbook playbook.yml
        break
        ;;
      [Nn]* )
        echo ""
        echo "$(gettext "init" "The deployment was aborted. To start the process, run ansible-playbook playbook.yml")"
        break
        ;;
      * )
        echo "$(gettext "init" "Incorrect answer!")"
        ;;
    esac
  done

else
  echo "$(gettext "init" "Execution interrupted. To restart, run ./init.sh")"
fi
