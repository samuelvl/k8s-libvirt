#cloud-config
hostname: ${hostname}
fqdn: ${fqdn}
manage_etc_hosts: true
ssh_pwauth: false
disable_root: false
users:
  - name: maintuser
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups:
      - sudo
    shell: /bin/bash
    lock_passwd: false
    ssh-authorized-keys:
      - ${ssh_pubkey}
packages:
  - qemu-guest-agent

# every boot
bootcmd:
    - [ sh, -c, 'echo $(date) | sudo tee -a /root/bootcmd.log' ]

# run once for setup
runcmd:
    - [ sh, -c, 'echo $(date) | sudo tee -a /root/runcmd.log' ]

# written to /var/log/cloud-init-output.log
final_message: "The system is finall up, after $UPTIME seconds"
