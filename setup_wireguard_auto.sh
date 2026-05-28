#!/bin/bash
set -e

sudo apt update
sudo apt install -y wireguard wireguard-tools

sudo mkdir -p /etc/wireguard
umask 077

# Generate server keys
sudo sh -c 'wg genkey > /etc/wireguard/server_privatekey'
sudo sh -c 'wg pubkey < /etc/wireguard/server_privatekey > /etc/wireguard/server_publickey'

# Generate client keys
wg genkey > client_privatekey
cat client_privatekey | wg pubkey > client_publickey

SERVER_PRIV=$(sudo cat /etc/wireguard/server_privatekey)
SERVER_PUB=$(sudo cat /etc/wireguard/server_publickey)
CLIENT_PUB=$(cat client_publickey)
CLIENT_PRIV=$(cat client_privatekey)

PUBLIC_IP=$(curl -fsS ifconfig.me)
WAN_IFACE=$(ip route | awk '/default/ {print $5; exit}')

if [ -z "$PUBLIC_IP" ]; then
    echo "Could not detect public IP."
    exit 1
fi

if [ -z "$WAN_IFACE" ]; then
    echo "Could not detect WAN interface."
    exit 1
fi

echo "Public IP: $PUBLIC_IP"
echo "WAN interface: $WAN_IFACE"

# Write server config
sudo tee /etc/wireguard/wg0.conf >/dev/null <<EOF
[Interface]
PrivateKey = $SERVER_PRIV
Address = 10.0.0.1/24
ListenPort = 51820

PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o $WAN_IFACE -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o $WAN_IFACE -j MASQUERADE

[Peer]
PublicKey = $CLIENT_PUB
AllowedIPs = 10.0.0.2/32
EOF

# Enable IP forwarding
sudo sh -c "echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/99-wireguard.conf"
sudo sysctl --system

# Start server
sudo wg-quick up /etc/wireguard/wg0.conf || true
sudo systemctl enable wg-quick@wg0 || true

# Write client config
cat > wg0.conf <<EOF
[Interface]
PrivateKey = $CLIENT_PRIV
Address = 10.0.0.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = $SERVER_PUB
Endpoint = $PUBLIC_IP:51820
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
EOF
chmod 600 wg0.conf /etc/wireguard/wg0.conf || true

# Start client locally
sudo wg-quick up ./wg0.conf || true

printf '\nWireGuard setup complete.\n'
printf 'Server config: /etc/wireguard/wg0.conf\n'
printf 'Client config: %s/wg0.conf\n' "$(pwd)"
printf 'Check status with: sudo wg show\n'
printf 'Check your IP with: curl -fsS ifconfig.me\n'
