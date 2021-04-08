#!/bin/bash

shopt -s expand_aliases
alias GETTEXT='gettext "init"'

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

read -p "$(GETTEXT "Continuing will erase the current configuration! Continue? [yes, no]: ")" continue
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
    read -p "$(GETTEXT "Create an SSH key? NOTE: Only accept if the key has not been created yet! [yes, no]: ")" generate_ssh_key
    case $generate_ssh_key in
      [Yy]* )
        ssh-keygen
        break
        ;;
      [Nn]* )
        echo "$(GETTEXT "You refused to create a key!")"
        echo ""
        break
        ;;
      * )
        echo "$(GETTEXT "Incorrect answer!")"
        echo ""
        ;;
    esac
  done

  read -p "$(GETTEXT "Enter the number of hosts: ")" hosts_number

  count=0

  mkdir {host_vars,group_vars}
  echo "[debian]" > hosts.ini

  while [ "$count" -lt "$hosts_number" ]
  do
    echo ""
    echo "$(GETTEXT "Configure host")" $((count + 1))
    echo ""

    while [[ true ]]; do
      read -p "$(GETTEXT "IP Address: ")" server_ip
      valid_ip "$server_ip"
      if [[ $? -eq 0 ]]; then
        echo ""
        break
      else
        echo "$(GETTEXT "Incorrect IP address!")"
        echo ""
      fi
    done

    echo "$(GETTEXT "Parameters for connecting via SSH:")"
    echo ""
    read -p "$(GETTEXT "Port (default: 22): ")" ansible_port
    ansible_port=${ansible_port:-22}

    read -p "$(GETTEXT "User (default: root): ")" ansible_user
    ansible_user=${ansible_user:-root}

    while [[ true ]]; do
      read -p "$(GETTEXT "Password: ")" ansible_password
      if [[ -z $ansible_password ]]; then
        echo "$(GETTEXT "The field cannot be empty!")"
        echo ""
      else
        echo ""
        break
      fi
    done

    while [[ true ]]; do
      read -p "$(GETTEXT "Domain Name: ")" domain_name
      if [[ -z $domain_name ]]; then
        echo "$(GETTEXT "The field cannot be empty!")"
        echo ""
      else
        echo ""
        break
      fi
    done

    while [[ true ]]; do
      read -p "$(GETTEXT "Hostname: ")" hostname
      if [[ -z $hostname ]]; then
        echo "$(GETTEXT "The field cannot be empty!")"
        echo ""
      else
        echo ""
        break
      fi
    done

    while [[ true ]]; do
      read -p "$(GETTEXT "Enable HTTPS? [yes, no]: ")" https_enable
      case $https_enable in
        [Yy]* )
          https_enable=true
          echo ""
        echo "$(GETTEXT "1) Use a certificate obtained in advance")"
        echo "$(GETTEXT "2) Get a certificate from Let's Encrypt")"
        echo "$(GETTEXT "3) Generate a self-signed certificate")"
          echo ""

          while [[ true ]]; do
            read -p "$(GETTEXT "Choose the right option: ")" ssl_option;
            case $ssl_option in
              1 )
                while [[ true ]]; do
                  echo ""
                  read -p "$(GETTEXT "SSL Certificate Path (fullchain): ")" ssl_certificate
                  if [[ -z $ssl_certificate ]]; then
                    echo "$(GETTEXT "The field cannot be empty!")"
                    echo ""
                  else
                    break
                  fi
                done

                while [[ true ]]; do
                  read -p "$(GETTEXT "SSL Trusted Certificate Path (chain): ")" ssl_trusted_certificate
                  if [[ -z $ssl_trusted_certificate ]]; then
                    echo "$(GETTEXT "The field cannot be empty!")"
                    echo ""
                  else
                    break
                  fi
                done

                while [[ true ]]; do
                  read -p "$(GETTEXT "SSL Certificate Key Path: ")" ssl_certificate_key
                  if [[ -z $ssl_certificate_key ]]; then
                    echo "$(GETTEXT "The field cannot be empty!")"
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
                  read -p "$(GETTEXT "Enable OCSP Must Staple? [yes, no]: ")" ocsp_must_staple
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
                      echo "$(GETTEXT "Incorrect answer!")"
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
                echo "$(GETTEXT "Incorrect answer!")"
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
          echo "$(GETTEXT "Incorrect answer!")"
          echo ""
          ;;
      esac
    done

    while [[ true ]]; do
      read -p "$(GETTEXT "Install DBMS? [yes, no]: ")" dbms_install
      case $dbms_install in
        [Yy]* )
          dbms_install=true
          echo ""
          echo "$(GETTEXT "Available DBMS:")"
          echo ""
        echo "$(GETTEXT "1) MariaDB")"
        echo "$(GETTEXT "2) MySQL")"
        echo "$(GETTEXT "3) PostgreSQL")"
          echo ""

          while [[ true ]]; do
            read -p "$(GETTEXT "Choose a suitable DBMS: ")" dbms
            case $dbms in
              1 )
                dbms_name="mariadb"

                echo ""
                read -p "$(GETTEXT "Old password (if exists): ")" dbms_old_password

                while [[ true ]]; do
                  read -p "$(GETTEXT "Password: ")" dbms_new_password
                  if [[ -z $dbms_new_password ]]; then
                    echo "$(GETTEXT "The field cannot be empty!")"
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
                read -p "$(GETTEXT "Old password (if exists): ")" dbms_old_password

                while [[ true ]]; do
                  read -p "$(GETTEXT "Password: ")" dbms_new_password
                  if [[ -z $dbms_new_password ]]; then
                    echo "$(GETTEXT "The field cannot be empty!")"
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
                read -p "$(GETTEXT "Version (default: 12): ")" postgresql_version
                postgresql_version=${postgresql_version:-12}

                while [[ true ]]; do
                  read -p "$(GETTEXT "Password: ")" dbms_new_password
                  if [[ -z $dbms_new_password ]]; then
                    echo "$(GETTEXT "The field cannot be empty!")"
                    echo ""
                  else
                    break
                  fi
                done

                echo ""
                break
                ;;
              * )
                echo "$(GETTEXT "Incorrect answer!")"
                echo ""
                ;;
            esac
          done

          if [[ $dbms_name != "postgresql" ]]; then
            while [[ true ]]; do
              read -p "$(GETTEXT "Install phpMyAdmin? [yes, no]: ")" phpmyadmin_install
              case $phpmyadmin_install in
                [Yy]* )
                  phpmyadmin_install=true

                  read -p "$(GETTEXT "Version (default: 5.1.0): ")" phpmyadmin_version
                  phpmyadmin_version=${phpmyadmin_version:-5.1.0}

                  while [[ true ]]; do
                    read -p "$(GETTEXT "Protecting phpMyAdmin? [yes, no]: ")" phpmyadmin_protect
                    case $phpmyadmin_protect in
                      [Yy]* )
                        phpmyadmin_protect=true
                        read -p "$(GETTEXT "Login: ")" htpasswd_username
                        read -p "$(GETTEXT "Password: ")" htpasswd_password
                        echo ""
                        break
                        ;;
                      [Nn]* )
                        phpmyadmin_protect=false
                        echo ""
                        break
                        ;;
                      * )
                        echo "$(GETTEXT "Incorrect answer!")"
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
                  echo "$(GETTEXT "Incorrect answer!")"
                  echo ""
                  ;;
              esac
            done
          fi

          # if [[ $dbms_name == "postgresql" ]]; then
          #   while [[ true ]]; do
          #     read -p "$(GETTEXT "Install pgAdmin? [yes, no]: ")" pgadmin_install
          #     case $pgadmin_install in
          #       [Yy]* )
          #         pgadmin_install=true
          #
          #         while [[ true ]]; do
          #           read -p "$(GETTEXT "Protecting pgAdmin? [yes, no]: ")" pgadmin_protect
          #           case $pgadmin_protect in
          #             [Yy]* )
          #               pgadmin_protect=true
          #               read -p "$(GETTEXT "Login: ")" htpasswd_username
          #               read -p "$(GETTEXT "Password: ")" htpasswd_password
          #               echo ""
          #               break
          #               ;;
          #             [Nn]* )
          #               pgadmin_protect=false
          #               echo ""
          #               break
          #               ;;
          #             * )
          #               echo "$(GETTEXT "Incorrect answer!")"
          #               echo ""
          #               ;;
          #           esac
          #         done
          #
          #         break
          #         ;;
          #       [Nn]* )
          #         pgadmin_install=false
          #         break
          #         ;;
          #       * )
          #         echo "$(GETTEXT "Incorrect answer!")"
          #         echo ""
          #         ;;
          #     esac
          #   done
          # fi

          break
          ;;
        [Nn]* )
          dbms_install=false
          echo ""
          break
          ;;
        * )
          echo "$(GETTEXT "Incorrect answer!")"
          echo ""
          ;;
      esac
    done

    # while [[ true ]]; do
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
    #            echo "$(GETTEXT "Incorrect answer!")"
    #            echo ""
    #            ;;
    #    esac
    # done

    while [[ true ]]; do
      read -p "$(GETTEXT "Install knockd? [yes, no]: ")" knockd_install
      case $knockd_install in
        [Yy]* )
          knockd_install=true
          read -p "$(GETTEXT "Port sequence (default: 500,1001,456): ")" port_sequence
          port_sequence=${port_sequence:-500,1001,456}
          read -p "$(GETTEXT "Sequence timeout (default: 15): ")" sequence_timeout
          sequence_timeout=${sequence_timeout:-15}
          read -p "$(GETTEXT "Command timeout (default: 10): ")" command_timeout
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
          echo "$(GETTEXT "Incorrect answer!")"
          echo ""
          ;;
      esac
    done

    while [[ true ]]; do
      read -p "$(GETTEXT "Configure sftp? [yes, no]: ")" sftp_configure
      case $sftp_configure in
        [Yy]* )
          sftp_configure=true
          read -p "$(GETTEXT "Root directory: ")" sftp_root
          read -p "$(GETTEXT "Login: ")" sftp_user
          read -p "$(GETTEXT "Password: ")" sftp_password
          break
          echo ""
          ;;
        [Nn]* )
          sftp_configure=false
          echo ""
          break
          ;;
        * )
          echo "$(GETTEXT "Incorrect answer!")"
          echo ""
          ;;
      esac
    done

    while [[ true ]]; do
      read -p "$(GETTEXT "Install a firewall? [yes, no]: ")" firewall_install
      case $firewall_install in
        [Yy]* )
          firewall_install="true"
          echo ""
          echo "$(GETTEXT "Available firewalls:")"
          echo ""
        echo "$(GETTEXT "1) UFW")"
          # echo "$(GETTEXT "2) Firewalld")"
          echo ""

          while [[ true ]]; do
            read -p "$(GETTEXT "Choose a suitable firewall: ")" firewall
            case $firewall in
              1 )
                firewall_name="ufw"
                echo ""
                break
                ;;
                # 2 )
                # firewall_name="firewalld"
                # echo ""
                # break
                # ;;
              * )
                echo "$(GETTEXT "Incorrect answer!")"
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
          echo "$(GETTEXT "Incorrect answer!")"
          echo ""
          ;;
      esac
    done

    while [[ true ]]; do
      read -p "$(GETTEXT "Protect SSH? [yes, no]: ")" ssh_protection
      case $ssh_protection in
        [Yy]* )
          ssh_protection=true
          echo ""
          while [[ true ]]; do
            read -p "$(GETTEXT "Port: ")" ssh_port
            if [[ -z $ssh_port ]]; then
              echo "$(GETTEXT "The field cannot be empty!")"
              echo ""
            else
              break
            fi
          done

          while [[ true ]]; do
            read -p "$(GETTEXT "Login: ")" ssh_username
            if [[ -z $ssh_username ]]; then
              echo "$(GETTEXT "The field cannot be empty!")"
              echo ""
            else
              break
            fi
          done

          while [[ true ]]; do
            read -p "$(GETTEXT "Password: ")" ssh_password
            if [[ -z $ssh_password ]]; then
              echo "$(GETTEXT "The field cannot be empty!")"
              echo ""
            else
              break
            fi
          done
          echo ""
          break
          ;;
        [Nn]* )
          ssh_protection=false
          echo ""
          break
          ;;
        * )
          echo "$(GETTEXT "Incorrect answer!")"
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

ssh:
  protect: "$ssh_protection"
  port: "$ssh_port"
  credentials:
    user: "$ssh_username"
    password: "$ssh_password"
EOF

    sshpass -p $ansible_password ssh-copy-id -p "$ansible_port" "$ansible_user"@"$server_ip"

    echo "$(GETTEXT "Host")" $server_ip "("$domain_name")" "$(GETTEXT "successfully configured!")"
    echo " "
    (( count++ ))
  done

  echo -e "\n[debian:vars]\nansible_python_interpreter=/usr/bin/python3" >> hosts.ini
  echo ""
  echo "$(GETTEXT "Configuration of global parameters")"
  echo ""

  # Web-Server Ports
  echo "$(GETTEXT "Web-Server ports")"
  echo ""
  while [[ true ]]; do
    read -p "$(GETTEXT "Apache port: ")" apache_port
    if [[ -z $apache_port ]]; then
      echo "$(GETTEXT "The field cannot be empty!")"
      echo ""
    else
      break
    fi
  done
  echo ""

  # PHP Configuration
  echo "$(GETTEXT "PHP configuration")"
  echo ""
  read -p "$(GETTEXT "Version (default: 8.0): ")" php_version
  php_version=${php_version:-8.0}
  echo ""

  # Nginx Protection
  echo "$(GETTEXT "Nginx protection")"
  echo ""
  read -p "$(GETTEXT "Client body timeout (default: 5): ")" client_body_timeout
  client_body_timeout=${client_body_timeout:-5}
  read -p "$(GETTEXT "Client header timeout (default: 5): ")" client_header_timeout
  client_header_timeout=${client_header_timeout:-5}
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
    read -p "$(GETTEXT "To start deploying? [yes, no]: ")" deploy
    case $deploy in
      [Yy]* )
        ansible-playbook playbook.yml
        break
        ;;
      [Nn]* )
        echo ""
        echo "$(GETTEXT "The deployment was aborted. To start the process, run ansible-playbook playbook.yml")"
        break
        ;;
      * )
        echo "$(GETTEXT "Incorrect answer!")"
        echo ""
        ;;
    esac
  done

else
  echo "$(GETTEXT "Execution interrupted. To restart, run ./init.sh")"
fi
