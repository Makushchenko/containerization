# Display help for the unshare command
unshare -h

# Launch a shell with isolated UTS, IPC, mount, net, PID, user, and cgroup namespaces
sudo unshare -i -m -n -p -u -U --mount-proc -f sh
    # Show user and group IDs inside the namespace
    id
    # List contents of the root directory
    ls -l /
    # Display network interfaces
    ip a
###########
# Exit from the isolated shell
exit

# Create a directory for the root filesystem
mkdir rootfs
# List current namespaces
lsns
###########
# Run a BusyBox container
docker run busybox
# List local images
docker images
# List all containers, including stopped ones
docker ps -a
# Export the container's filesystem into the rootfs directory
docker export <container_id> | tar xf - -C rootfs
###########
# Enter the exported rootfs in new namespaces
unshare -i -m -n -p -u -U --mount-proc -R rootfs -f sh
    # List running processes
    ps xa
    # Display network interfaces
    ip a
    # List contents of the root directory
    ls -l /
    # Exit from the isolated shell
    exit
###########
# Display help for runc
runc
# Generate a default OCI spec (config.json)
runc spec
# List generated files
ll
# Run the container named 'demo'
sudo runc run demo
    # Display network interfaces inside the container
    ip a
    # List processes inside the container
    ps xa
# Edit 'args' in config.json to run a simple HTTP server
  "args": [
    "sh", "-c",
    "while true; do { echo -e 'HTTP/1.1 200 OK\n\n Version: 1.0.0'; } | nc -vlp 8080; done"
  ]
# Set "terminal": false in config.json
  "terminal": false
# Re-run the container with the updated spec
sudo runc run demo
# In a new terminal, list running runc containers
sudo runc ps demo
# Force-stop the container
sudo runc kill demo KILL
###########
# Add network namespace path to config.json
#   "path": "/var/run/netns/runc"
# Create a new network namespace named 'runc'
sudo ip netns add runc
# List network namespaces
sudo ip netns ls
# Run the container with the network namespace
sudo runc run demo
# In another terminal, stop the container
sudo runc kill demo KILL
# Switch to root shell to install required tools
sudo bash
# Update package lists
sudo apt-get update
# Install bridge-utils
sudo apt-get install bridge-utils
# Create a Linux bridge named 'runc0'
brctl addbr runc0
# Bring up the bridge interface
ip link set runc0 up
# List interfaces
ip a
# Assign IP address to the bridge
ip addr add 192.168.0.1/24 dev runc0
# List IP addresses
ip a
# Create a veth pair between host and guest
ip link add name veth-host type veth peer name veth-guest
# List interfaces
ip a
# Bring up the host end of the veth pair
ip link set veth-host up
# Add the host veth to the bridge
brctl addif runc0 veth-host
# List interfaces
ip a
# Move the guest veth into the 'runc' namespace
ip link set veth-guest netns runc
# Inside the 'runc' namespace, rename and configure the guest interface
ip netns exec runc ip link set veth-guest name eth1
ip netns exec runc ip addr add 192.168.0.2/24 dev eth1
ip netns exec runc ip link set eth1 up
ip netns exec runc ip route add default via 192.168.0.1
# Exit the root shell
exit
###########
# Run the container 'demo' with the network setup
sudo runc run demo
# In another terminal, test HTTP connectivity
curl 192.168.0.2:8080
###########
# Download and install 'dive' to analyze image layers
wget https://github.com/wagoodman/dive/releases/download/v0.10.0/dive_0.10.0_linux_amd64.deb
sudo apt install ./dive_0.10.0_linux_amd64.deb
# Remove the downloaded package file
echo "rm dive_0.10.0_linux_amd64.deb"
# Run dive to inspect the image
dive <image_id>