#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: HatchetMan111
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://code.solhive.energy/solhive/solhive

APP="SolHive"
var_tags="${var_tags:-solar;energy;smart-home;ev}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
# Unprivileged by default, matching the other Docker-based community-scripts
# apps (Docker runs fine unprivileged here via setup_docker's nesting/keyctl
# handling). Only switch to privileged (0) if you're passing through USB/
# serial hardware directly for a wallbox driver — see README.
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
    header_info
    check_container_storage
    check_container_resources

    msg_info "Updating base system"
    $STD apt update
    $STD apt upgrade -y
    msg_ok "Base system updated"

    msg_info "Updating SolHive container"
    cd /opt/solhive
    $STD docker compose pull
    $STD docker compose up -d --force-recreate
    msg_ok "SolHive updated"

    msg_ok "Updated successfully!"
    exit
}

start
build_container
description

msg_ok "Completed successfully!"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access SolHive at: ${BGN}https://${IP}:8080${CL}"
