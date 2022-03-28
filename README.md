# backup_containers

 Backup containers from all my podman containers into my backup host (e.g. a remote host, a Synology NAS, a NAS, etc.)
 ---------------------------------------------------------------------------
> USE AT YOUR OWN RISK! It may delete files on the backup host!
{.is-warn}

 **Assumptions:**
 - I have a backup host (e.g. a remote host, a Synology NAS, a NAS, etc.) that runs a cron job to backup my containers
  - source host account has passwordless ssh login (with key) (ssh-copy-id user@host)
  - source host account has sudo with no password for tar command (echo "username ALL=(ALL) NOPASSWD: /usr/bin/tar" | sudo tee -a /etc/sudoers.d/username)
  - destination host has xz in path
  - no error control is done on the source host, if it fails, it fails. There are stop and start files to know if the container is running or not
  - containers are running under podman, and each application has all containers inside a pod with the name of the app. containers are then named with suffixes as -app, -db, etc
  - I run my containers as non root on a standard /home/username/podman-podname/ folder structure. This allows me to include on the .ini file only the hostname, the pod name and the exclude patterns
  - structure of the .ini file is: hostname;podname;exclude pattern;include pattern;source directory (separated by ;)
  - I keep only the last 30 days of backups of each container
