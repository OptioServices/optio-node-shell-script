#!/usr/bin/env sh
# installs the Optio Node CLI and default node instance
set -e

# DOWNLOAD
optio="$HOME/optio/library/node/optio"
download_url="https://static.optionetwork.io/node/linux/releases/1.8.2/optio"
curl $download_url -o $optio --create-dirs
chmod +x $optio

# ADD ALIAS
alias='alias optio="~/optio/library/node/optio"'
if ! grep -Fxq "$alias" ~/.bashrc; then
    echo $alias >> ~/.bashrc
fi
# source ~/.bashrc

$optio version

# INITIALIZE
set +e
$optio node init -e mainnet
exit_code=$?
set -e
if [ "$exit_code" != 0 ] && [ $exit_code != 99 ]; then
  exit 1
fi

# ACTIVATE
$optio node activate

# INSTALL SERVICE
$optio node service install --wait
echo "Installing service..."
sleep 3
$optio node service start
