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
echo "Installing service..."
$optio node service install

echo "Waiting for service to be registered..."
until $optio node service status &>/dev/null
do
    echo "Waiting for service..."
    sleep 1
done

echo "Starting service..."
$optio node service start
