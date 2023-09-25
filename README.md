## Tasks

### manager-vm-create

Create a new VM. If it already exists, delete it with `multipass delete manager`, then `multipass purge`

```bash
multipass launch -n manager --disk 10G --cpus 4 --memory 8G --cloud-init cloud-init.yaml --verbose
multipass transfer ./key manager:.ssh/key
```

### manager-get-ip

Get the IP address of the manager node and write it to `manager-ip.txt`.

```bash
export MANAGER_IP=`multipass info manager --format=json | jq -r '.info."manager".ipv4[0]'`
echo "$MANAGER_IP" > manager-ip.txt
```

### manager-ssh

SSH into the manager node.

```bash
export MANAGER_IP=`cat manager-ip.txt`
echo $MANAGER_IP
ssh worker@$MANAGER_IP
```

### worker-vm-create

Create a new VM. If it already exists, delete it with `multipass delete worker`, then `multipass purge`

```sh
multipass launch -n worker --disk 10G --cpus 4 --memory 8G --cloud-init cloud-init.yaml --verbose
```

### worker-get-ip

Get the worker IP and write it to `worker-ip.txt`.

```bash
export WORKER_IP=`multipass info worker --format=json | jq -r '.info."worker".ipv4[0]'`
echo "$WORKER_IP" > worker-ip.txt
```

### worker-disable-outbound-internet

Disable the outbound network on the worker.

```bash
export WORKER_IP=`cat worker-ip.txt`
ssh worker@$WORKER_IP 'sudo iptables -t filter -I OUTPUT 1 -m state --state NEW -j DROP'
```

### worker-ssh

SSH into the worker.

```bash
export WORKER_IP=`cat worker-ip.txt`
echo $WORKER_IP
ssh worker@$WORKER_IP
```

### manager-copy-system-manager-to-worker

Copy system-manager from the manager to the worker node.

```bash
export MANAGER_IP=`cat manager-ip.txt`
export WORKER_IP=`cat worker-ip.txt`
echo "Enable SSH from the manager to the worker"
ssh worker@$MANAGER_IP sudo cp /home/ubuntu/.ssh/key /home/worker/.ssh
ssh worker@$MANAGER_IP sudo chmod 400 /home/worker/.ssh/key
ssh worker@$MANAGER_IP sudo chown worker:worker /home/worker/.ssh/key
ssh worker@$MANAGER_IP 'echo "IdentityFile /home/worker/.ssh/key" >> ~/.ssh/config'
ssh worker@$MANAGER_IP "ssh worker@$WORKER_IP -o StrictHostKeyChecking=no hostname"
echo "Building on manager and pushing outputs to worker machine."
ssh worker@$MANAGER_IP nix copy --no-check-sigs --to ssh-ng://worker@$WORKER_IP github:numtide/system-manager
export STORE_PATH=`ssh worker@$MANAGER_IP nix path-info github:numtide/system-manager`
echo "Installing on worker"
ssh worker@$WORKER_IP "nix profile install $STORE_PATH"
```

### worker-run-system-manager

Run system-manager on the worker as a test.

```bash
export WORKER_IP=`cat worker-ip.txt`
ssh worker@$WORKER_IP system-manager
```

### manager-apply-config

Copy the worker configuration to the worker node, and activate it (start the service).

```bash
export MANAGER_IP=`cat manager-ip.txt`
export WORKER_IP=`cat worker-ip.txt`
# Copy this repo over to the remote.
ssh worker@$MANAGER_IP rm -rf /flakes/github.com/a-h/system-manager-test
ssh worker@$MANAGER_IP mkdir -p /flakes/github.com/a-h
scp -r $PWD worker@$MANAGER_IP:/flakes/github.com/a-h
ssh worker@$MANAGER_IP sudo chown -R worker:worker /flakes
# Build config locally and push the outputs to the remote machine.
ssh worker@$MANAGER_IP "(cd /flakes/github.com/a-h/system-manager-test/machines/worker-001 && nix copy --no-check-sigs --to ssh-ng://worker@$WORKER_IP .#systemConfigs.default)"
export STORE_PATH=`ssh worker@$MANAGER_IP "(cd /flakes/github.com/a-h/system-manager-test/machines/worker-001 && nix path-info .#systemConfigs.default)"`
# Apply the changes using system manager on the remote machine.
ssh -t worker@$WORKER_IP "sudo $STORE_PATH/bin/activate"
```

### worker-service-status

Check that the worker started the service.

```bash
export WORKER_IP=`cat worker-ip.txt`
ssh -t worker@$WORKER_IP systemctl status foo.service
```

### worker-service-logs

Read the logs from the service.

```bash
export WORKER_IP=`cat worker-ip.txt`
ssh -t worker@$WORKER_IP sudo journalctl -u foo.service
```
