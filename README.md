# Republic Node Setup (Testnet)

Production-ready Republic node setup with systemd, state sync, firewall configuration and operational checks.

Maintained by **Xibz** — infrastructure operator focused on monitoring, reliability and security-first deployments.

---

## System Requirements

| Component | Minimum | Recommended |
|-----------|----------|-------------|
| CPU | 2 cores | 4+ cores |
| RAM | 4 GB | 8–16 GB |
| Disk | 100 GB SSD | 200+ GB NVMe |
| OS | Ubuntu 22.04+ | Ubuntu 22.04 / 24.04 |

---

# 0) Variables

Update according to official Republic documentation.

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

# 1) Install Dependencies

```bash
sudo apt update -y
sudo apt install -y curl jq git build-essential ufw
```

---

# 2) Install Binary

Follow official Republic repository instructions.

Example:

```bash
# git clone <REPO>
# cd <REPO>
# make install
```

Verify:

```bash
which $BINARY
$BINARY version
```

---

# 3) Initialize Node

```bash
$BINARY init "Xibz" --chain-id $CHAIN_ID
```

---

# 4) Download Genesis

```bash
curl -L $GENESIS_URL -o $HOME_DIR/config/genesis.json
```

---

# 5) Configure Seeds / Peers

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

# 6) Optional: State Sync (Fast Sync)

⚠ Always verify RPC servers are trustworthy.

Example template:

```bash
SNAP_RPC="https://rpc.example.com:443"

LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height)
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000))
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

sed -i.bak -e "s|^enable *=.*|enable = true|" \
-e "s|^rpc_servers *=.*|rpc_servers = \"$SNAP_RPC,$SNAP_RPC\"|" \
-e "s|^trust_height *=.*|trust_height = $BLOCK_HEIGHT|" \
-e "s|^trust_hash *=.*|trust_hash = \"$TRUST_HASH\"|" \
$HOME_DIR/config/config.toml
```

Restart node after enabling state sync.

---

# 7) Create Dedicated User

```bash
sudo adduser --disabled-password --gecos "" validator
sudo usermod -aG sudo validator
```

---

# 8) systemd Service

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

# 9) Firewall (UFW Recommended)

Enable firewall:

```bash
sudo ufw allow ssh
sudo ufw allow 26656/tcp
sudo ufw enable
```

Optional (if RPC needed):

```bash
sudo ufw allow 26657/tcp
```

⚠ Do NOT expose RPC publicly unless required.

---

# 10) Sync Check

```bash
curl -s localhost:26657/status | jq -r '.result.sync_info'
```

Check catching up:

```bash
curl -s localhost:26657/status | jq -r '.result.sync_info.catching_up'
```

---

# 11) Operational Notes

- Keep RPC private
- Never store mnemonics on VPS
- Monitor disk growth
- Watch missed blocks
- Implement monitoring (recommended)

---

# Monitoring

For production monitoring:

- validator-monitoring-suite
- cosmos-validator-playbook

---

# Validator Operations

⚠ Never store mnemonics or private keys on a public VPS.

## Create Wallet

```bash
$BINARY keys add wallet
```

Recover existing wallet:

```bash
$BINARY keys add wallet --recover
```

Show address:

```bash
$BINARY keys show wallet -a
```

---

## Create Validator

After funding your wallet:

```bash
$BINARY tx staking create-validator \
  --amount 1000000utoken \
  --pubkey $($BINARY tendermint show-validator) \
  --moniker "Xibz" \
  --chain-id $CHAIN_ID \
  --commission-rate "0.05" \
  --commission-max-rate "0.20" \
  --commission-max-change-rate "0.01" \
  --min-self-delegation "1" \
  --gas auto \
  --gas-adjustment 1.3 \
  --gas-prices 0.025utoken \
  --from wallet \
  -y
```

> Replace `utoken` with the correct staking denom.

---

## Check Validator Status

```bash
$BINARY query staking validator $($BINARY keys show wallet --bech val -a)
```

Check jailed status:

```bash
$BINARY query staking validator <your_valoper_address> | jq '.jailed'
```

---

## Unjail Validator

If jailed due to missed blocks:

```bash
$BINARY tx slashing unjail \
  --from wallet \
  --chain-id $CHAIN_ID \
  --gas auto \
  --gas-adjustment 1.3 \
  --gas-prices 0.025utoken \
  -y
```

---

## Check Missed Blocks

```bash
$BINARY query slashing signing-info \
  $($BINARY tendermint show-validator) \
  --chain-id $CHAIN_ID
```

---

## Operational Best Practices

- Monitor missed blocks continuously
- Alert on jailed status
- Keep commission transparent
- Rotate keys securely if required
- Maintain proper backups (offline only)



# Disclaimer

Use at your own risk. Always verify chain parameters from official sources.