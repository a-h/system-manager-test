
## Tasks

### create-multipass-vm

You might need to destroy your default vm with `multipass delete --all`

```sh
multipass launch -n stunning-fantail --disk 10G --cloud-init cloud-init.yaml --verbose
```

### find-multipass-ip

```sh
multipass info stunning-fantail
```

### ssh

```sh
ssh adrian-hesketh@10.162.19.9
```

### copy

```
scp -r ./machines/stunning-fantail adrian-hesketh@10.162.19.9:/home/adrian-hesketh
```

### run

```
ssh -t adrian-hesketh@10.162.19.9 'sudo bash --login /home/adrian-hesketh/stunning-fantail/run.sh'
```

### service-status

```
ssh -t adrian-hesketh@10.162.19.9 systemctl status foo.service
```

### service-logs

```
ssh -t adrian-hesketh@10.162.19.9 sudo journalctl -u foo.service
```
