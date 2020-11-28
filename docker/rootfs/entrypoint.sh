#!/bin/sh

file_permissions() {
  local file=$1 user=$3 perms=$4
  current="$(stat -c "%U %G %04a" "$file")"
  if [ "$current" != "$user $user $perms" ];then
    chown "$user:$user" "$file"
    chmod $perms "$file"
  fi
}
file_permissions /bin/ssh-honeypot true root 0775 0775
file_permissions /bin/ssh-honeypot-wrapper true root 0775 0775
file_permissions /etc/services.d/sshd/run true root 0775 0775
file_permissions /home/honeycomb true honeycomb 2770 2770

set -e

RSA_KEY="/home/honeycomb/rsa/sshd-key.rsa"

if [ ! -f "${RSA_KEY}" ]; then
  ssh-keygen -t rsa -f "${RSA_KEY}" -q -N ""
  chown honeycomb:honeycomb "${RSA_KEY}"
fi

# Initial arguments that ssh-honeypot will be started with
# Intentionally added one by one for more clarity
P_INIT_ARGS="-r /home/honeycomb/rsa/sshd-key.rsa"
P_INIT_ARGS="${P_INIT_ARGS} -p 2022"
P_INIT_ARGS="${P_INIT_ARGS} -j /home/honeycomb/log/honeypot.json"

# Show banner by either string or index
if [ -n "${SSH_BANNER}" ]; then
  P_INIT_ARGS="${P_INIT_ARGS} -b '${SSH_BANNER}'"
elif [ -n "${SSH_BANNER_INDEX}" ]; then
  P_INIT_ARGS="${P_INIT_ARGS} -i '${SSH_BANNER_INDEX}'"
fi

# Should we send log to JSON log server
if [ -n "${SSH_JSON_LOG_SERVER}" ]; then
  P_INIT_ARGS="${P_INIT_ARGS} -J '${SSH_JSON_LOG_SERVER}'"

  # JSON server port
  if [ -n "${SSH_JSON_LOG_SERVER_PORT}" ]; then
    P_INIT_ARGS="${P_INIT_ARGS} -P '${SSH_JSON_LOG_SERVER_PORT}'"
  fi

fi

exec /bin/ssh-honeypot ${P_INIT_ARGS} -u honeycomb
