# CONTAINERIZATION

---

# 1. cgroups

## Overview

**Control Groups (cgroups)** are a Linux kernel feature that allow you to allocate, track, and limit system resources (CPU, memory, I/O, etc.) for a group of processes. They provide fine‑grained control over how processes consume resources, improving stability and ensuring isolation.

## Key Concepts

* **Controllers (subsystems):** Modules that manage specific resources, e.g., `cpu`, `memory`, `blkio`, `pids`.
* **Hierarchy:** A tree of cgroups under which resource settings are inherited by child groups.
* **Tasks:** Processes are attached to cgroups to enforce the configured limits.

## Prerequisites

* **Kernel support:** Linux kernel ≥ 2.6.24 for cgroup v1; kernel ≥ 4.5 for cgroup v2.
* **Tools:** `cgroup-tools` (`cgcreate`, `cgexec`, `cgset`, `cgdelete`).

## Installation

<details>
<summary>Debian/Ubuntu</summary>

```bash
sudo apt update
sudo apt install cgroup-tools
```
</details>

<details>
<summary>RHEL/CentOS/Fedora</summary>

```bash
sudo yum install libcgroup-tools
```
</details>

## Basic Usage

### 1. Create a New cgroup

```bash
# Create a cgroup named "mygroup" for cpu and memory controllers
gsudo cgcreate -g cpu,memory:mygroup
```

### 2. Set Resource Limits

```bash
# Limit memory to 256 MiB
gsudo cgset -r memory.limit_in_bytes=$((256*1024*1024)) mygroup

# Restrict CPU to 50% (0.5 shares)
gsudo cgset -r cpu.shares=512 mygroup
```

### 3. Add Processes

```bash
# Run a command within "mygroup"
sudo cgexec -g cpu,memory:mygroup my_app --option

# Or attach an existing PID:
echo 12345 | sudo tee /sys/fs/cgroup/memory/mygroup/cgroup.procs
```

### 4. Monitor Usage

```bash
# View stats for memory controller
cat /sys/fs/cgroup/memory/mygroup/memory.usage_in_bytes
```

### 5. Delete a cgroup

```bash
sudo cgdelete -g cpu,memory:mygroup
```

## Example Workflow

```bash
# 1. Create
gsudo cgcreate -g cpu,memory:webserver

# 2. Configure
gsudo cgset -r cpu.shares=512 webserver
gsudo cgset -r memory.limit_in_bytes=$((512*1024*1024)) webserver

# 3. Start service in cgroup
sudo cgexec -g cpu,memory:webserver nginx -g 'daemon off;'

# 4. Monitor
watch -n1 cat /sys/fs/cgroup/cpu/webserver/cpuacct.usage

# 5. Cleanup
sudo cgdelete -g cpu,memory:webserver
```

## Advanced Topics

* **cgroup v2 unified hierarchy:** `/sys/fs/cgroup/unified`
* **Systemd integration:** `systemd-run --slice=myslice` for dynamic cgroup creation (see [systemd.resource-control(5)](https://www.freedesktop.org/software/systemd/man/systemd.resource-control.html)).

## References

* Linux Kernel Documentation: [https://www.kernel.org/doc/html/latest/admin-guide/cgroup-v2.html](https://www.kernel.org/doc/html/latest/admin-guide/cgroup-v2.html)
* cgroup-tools GitHub: [https://github.com/hjl-tools/libcgroup](https://github.com/hjl-tools/libcgroup)
* man pages: `man cgcreate`, `man cgexec`, `man cgset`, `man cgdelete`

---

# 2. Container Image From Scratch

This guide walks you through building and running a container image from scratch using Linux namespaces, `docker export`, and the OCI runtime `runc`. You’ll learn how to:

1. **Explore isolation primitives** with the `unshare` command.
2. **Extract a filesystem** from a simple BusyBox container.
3. **Run that filesystem** in a fresh namespace environment.
4. **Generate and customize** an OCI bundle with `runc`.
5. **Wire up networking** manually (bridge + veth pair).
6. **Inspect image layers** using `dive`.

---

## 1. Preparations & Namespace Exploration

Begin by examining the `unshare` help to understand which namespaces you can isolate (UTS, IPC, mount, network, PID, user, cgroup). Then launch a throw‑away shell that has completely separated namespaces, and inspect inside:

* Check your UID/GID, filesystem view, and network interfaces.
* Exit back to the host when you’re done.

## 2. Extracting a Minimal RootFS

Use Docker to spin up a lightweight BusyBox container, then export its filesystem into a local directory (`rootfs`).

* This gives you a minimal, standalone root filesystem without Docker running at runtime.

## 3. Running the Exported FS in Namespaces

Re‑enter `rootfs` under its own isolated namespaces.

* Observe running processes, network stack, and filesystem in this minimal environment.
* Exit back to the host afterward.

## 4. Bootstrapping an OCI Bundle with `runc`

Generate a default `config.json` via `runc spec`.

* Review the bundle layout (`config.json` + `rootfs` directory).
* Launch the container as `demo`, then inspect interfaces and processes inside.
* Customize the `args` in `config.json` to run a simple HTTP server, and disable the TTY (`"terminal": false`).
* Restart the container to verify your changes and then stop it.

## 5. Manual Network Setup

Assign a dedicated network namespace to your container:

1. Create a named namespace (e.g., `runc`).
2. Edit `config.json` to reference `/var/run/netns/runc`.
3. On the host, build a Linux bridge (`runc0`) and a veth pair connecting host ↔ container.
4. Move one end of the veth into the `runc` namespace, rename it inside, assign an IP, and set up a default route.
5. Run the `demo` container again; from another shell, verify you can reach the HTTP server.

## 6. Inspecting Image Layers with Dive

Finally, use the `dive` tool to analyze the layers of any Docker image:

* Download and install `dive`.
* Run `dive <image_id>` to explore layer contents, efficiency, and potential space optimizations.