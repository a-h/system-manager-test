
## Tasks

### create-multipass-vm

Create a new VM. If it already exists, delete it with `multipass delete worker-001`, then `multipass purge`

```sh
multipass launch -n worker-001 --disk 10G --cloud-init cloud-init.yaml --verbose
```

### get-multipass-ip

```bash
export WORKER_IP=`multipass info worker-001 --format=json | jq -r '.info."worker-001".ipv4[0]'`
echo "$WORKER_IP" > worker-ip.txt
```

### ssh

```bash
export WORKER_IP=`cat worker-ip.txt`
echo $WORKER_IP
ssh worker@$WORKER_IP
```

### install-flake-registry-offline

```bash
export WORKER_IP=`cat worker-ip.txt`
# wget https://raw.githubusercontent.com/NixOS/flake-registry/master/flake-registry.json
scp $PWD/flake-registry.json worker@$WORKER_IP:/home/worker/registry.json
ssh worker@$WORKER_IP 'sudo mv /home/worker/registry.json /etc/nix/flake-registry.json'
ssh worker@$WORKER_IP 'sudo chown root:root /etc/nix/flake-registry.json'
ssh worker@$WORKER_IP 'sudo chmod 664 /etc/nix/flake-registry.json'
ssh worker@$WORKER_IP 'sudo systemctl restart nix-daemon'
```

### install-flake-utils

```bash
export WORKER_IP=`cat worker-ip.txt`
# https://github.com/numtide/flake-utils/archive/f9e7cf818399d17d347f847525c5a5a8032e4e44.tar.gz
echo "Cloning flake-utils."
rm -rf flakes/github.com/numtide/flake-utils
git clone https://github.com/numtide/flake-utils flakes/github.com/numtide/flake-utils
echo "Bundling flake-utils to single file."
(cd flakes/github.com/numtide/flake-utils && git bundle create flake-utils.bundle HEAD main)
echo "Copying cloned and bundled flake-utils to remote machine."
ssh worker@$WORKER_IP 'sudo chown -R worker:worker /flakes'
ssh worker@$WORKER_IP rm -rf /flakes/github.com/numtide/flake-utils
scp -r $PWD/flakes/github.com/numtide/flake-utils/flake-utils.bundle worker@$WORKER_IP:/flakes
echo "Unbundling repo on target machine."
ssh worker@$WORKER_IP 'cd /flakes && git clone flake-utils.bundle /flakes/github.com/numtide/flake-utils'
echo "Updating flake registry to point at local copy."
ssh worker@$WORKER_IP 'nix registry add "github:numtide/flake-utils" /flakes/github.com/numtide/flake-utils'
ssh worker@$WORKER_IP 'sudo systemctl restart nix-daemon'
```

### install-system-manager

```bash
export WORKER_IP=`cat worker-ip.txt`
echo "Cloning system-manager."
rm -rf flakes/github.com/numtide/system-manager
git clone https://github.com/numtide/system-manager flakes/github.com/numtide/system-manager
echo "Bundling system-manager to single file."
(cd flakes/github.com/numtide/system-manager && git bundle create system-manager.bundle HEAD main)
echo "Copying cloned and bundled system-manager to remote machine."
ssh worker@$WORKER_IP 'sudo chown -R worker:worker /flakes'
ssh worker@$WORKER_IP rm -rf /flakes/github.com/numtide/system-manager
scp -r $PWD/flakes/github.com/numtide/system-manager/system-manager.bundle worker@$WORKER_IP:/flakes
echo "Unbundling repo on target machine."
ssh worker@$WORKER_IP 'cd /flakes && git clone system-manager.bundle /flakes/github.com/numtide/system-manager'
echo "Updating flake registry to point at local copy."
ssh worker@$WORKER_IP 'nix registry add "github:numtide/system-manager" /flakes/github.com/numtide/system-manager'
ssh worker@$WORKER_IP 'sudo systemctl restart nix-daemon'

echo "Building locally and pushing outputs and build deps to remote machine."
nix copy --no-check-sigs --to ssh-ng://worker@$WORKER_IP github:numtide/system-manager
nix copy --no-check-sigs --derivation --to ssh-ng://worker@$WORKER_IP github:numtide/system-manager

echo "Installing system-manager on remote machine."
# ssh worker@$WORKER_IP 'bash -c "cd /flakes/github.com/numtide/system-manager && nix profile install --offline"'
ssh worker@$WORKER_IP 'nix run "github:numtide/system-manager" --offline --debug'
```

### apply-config

```bash
export WORKER_IP=`cat worker-ip.txt`
# Copy this repo over to the remote.
ssh worker@$WORKER_IP mkdir -p /flakes/github.com/a-h/system-manager-test
scp -r $PWD worker@$WORKER_IP:/flakes/github.com/a-h/system-manager-test
# Build config locally and push the outputs and build deps to the remote machine.
nix copy --to ssh-ng://worker@$WORKER_IP .#systemConfigs.default
nix copy --derivation --to ssh-ng://worker@$WORKER_IP .#systemConfigs.default
# Apply the changes using system manager on the remote machine.
ssh -t worker@$WORKER_IP 'sudo bash --login -c "cd /flakes/github.com/a-h/system-manager-test/worker/worker-001; system-manager switch --flake .'
```

### service-status

```bash
export WORKER_IP=`cat worker-ip.txt`
ssh -t worker@$WORKER_IP systemctl status foo.service
```

### service-logs

```bash
ssh -t worker@$WORKER_IP sudo journalctl -u foo.service
```
