unshare -h
sudo unshare -i -m -n -p -u -U --mount-proc -f sh
    id
    ls -l /
    ip a
###########
exit
mkdir rootfs
lsns
###########
docker run busybox
docker images
docker ps -a
docker export <container_id> | tar xf - -C rootfs
###########
unshare -i -m -n -p -u -U --mount-proc -R rootfs -f sh
    ps xa
    ip a
    ls -l /
    exit
###########
runc
# Create config.json
runc spec
ll
sudo runc run demo
    ip a
    ps xa
# Change args into config.json
"args": [
    "sh", "-c", "while true; do { echo -e 'HTTP/1.1 200 OK\n\n Version: 1.0.0'; } | nc -vlp 8080; done"
]
# Change terminal into config.json
"terminal": false
# Run with new config
sudo runc run demo
# Check in new terminal
sudo runc ps demo
sudo runc kill demo KILL
###########
# Add network namespace into config.json
"path": "/var/run/netns/runc" #runc - random name for the network
sudo ip netns add runc
sudo ip netns ls
sudo runc run demo
# From other terminal
sudo runc kill demo KILL
# Installation needed tools
sudo bash
sudo apt-get update
sudo apt-get install bridge-utils
#
brctl addbr runc0
ip link set runc0 up
ip a
ip addr add 192.168.0.1/24 dev runc0
ip a
ip link add name veth-host type veth peer name veth-guest
ip a
ip link set veth-host up
ip a
brctl addif runc0 veth-host
ip a
# Add runc namespace that we declared into config.json
ip link set veth-guest netns runc
# Perform configuration into namespace
ip netns exec runc ip link set veth-guest name eth1
ip netns exec runc ip addr add 192.168.0.2/24 dev eth1
ip netns exec runc ip link set eth1 up
ip netns exec runc ip route add default via 192.168.0.1
exit
###########
sudo runc run demo
# From other terminal
curl 192.168.0.2:8080
###########
# Exploring a Docker image
wget https://github.com/wagoodman/dive/releases/download/v0.10.0/dive_0.10.0_linux_amd64.deb
sudo apt install ./dive_0.10.0_linux_amd64.deb
rm dive_0.10.0_linux_amd64.deb
dive <image_id>