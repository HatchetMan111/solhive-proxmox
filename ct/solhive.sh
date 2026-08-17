#!/usr/bin/env bash
# Copyright (c) 2021-2026 community-scripts ORG
# Author: HatchetMan111
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://code.solhive.energy/solhive/solhive
#
# Standalone Proxmox VE LXC installer for SolHive.
#
# This deliberately does NOT source community-scripts' misc/build.func /
# build_container(). That function is hard-coded to fetch the app's install
# script from:
#   https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/install/<app>-install.sh
# which only exists for apps merged into the official monorepo. SolHive
# isn't, so that fetch 404s, `_install_script` ends up empty, and
# `lxc-attach ... bash -c ""` silently does nothing — the container gets
# created but SolHive never gets installed inside it (the container itself
# reports success, since running an empty command is not an error).
#
# Instead this script creates the LXC directly with `pct create` and pulls
# install/solhive-install.sh from THIS repo.

set -euo pipefail

APP="SolHive"
REPO_RAW_BASE="https://raw.githubusercontent.com/HatchetMan111/solhive-proxmox/main"

HOSTNAME="${HOSTNAME:-solhive}"
CORES="${CORES:-2}"
RAM="${RAM:-2048}"
DISK="${DISK:-4}"
BRIDGE="${BRIDGE:-vmbr0}"
STORAGE="${STORAGE:-local-lvm}"
TEMPLATE_STORAGE="${TEMPLATE_STORAGE:-local}"
UNPRIVILEGED="${UNPRIVILEGED:-1}"

info(){ printf '\033[1;36m[INFO]\033[0m %s\n' "$*"; }
ok(){ printf '\033[1;32m[ OK ]\033[0m %s\n' "$*"; }
err(){ printf '\033[1;31m[ERR ]\033[0m %s\n' "$*" >&2; }

command -v pveversion >/dev/null || { err "Proxmox VE not detected."; exit 1; }
command -v pct >/dev/null || { err "pct not found."; exit 1; }
command -v pveam >/dev/null || { err "pveam not found."; exit 1; }

SKIP_CREATE=0
if [[ -n "${CTID:-}" ]] && pct status "$CTID" &>/dev/null; then
    info "Container $CTID already exists — updating SolHive instead of creating a new one"
    SKIP_CREATE=1
    pct start "$CTID" &>/dev/null || true
else
    CTID="${CTID:-$(pvesh get /cluster/nextid)}"
fi

if [[ "$SKIP_CREATE" -eq 0 ]]; then
    info "Looking for a Debian 13 template"
    pveam update &>/dev/null || true
    TEMPLATE="$(pveam available --section system 2>/dev/null | awk '{print $2}' | grep '^debian-13-standard' | sort -V | tail -1)"
    if [[ -z "$TEMPLATE" ]]; then
        err "No debian-13-standard template found via 'pveam available'. Run 'pveam update' and retry."
        exit 1
    fi
    if ! pveam list "$TEMPLATE_STORAGE" 2>/dev/null | grep -q "$TEMPLATE"; then
        info "Downloading template $TEMPLATE"
        pveam download "$TEMPLATE_STORAGE" "$TEMPLATE"
    fi
    ok "Template ready: $TEMPLATE"

    info "Creating unprivileged SolHive LXC $CTID"
    pct create "$CTID" "$TEMPLATE_STORAGE:vztmpl/$TEMPLATE" \
        -hostname "$HOSTNAME" \
        -cores "$CORES" -memory "$RAM" \
        -rootfs "$STORAGE:$DISK" \
        -net0 "name=eth0,bridge=$BRIDGE,ip=dhcp" \
        -unprivileged "$UNPRIVILEGED" \
        -features nesting=1,keyctl=1 \
        -onboot 1 -start 1 \
        -ostype debian -tags "solar;energy;smart-home;ev"
    ok "LXC $CTID created"
fi

info "Waiting for network inside the container"
IP=""
for i in $(seq 1 30); do
    IP="$(pct exec "$CTID" -- hostname -I 2>/dev/null | awk '{print $1}')"
    [[ -n "$IP" ]] && break
    sleep 2
done
[[ -n "$IP" ]] || { err "Container did not get an IP address in time."; exit 1; }
ok "Network up: $IP"

info "Installing SolHive inside LXC $CTID"
pct exec "$CTID" -- bash -c \
    "apt-get update && apt-get install -y curl && curl -fsSL ${REPO_RAW_BASE}/install/solhive-install.sh | bash"
ok "SolHive installation complete"

echo "=============================================="
ok "SolHive setup has been successfully initialized!"
echo -e "\033[1;33mAccess SolHive at:\033[0m https://${IP}:8080"
echo "Note: a self-signed certificate is generated on first access."
echo "Data directory (inside CT $CTID): /opt/solhive/data"
