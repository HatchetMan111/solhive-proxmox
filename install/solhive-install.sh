#!/usr/bin/env bash
# Copyright (c) 2021-2026 community-scripts ORG
# Author: HatchetMan111
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://code.solhive.energy/solhive/solhive
#
# Runs INSIDE the LXC container (invoked by ct/solhive.sh via pct exec).
# community-scripts' misc/install.func is generic and self-bootstraps its
# own dependencies (core.func for color/msg_info/msg_ok, error_handler.func
# for catch_errors) when sourced, so we pull it in directly here instead of
# depending on a FUNCTIONS_FILE_PATH env var from build_container — this
# project intentionally doesn't use build_container (see ct/solhive.sh).
#
# Deliberately NOT using `set -u` here: install.func's own catch_errors()
# only does `set -Ee -o pipefail` and adds `-u` itself if STRICT_UNSET=1.
# Its library functions (e.g. update_os's APT-cacher check) reference
# $CACHER, which build_container normally exports from the host — we skip
# build_container, so we export a safe default ourselves instead.
set -eo pipefail
export CACHER=no
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/install.func)
color
verb_ip6
setting_up_container
network_check
update_os

# Required Notice: Copyright 2025-2026 Markus Nüsser — https://solhive.energy
# Licensed under PolyForm Perimeter License 1.0.1

msg_info "Setting up timezone"
CURRENT_TZ="$(timedatectl show --property=Timezone --value 2>/dev/null)"
if [[ -z "$CURRENT_TZ" || "$CURRENT_TZ" == "Etc/UTC" || "$CURRENT_TZ" == "UTC" ]]; then
    timedatectl set-timezone "Europe/Berlin"
fi
msg_ok "Timezone set to: $(timedatectl show --property=Timezone --value)"

msg_info "Installing Docker"
if ! command -v docker &>/dev/null; then
    $STD bash -c "curl -fsSL https://get.docker.com | sh"
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
