#!/bin/bash
set -e

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

echo "[*] Updating apt..."
apt-get update -y

echo "[*] Installing prerequisites (ca-certificates, curl, gnupg, software-properties-common)..."
apt-get install -y ca-certificates curl gnupg software-properties-common apt-transport-https lsb-release

echo "[*] Setting up Docker APT keyring..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo "[*] Adding Docker repo..."
ARCH=$(dpkg --print-architecture)
CODENAME=$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${CODENAME} stable" \
    > /etc/apt/sources.list.d/docker.list

echo "[*] apt update (with Docker repo)..."
apt-get update -y

echo "[*] Installing Docker Engine + plugins..."
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "[*] Removing any user-installed buildx override if arch mismatch..."
if [ -f "/home/zerrino/.docker/cli-plugins/docker-buildx" ]; then
    rm -f /home/zerrino/.docker/cli-plugins/docker-buildx || true
fi

echo "[*] Enabling and starting Docker service..."
systemctl enable --now docker

echo "[*] Adding 'zerrino' to docker group so it can run docker without sudo..."
if id "zerrino" &>/dev/null; then
    usermod -aG docker zerrino
fi

echo "[*] Installing GNS3 repo..."
add-apt-repository -y ppa:gns3/ppa
apt-get update -y

echo "[*] Installing GNS3 GUI + server..."
apt-get install -y gns3-gui gns3-server

echo "[*] Done."
echo "!! IMPORTANT: You must log out / log back in (or 'su - zerrino') before 'docker ps' works without sudo."

