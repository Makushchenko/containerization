# === Build, Run Locally, and Push to GHCR ===
# Build the Docker image from the Dockerfile in current directory
docker build .
# List all local Docker images to verify the build
docker images
# Run the image on port 8080:8080 (replace <image_id> with the actual ID)
docker run -p 8080:8080 <image_id>
# Test the local service by sending an HTTP request to localhost:8080
curl localhost:8080
# Read CR_PAT (GitHub Container Registry token) securely (silent input)
read -s CR_PAT
# Authenticate Docker to GitHub Container Registry using the CR_PAT token
echo $CR_PAT | docker login ghcr.io -u Makushchenko --password-stdin
# Tag the local image for GHCR (replace <image_id> with the actual ID)
docker tag <image_id> ghcr.io/makushchenko/kind-ghcr:v1.0.0
# Push the tagged image to GHCR
docker push ghcr.io/makushchenko/kind-ghcr:v1.0.0

# === Install kind (local Kubernetes cluster) ===
# Download the kind binary for AMD64 / x86_64
curl -Lo kind https://kind.sigs.k8s.io/dl/v0.29.0/kind-linux-amd64
# Make the kind binary executable
chmod +x kind
# Move kind into a directory in your PATH
sudo mv kind /usr/local/bin/
# Create a new kind cluster named kind-ghcr
kind create cluster --name kind-ghcr

# === Deploy Application to kind cluster ===
# Create a Deployment named kind-ghcr pointing to the GHCR image
kubectl create deploy kind-ghcr --image ghcr.io/makushchenko/kind-ghcr:v1.0.0
# Verify the Deployment exists
k get deploy
# List Pods to ensure they are running
k get po

# === Install k9s (Kubernetes CLI tool) ===
# Download and install the latest k9s release, then remove the .deb file
sudo wget https://github.com/derailed/k9s/releases/latest/download/k9s_linux_amd64.deb && sudo apt install ./k9s_linux_amd64.deb && sudo rm k9s_linux_amd64.deb

# === Configure imagePullSecret for ghcr.io ===
# Create a Kubernetes secret for pulling images from GHCR
k create secret docker-registry ghcr-secret --docker-server ghcr.io --docker-username Makushchenko --docker-password $CR_PAT
# Show ServiceAccounts in JSON to verify secret creation
k get serviceaccounts -o json
# Patch the default ServiceAccount to use the new imagePullSecret
k patch serviceaccounts default -p '{"imagePullSecrets": [{"name": "ghcr-secret"}]}'

# === Restart Deployment, Access Pod, and Test Service ===
# Restart the Deployment to pull the new image with secret
k rollout restart deploy kind-ghcr
# Watch Pod status until healthy
k get po -w
# View logs from the Pod (replace <pod_id> with the actual Pod name)
k logs pods/<pod_id>
# Expose the Deployment as a Service on port 80, targeting container port 8080
k expose deployment kind-ghcr --port 80 --target-port 8080
# List Services to verify exposure
k get service
# Forward Service port 80 to localhost:8088
k port-forward svc/kind-ghcr 8088:80
# In another terminal, test the forwarded service
curl localhost:8088
# Exec into the running Pod for debugging (replace <pod_id> with the actual Pod name)
k exec -it <pod_id> -- sh
    ls -l     # Inside Pod: list directory contents
    ip a      # Inside Pod: show network interfaces