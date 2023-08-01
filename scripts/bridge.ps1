$errorActionPreference = "Stop"
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments', "Internal PS variable"
)]
$PSNativeCommandUseErrorActionPreference = $true

# only run this script if the br0 interface does not exist
$_br0Interface = $(ip link show br0)
if ($_br0Interface) {
    Write-Host "✅ Bridge already created"
    exit 0
}

# maybe we already created it before?
nmcli connection show | /usr/bin/grep br0
if ($? -ne 0) {
    Write-Host "⚠️ previous bridge found, removing it"
    sudo nmcli connection delete br0
}

# setup
sudo chmod +s /usr/lib/qemu/qemu-bridge-helper
sudo mkdir -p /etc/qemu
sudo bash -c "echo `"allow br0`" >> /etc/qemu/bridge.conf"
sudo sysctl -w "net.ipv4.ip_forward=1"
sudo sysctl -w "net.bridge.bridge-nf-call-iptables=0"
sudo iptables -P FORWARD ACCEPT

# get the main interface
$_mainInterface = $(ip route | grep default | awk '{print $5}')
Write-Host "Main interface: $_mainInterface"

# get the ip with the subnet mask
$_mainIp = $(ip addr show $_mainInterface | grep -oE 'inet [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+' | awk '{print $2}')
Write-Host "Main IP: $_mainIp"

# store the route with the mask
$_mainRoute = $(ip route | grep default | awk '{print $3}')
Write-Host "Main route: $_mainRoute"

# create the bridge
sudo ip link add name br0 type bridge nf_call_iptables 0
sudo ip link set br0 up
sudo ip address add $_mainIp dev br0
sudo ip route append default via $_mainRoute dev br0

# flush the main interface
sudo ip link set $_mainInterface master br0
sudo ip address del $_mainIp dev $_mainInterface

# accept
sudo iptables -I FORWARD -m physdev --physdev-is-bridged -j ACCEPT

Write-Host "✅ Bridge created"

Write-Host "Setting and restarting the network service..."
sleep 2
sudo nmcli connection modify br0 ipv4.dns "8.8.8.8 8.8.4.4"
sleep 4
sudo systemctl restart NetworkManager

Write-Host "✅ Network service restarted"
