#!/bin/bash

# Based on setup_gpadmin_user.bash from GPDB Concourse scripts

set -euxo pipefail
setup_ssh_for_user() {
  local user="${1}"
  local home_dir
  home_dir=$(eval echo "~${user}")

  mkdir -p "${home_dir}/.ssh"
  touch "${home_dir}/.ssh/authorized_keys" "${home_dir}/.ssh/known_hosts" "${home_dir}/.ssh/config"
  if [ ! -f "${home_dir}/.ssh/id_rsa" ]; then
    ssh-keygen -t rsa -N "" -f "${home_dir}/.ssh/id_rsa"
  fi
  cat "${home_dir}/.ssh/id_rsa.pub" >> "${home_dir}/.ssh/authorized_keys"
  chmod 0600 "${home_dir}/.ssh/authorized_keys"
  cat << 'NOROAMING' >> "${home_dir}/.ssh/config"
Host *
  UseRoaming no
  StrictHostKeyChecking no
NOROAMING
  chown -R "${user}" "${home_dir}/.ssh"
}

ssh_keyscan_for_user() {
  local user="${1}"
  local home_dir
  home_dir=$(eval echo "~${user}")

  {
    ssh-keyscan localhost
    ssh-keyscan 0.0.0.0
    ssh-keyscan `hostname`
  } >> "${home_dir}/.ssh/known_hosts"
}

set_limits() {
  # Currently same as what's recommended in install guide
  if [ -d /etc/security/limits.d ]; then
    cat > /etc/security/limits.d/gpadmin-limits.conf <<-EOF
                gpadmin soft core unlimited
                gpadmin soft nproc 131072
                gpadmin soft nofile 65536
	EOF
  fi
  # Print now effective limits for gpadmin
  su gpadmin -c 'ulimit -a'
}

create_gpadmin_if_not_existing() {
  gpadmin_exists=`id gpadmin > /dev/null 2>&1;echo $?`
  if [ "0" -eq "$gpadmin_exists" ]; then
      echo "gpadmin user already exists, skipping creating again."
  else
      eval "$*"
  fi
}

setup_gpadmin_user() {
  groupadd supergroup
  case "$TEST_OS" in
    centos)
      user_add_cmd="/usr/sbin/useradd -G supergroup,tty gpadmin"
      create_gpadmin_if_not_existing ${user_add_cmd}
      ;;
    ubuntu)
      user_add_cmd="/usr/sbin/useradd -G supergroup,tty gpadmin -s /bin/bash"
      create_gpadmin_if_not_existing ${user_add_cmd}
      ;;
    sles)
      # create a default group gpadmin, and add user gpadmin to group gapdmin, supergroup, tty
      user_add_cmd="/usr/sbin/useradd -U -G supergroup,tty gpadmin"
      create_gpadmin_if_not_existing ${user_add_cmd}
      ;;
    *) echo "Unknown OS: $TEST_OS"; exit 1 ;;
  esac
  echo -e "password\npassword" | passwd gpadmin
  setup_ssh_for_user gpadmin
  set_limits
}

setup_sshd() {
  if [ ! "$TEST_OS" = 'ubuntu' ]; then
    test -e /etc/ssh/ssh_host_key || ssh-keygen -f /etc/ssh/ssh_host_key -N '' -t rsa1
  fi
  test -e /etc/ssh/ssh_host_rsa_key || ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa
  test -e /etc/ssh/ssh_host_dsa_key || ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa

  # For Centos 7, disable looking for host key types that older Centos versions don't support.
  sed -ri 's@^HostKey /etc/ssh/ssh_host_ecdsa_key$@#&@' /etc/ssh/sshd_config
  sed -ri 's@^HostKey /etc/ssh/ssh_host_ed25519_key$@#&@' /etc/ssh/sshd_config

  # See https://gist.github.com/gasi/5691565
  sed -ri 's/UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config
  # Disable password authentication so builds never hang given bad keys
  sed -ri 's/PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config

  setup_ssh_for_user root

  if [ "$TEST_OS" = 'ubuntu' ]; then
    mkdir -p /var/run/sshd
    chmod 0755 /var/run/sshd
  fi

  /usr/sbin/sshd

  ssh_keyscan_for_user root
  ssh_keyscan_for_user gpadmin
}

determine_os() {
  if [ -f /etc/redhat-release ] ; then
    echo "centos"
    return
  fi
  if grep -q ID=ubuntu /etc/os-release ; then
    echo "ubuntu"
    return
  fi
  if grep -q 'ID="sles"' /etc/os-release ; then
    echo "sles"
    return
  fi
  echo "Could not determine operating system type" >/dev/stderr
  exit 1
}

setup_golang_path() {
  echo "export PATH=$PATH:/usr/local/go/bin" >> ~gpadmin/.bashrc
  echo "export GOPATH=$HOME/go" >> ~gpadmin/.bashrc
}

# Set the "Set-User-ID" bit of ping, or else gpinitsystem will error by following message:
# [FATAL]:-Unknown host d6f9f630-65a3-4c98-4c03-401fbe5dd60b: ping: socket: Operation not permitted
# This is needed in centos7, sles12sp5, but not for ubuntu18.04
workaround_before_concourse_stops_stripping_suid_bits() {
  chmod u+s $(which ping)
}

_main() {
  TEST_OS=$(determine_os)
  setup_gpadmin_user
  setup_sshd
  setup_golang_path
  workaround_before_concourse_stops_stripping_suid_bits
}

[ "${BASH_SOURCE[0]}" = "$0" ] && _main "$@"
