#####
# Install cgroup-tools v2
sudo chmod o+w /etc/apt/sources.list
echo "deb http://cz.archive.ubuntu.com/ubuntu jammy main universe" >>/etc/apt/sources.list
sudo add-apt-repository universe
sudo apt update
sudo apt install cgroup-tools stress
#####
ll -h /sys/fs/cgroup
# Create a unified/cg1 cgroup
sudo mkdir /sys/fs/cgroup/unified
sudo mount -t cgroup2 none /sys/fs/cgroup/unified
sudo cgcreate -g cpuset,memory:unified/cg1
#####
# Check the cgroup
sudo cgget -g cpuset unified/cg1
sudo cgget -g memory unified/cg1

#####
# Set the CPU and memory limits
sudo cgset -r memory.max=100M unified/cg1
sudo cgexec -g cpu:unified/cg1 htop
sudo cgset -r memory.max=100K unified/cg1
sudo cgset -r memory.max=100M unified/cg1
sudo cgexec -g cpu:unified/cg1 htop

#####
# Run the stress tool
sudo cgexec -g cpu:unified/cg1 stress --cpu 2 --timeout 60
htop
sudo cgset -r cpuset.cpus=0 unified/cg1 # set cpu
echo 1 >/sys/fs/cgroup/cg1/cgroup.freeze # freeze the cgroup

#####
# Create a webserver cgroup
sudo cgcreate -g cpu:webserver
# Default 100% cpu usage: quota=100ms, period=100ms
sudo cgset -r cpu.max=100000 webserver
# Adds this shell process to the webserver cgroup (run from the same terminal as 'while...' command)
echo $$ | sudo tee /sys/fs/cgroup/webserver/cgroup.procs
# Repeatedly requests 1.1.1.1 every 0.3s, printing HTTP status
while true; do curl -sLo /dev/null -w "%{http_code} " 1.1.1.1; sleep 0.3; done