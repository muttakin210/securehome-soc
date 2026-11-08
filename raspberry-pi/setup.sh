#!/usr/bin/env bash
# =====================================================================
# SecureHome SOC — Raspberry Pi defence setup
# Installs & configures Suricata IDS + nftables firewall on Raspberry Pi OS.
# Run once:  sudo bash setup.sh
# Tested on: Raspberry Pi OS Lite (64-bit, Debian bookworm)
# =====================================================================
set -euo pipefail

# ---- CONFIG: edit this to match your Pi's monitoring interface ----
MON_IFACE="${MON_IFACE:-eth0}"      # the NIC that sees home traffic (SPAN or inline)
HOME_NET="${HOME_NET:-[10.10.0.0/16,192.168.0.0/16]}"  # your internal ranges
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# -------------------------------------------------------------------

log() { printf '\n\033[1;32m[+] %s\033[0m\n' "$*"; }
err() { printf '\n\033[1;31m[!] %s\033[0m\n' "$*" >&2; }

if [[ $EUID -ne 0 ]]; then err "Run as root: sudo bash setup.sh"; exit 1; fi

log "Updating package lists"
apt-get update -y

log "Installing Suricata, nftables, jq, tools"
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    suricata suricata-update nftables jq tcpdump

log "Configuring Suricata (interface=${MON_IFACE}, HOME_NET=${HOME_NET})"
# Point HOME_NET and the capture interface at your network.
sed -i "s|HOME_NET:.*|HOME_NET: \"${HOME_NET}\"|" /etc/suricata/suricata.yaml
# af-packet interface (first occurrence under af-packet:)
sed -i "0,/interface:.*/s//interface: ${MON_IFACE}/" /etc/suricata/suricata.yaml

log "Installing custom detection rules"
install -d /etc/suricata/rules
cp "${REPO_DIR}/suricata/custom.rules" /etc/suricata/rules/custom.rules
# Make sure custom.rules is loaded + ET open ruleset is updated
grep -q "custom.rules" /etc/suricata/suricata.yaml || \
  sed -i "/rule-files:/a\  - custom.rules" /etc/suricata/suricata.yaml

log "Updating Emerging Threats open ruleset"
suricata-update || err "suricata-update failed (continuing with custom rules)"

log "Validating Suricata config"
suricata -T -c /etc/suricata/suricata.yaml -v || { err "Suricata config test failed"; exit 1; }

log "Applying nftables firewall"
cp "${REPO_DIR}/firewall/nftables.conf" /etc/nftables.conf
systemctl enable nftables
nft -f /etc/nftables.conf
nft list ruleset | head -n 40

log "Enabling + starting Suricata"
systemctl enable suricata
systemctl restart suricata
sleep 3
systemctl --no-pager status suricata | head -n 12

log "DONE. Live alerts:  tail -f /var/log/suricata/eve.json | jq 'select(.event_type==\"alert\")'"
echo "Next: cd ${REPO_DIR}/../dashboards && docker compose up -d   (then open http://<pi-ip>:3000)"
