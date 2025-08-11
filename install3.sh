#!/usr/bin/env sh
# Installs the Optio Node CLI and default node instance (system-safe, root-only)
set -eu

# --- require root ---
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root." >&2
  exit 1
fi

# --- DOWNLOAD to /usr/local/bin ---
download_url="https://static.optionetwork.io/node/linux/releases/1.8.2/optio"
tmp="$(mktemp)"
curl -fsSL "$download_url" -o "$tmp"
install -Dm755 "$tmp" /usr/local/bin/optio
rm -f "$tmp"
# (SELinux contexts, if applicable)
restorecon -v /usr/local/bin/optio 2>/dev/null || true

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
/usr/local/bin/optio node service install

# Wait until systemd knows about the service
echo "Waiting for service registration..."
SERVICE_NAME="optio.node.service"  # change if actual name differs
until systemctl list-unit-files | grep -q "^${SERVICE_NAME}"; do
  sleep 1
done
echo "Service registered."

# Force ExecStart to system-safe path (avoids /root path issues)
mkdir -p "/etc/systemd/system/$SERVICE_NAME.d"
tee "/etc/systemd/system/$SERVICE_NAME.d/override.conf" >/dev/null <<'EOF'
[Service]
ExecStart=
ExecStart=/usr/local/bin/optio node start
EOF

# --- Reload, enable, start, and show status ---
systemctl daemon-reload
systemctl enable "$SERVICE_NAME" --now
systemctl status "$SERVICE_NAME" --no-pager -l || true
