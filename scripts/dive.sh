# === Install Dive ===
DIVE_VERSION=$(curl -sL "https://api.github.com/repos/wagoodman/dive/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')  # Fetch latest Dive version
curl -fOL "https://github.com/wagoodman/dive/releases/download/v${DIVE_VERSION}/dive_${DIVE_VERSION}_linux_amd64.deb"  # Download Dive .deb
sudo apt install ./dive_${DIVE_VERSION}_linux_amd64.deb  # Install Dive
rm -rf dive_${DIVE_VERSION}_linux_amd64.deb  # Clean up installer

# === Authenticate & Evaluate Image Efficiency ===
read -s CR_PAT  # Read GHCR token silently
echo $CR_PAT | docker login ghcr.io -u Makushchenko --password-stdin  # Log in to GitHub Container Registry
dive --ci --lowestEfficiency=0.9 ghcr.io/makushchenko/kind-ghcr:v1.0.0  # Run Dive CI check on v1.0.0

# === Waste Layer Dockerfile Snippet ===
# Add to Dockerfile:
# ─── waste layer ──────────────────────────────────────────────
# Create a 5 MB file that your app never uses
    RUN dd if=/dev/zero of=/tmp/waste.bin bs=1M count=5
#
# (Optionally) remove it in the next layer to demonstrate
# that even deleted data still bloats earlier layers:
    RUN rm /tmp/waste.bin
# ───────────────────────────────────────────────────────────────

# === Build & Evaluate with Waste Layer ===
docker build -t ghcr.io/makushchenko/kind-ghcr:v1.0.1-waste-layer .  # Build image with waste layer
docker images  # Verify local images list
dive --ci --lowestEfficiency=0.9 ghcr.io/makushchenko/kind-ghcr:v1.0.1-waste-layer  # CI check on waste-layer image
dive ghcr.io/makushchenko/kind-ghcr:v1.0.1-waste-layer  # Interactive Dive exploration

# === Build & Evaluate Fixed Waste Layer ===
docker build -t ghcr.io/makushchenko/kind-ghcr:v1.0.1-fix-waste-layer .  # Build fixed image
docker images  # Verify local images list
dive --ci --lowestEfficiency=0.9 ghcr.io/makushchenko/kind-ghcr:v1.0.1-fix-waste-layer  # CI check on fixed image
dive ghcr.io/makushchenko/kind-ghcr:v1.0.1-fix-waste-layer  # Interactive Dive exploration