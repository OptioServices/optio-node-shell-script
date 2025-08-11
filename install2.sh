#!/usr/bin/env sh
# Installs the Optio Node CLI and default node instance (system-safe)
set -eu

# --- sudo helper ---
if [ "$(id -u)" -eq 0 ]; then SUDO=""; else SUDO="sudo"; fi

# --- DOWNLOAD to /usr/local/bin ---
download_url="https://static.optionetwork.io/node/linux/releases/1.8.2/optio"
tmp="$(mktemp)"
curl -fsSL "$download_url" -o "$tmp"
$SUDO install -Dm755 "$tmp" /usr/local/bin/optio
rm -f "$tmp"
# (SELinux contexts, if applicable)
($SUDO restorecon -v /usr/local/bin/optio 2>/dev/null || true)

# sanity check
/usr/local/bin/optio version

# --- INITIALIZE (allow exit 99) ---
set +e
/usr/local/bin/optio node init -e mainnet
exit_code=$?
set -e
if [ "$exit_code" != "0" ] && [ "$exit_code" != "99" ]; then
  echo "Init failed with exit code $exit_code" >&2
  exit 1
fi

# --- ACTIVATE ---
/usr/local/bin/optio node activate

# --- INSTALL SERVICE (system unit) ---
if ! $SUDO /usr/local/bin/optio node service install --wait; then
  echo "Warning: service install reported a non-zero exit code; continuing..." >&2
fi

# Force ExecStart to system-safe path (avoids /root path issues)
$SUDO systemctl edit optio.node.service <<'EOF'
[Service]
ExecStart=
ExecStart=/usr/local/bin/optio node start
EOF

# Reload, enable, start, and show status
$SUDO systemctl daemon-reload
$SUDO systemctl enable optio.node.service --now
$SUDO systemctl status optio.node.service --no-pager -l || true
