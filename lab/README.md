# lab/ — one-shot runnable demo

`soc-demo.sh` runs the **entire** attack → detect loop in a single command,
from your Kali VM, against a target (Metasploitable by default).

## Run it (from Kali)

```bash
git clone https://github.com/muttakin210/securehome-soc
sudo bash securehome-soc/lab/soc-demo.sh 192.168.1.3
```

Replace `192.168.1.3` with your target's IP if different
(find it with `nmap -sn 192.168.1.0/24`).

## What you'll see

1. Tool check (installs nmap/hydra/suricata/jq if missing)
2. Custom Suricata rules installed
3. Suricata IDS started on `eth0`
4. **Attacks:** host discovery → full service scan → SSH brute-force
5. **Detections:** the Suricata alerts that fired for your attacks

That last section — attacker IP → target with the signature that caught it — is
the money shot for your demo video and interviews.

## Useful follow-ups

```bash
# watch alerts live
sudo tail -f /var/log/suricata/eve.json | jq 'select(.event_type=="alert")'

# stop the IDS
sudo pkill -f 'suricata -i'
```

> Runs only inside your isolated VirtualBox lab against your own VMs.
