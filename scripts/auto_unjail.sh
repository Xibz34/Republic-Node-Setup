Auto-Unjail (Safe & Rate-Limited)

⚠ This script does NOT solve slashing risks.  
Always fix the root cause (peering, CPU, disk, network) before relying on automation.

### Script: `scripts/auto_unjail.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

# ===== Required environment variables =====
: "${BINARY:?missing BINARY}"
: "${CHAIN_ID:?missing CHAIN_ID}"
: "${WALLET:?missing WALLET}"
: "${GAS_PRICES:?missing GAS_PRICES}"

# Safety switch (must be explicitly enabled)
ENABLE_AUTO_UNJAIL="${ENABLE_AUTO_UNJAIL:-false}"
if [[ "$ENABLE_AUTO_UNJAIL" != "true" ]]; then
  echo "AUTO_UNJAIL disabled (set ENABLE_AUTO_UNJAIL=true)"
  exit 0
fi

NODE_ARG=()
if [[ -n "${NODE:-}" ]]; then
  NODE_ARG=(--node "$NODE")
fi

VALOPER="$($BINARY keys show "$WALLET" --bech val -a)"
if [[ -z "$VALOPER" ]]; then
  echo "Could not resolve valoper address for wallet=$WALLET"
  exit 1
fi

JAILED="$($BINARY query staking validator "$VALOPER" "${NODE_ARG[@]}" -o json 2>/dev/null | jq -r '.jailed // empty' || true)"
if [[ "$JAILED" != "true" ]]; then
  echo "Validator is not jailed (jailed=$JAILED)"
  exit 0
fi

echo "Validator is JAILED → attempting unjail..."

$BINARY tx slashing unjail \
  --from "$WALLET" \
  --chain-id "$CHAIN_ID" \
  --gas auto \
  --gas-adjustment 1.3 \
  --gas-prices "$GAS_PRICES" \
  "${NODE_ARG[@]}" \
  -y

echo "Unjail transaction broadcasted. Verify status shortly."
```

Make it executable:

```bash
chmod +x scripts/auto_unjail.sh
```

### Cron Example (Every 10 Minutes)

```bash
crontab -e
```

Add:

```cron
*/10 * * * * /bin/bash -lc 'cd $HOME/Republic-Node-Setup && BINARY=republicd CHAIN_ID=raitestnet_77701-1 WALLET=wallet GAS_PRICES=0.025utoken ENABLE_AUTO_UNJAIL=true ./scripts/auto_unjail.sh >> $HOME/auto_unjail.log 2>&1'
```