#!/bin/bash
#set -x

remote="$1"
mountpoint="$2"
shift 2

wait=yes
foreground=no
rclone={{ lin_rclone_binary }}
args=""

export PATH=/bin:/usr/bin
export RCLONE_CONFIG={{ lin_rclone_config }}
export RCLONE_VERBOSE=0

# Process -o parameters
while getopts :o: opts; do
  if [ "$opts" != "o" ]; then
    echo "invalid option: -${OPTARG}"
    continue
  fi

  params=${OPTARG//,/ }
  for param in $params; do
    case "$param" in
      # generic mount options
      rw|ro|dev|nodev|suid|nosuid|exec|noexec|auto|noauto|user)
        continue ;;
      # systemd options
      _netdev|nofail|x-systemd.*)
        continue ;;
      # wrapper options
      config=*)
        export RCLONE_CONFIG=${param#config=} ;;
      verbose=*)
        export RCLONE_VERBOSE=${param#verbose=} ;;
      rcaddr=*)
        export RCLONE_RC=true
        export RCLONE_RC_NO_AUTH=true
        export RCLONE_RC_ADDR=${param#rcaddr=} ;;       
      nowait)
        wait=no ;;
      foreground)
        foreground=yes ;;
      # fuse / rclone options
      allow_other|allow_root|uid=*|gid=*)
        args="$args --${param//_/-}" ;;
      # rclone options
      *)
        args="$args --$param" ;;
    esac
  done
done

# exec rclone
if [ $foreground = yes ]; then
  exec $rclone mount $args $remote $mountpoint
else
  # NOTE: --daemon hangs under systemd automount, using `&`
  $rclone mount $args $remote $mountpoint </dev/null >&/dev/null &
  # WARNING: this check hangs for empty mounts!
  while [ $wait = yes ] && [ "$(ls -lA $mountpoint)" = "total 0" ]; do
    sleep 0.5
  done
fi
