# Republic Node Setup (Testnet)

Production-ready setup guide for running a Republic node with `systemd`, safe defaults, and post-install checks.

Maintained by **Xibz** — independent infrastructure operator focused on monitoring, reliability, and operational maturity.

---

## What you get

- Clean install steps (deps → binary → init → genesis)
- systemd service template (non-root)
- Sync / health verification commands
- Practical operational notes

> Always verify chain parameters (chain-id, seeds, genesis) from official Republic documentation.

---

## System Requirements

| Component | Minimum | Recommended |
|-----------|----------|-------------|
| CPU | 2 cores | 4+ cores |
| RAM | 4 GB | 8–16 GB |
| Disk | 100 GB SSD | 200+ GB NVMe |
| OS | Ubuntu 22.04+ | Ubuntu 22.04 / 24.04 |

---

## 0) Set Variables

Update according to official documentation:

```bash
export CHAIN_ID="raitestnet_77701-1"
export BINARY="republicd"
export HOME_DIR="$HOME/.republicd"

# Replace with official values
export GENESIS_URL=""
export SEEDS=""
export PEERS=""
```

---

## 1) Install Dependencies

```bash
sudo apt update -y
sudo apt install -y curl jq git build-essential
```

---

## 2) Install Binary

Follow the official Republic repository instructions.

Example pattern:

```bash
# git clone <REPUBLIC_REPO>
# cd <REPUBLIC_REPO>
# make install
```

Verify:

```bash
which $BINARY
$BINARY version
```

---

## 3) Initialize Node

```bash
$BINARY init "Xibz" --chain-id $CHAIN_ID
```

---

## 4) Download Genesis

```bash
curl -L $GENESIS_URL -o $HOME_DIR/config/genesis.json
```

---

## 5) Configure Seeds / Peers

Edit:

```bash
nano $HOME_DIR/config/config.toml
```

Set:

```
seeds = "$SEEDS"
persistent_peers = "$PEERS"
```

---

## 6) Create Dedicated User (Recommended)

```bash
sudo adduser --disabled-password --gecos "" validator
sudo usermod -aG sudo validator
```

(Optional: move node home directory under /home/validator)

---

## 7) Create systemd Service

```bash
sudo nano /etc/systemd/system/republicd.service
```

Paste:

```ini
[Unit]
Description=Republic Node
After=network-online.target
Wants=network-online.target

[Service]
User=validator
ExecStart=/usr/local/bin/republicd start --home /home/validator/.republicd
Restart=on-failure
RestartSec=5
LimitNOFILE=65535

NoNewPrivileges=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```

Enable & start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable republicd
sudo systemctl restart republicd
sudo journalctl -u republicd -f --no-hostname
```

---

## 8) Sync Check

Check sync status:

```bash
curl -s localhost:26657/status | jq -r '.result.sync_info'
```

Check catching up:

```bash
curl -s localhost:26657/status | jq -r '.result.sync_info.catching_up'
```

---

## 9) Security Notes

- Never commit private keys or mnemonics
- Keep RPC private unless required
- Use SSH keys, disable password login
- Consider sentry architecture for public validators

---

## Monitoring

For production monitoring:

- validator-monitoring-suite
- cosmos-validator-playbook

---

## Disclaimer

Use at your own risk. Always verify parameters from official sources.