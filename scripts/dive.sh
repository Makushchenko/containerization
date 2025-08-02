DIVE_VERSION=$(curl -sL "https://api.github.com/repos/wagoodman/dive/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
curl -fOL "https://github.com/wagoodman/dive/releases/download/v${DIVE_VERSION}/dive_${DIVE_VERSION}_linux_amd64.deb"
sudo apt install ./dive_${DIVE_VERSION}_linux_amd64.deb
rm -rf dive_${DIVE_VERSION}_linux_amd64.deb
##############
# Read CR_PAT (GitHub Container Registry token) securely (silent input)
read -s CR_PAT
# Authenticate Docker to GitHub Container Registry using the CR_PAT token
echo $CR_PAT | docker login ghcr.io -u Makushchenko --password-stdin

dive --ci --lowestEfficiency=0.9 ghcr.io/makushchenko/kind-ghcr:v1.0.0

# Add to Dockerfile
    # ─── waste layer ──────────────────────────────────────────────
    # Create a 5 MB file that your app never uses
    RUN dd if=/dev/zero of=/tmp/waste.bin bs=1M count=5

    # (Optionally) remove it in the next layer to demonstrate
    # that even deleted data still bloats earlier layers:
    RUN rm /tmp/waste.bin
    # ───────────────────────────────────────────────────────────────

# === Build, Run Locally, and Push to GHCR ===
# ─── waste layer ──────────────────────────────────────────────
# Build the Docker image from the Dockerfile in current directory
docker build -t ghcr.io/makushchenko/kind-ghcr:v1.0.1-waste-layer .
# List all local Docker images to verify the build
docker images
#
dive --ci --lowestEfficiency=0.9 ghcr.io/makushchenko/kind-ghcr:v1.0.1-waste-layer
#
dive ghcr.io/makushchenko/kind-ghcr:v1.0.1-waste-layer

# ─── fix waste layer ──────────────────────────────────────────────
# === Build, Run Locally, and Push to GHCR ===
# Build the Docker image from the Dockerfile in current directory
docker build -t ghcr.io/makushchenko/kind-ghcr:v1.0.1-fix-waste-layer .
# List all local Docker images to verify the build
docker images
#
dive --ci --lowestEfficiency=0.9 ghcr.io/makushchenko/kind-ghcr:v1.0.1-fix-waste-layer
#
dive ghcr.io/makushchenko/kind-ghcr:v1.0.1-fix-waste-layer
