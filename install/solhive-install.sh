#!/usr/bin/env bash
# Copyright (c) 2021-2026 community-scripts ORG
# Author: HatchetMan111
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://code.solhive.energy/solhive/solhive

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

# Required Notice: Copyright 2025-2026 Markus Nüsser — https://solhive.energy
# Licensed under PolyForm Perimeter License 1.0.1

msg_info "Setting up timezone"
# The container inherits the Proxmox host's timezone by default (set via
# build.func during container creation). We only step in with a fallback if
# that never happened (e.g. a bare template), so the install stays a true
# one-liner with no interactive prompt. An interactive whiptail list of all
# ~600 IANA zones doesn't fit usefully in a 16-line dialog and would hang a
# non-interactive/automated install anyway.
CURRENT_TZ="$(timedatectl show --property=Timezone --value 2>/dev/null)"
if [[ -z "$CURRENT_TZ" || "$CURRENT_TZ" == "Etc/UTC" || "$CURRENT_TZ" == "UTC" ]]; then
    timedatectl set-timezone "Europe/Berlin"
fi
msg_ok "Timezone set to: $(timedatectl show --property=Timezone --value)"

msg_info "Installing Docker"
if ! command -v docker &>/dev/null; then
    setup_docker
fi
msg_ok "Installed Docker"

msg_info "Setting up SolHive"
mkdir -p /opt/solhive/data /opt/solhive/certs
cd /opt/solhive
cat <<EOF > docker-compose.yml
services:
  solhive:
    image: code.solhive.energy/solhive/solhive:latest
    container_name: solhive
    restart: unless-stopped
    network_mode: host
    environment:
      PORT: 8080
      TZ: $(timedatectl show --property=Timezone --value)
    volumes:
      - ./data:/app/data
      - ./certs:/app/certs
EOF
$STD docker compose pull
$STD docker compose up -d
msg_ok "Setup SolHive"

motd_ssh
customize

msg_ok "Completed successfully!"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access SolHive at: ${BGN}https://$(hostname -I | awk '{print $1}'):8080${CL}"
echo -e "${INFO}${YW} Note: A self-signed certificate is generated on first access.${CL}"
echo -e "${INFO}${YW} Data directory: /opt/solhive/data${CL}"
