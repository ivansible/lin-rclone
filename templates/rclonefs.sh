#!/bin/bash
#set -x

remote="$1"
mountpoint="${2%%/}"
shift 2

wait=yes
bglog=no
foreground=no
mount_verb=mount
rclone="{{ lin_rclone_binary }}"
args=""

export PATH=/bin:/usr/bin
export RCLONE_CONFIG="{{ lin_rclone_config }}"
export RCLONE_VERBOSE=0

export RCLONE_CACHE_DIR="{{ lin_rclone_cache_dir }}"
unset RCLONE_VFS_CACHE_MODE
unset RCLONE_DIR_CACHE_TIME
unset RCLONE_UID
unset RCLONE_GID
unset RCLONE_ALLOW_ROOT
unset RCLONE_ALLOW_OTHER

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
      proxy=*)
        export http_proxy=${param#*=}
        export https_proxy=${param#*=} ;;
      config=*)
        export RCLONE_CONFIG=${param#*=} ;;
      verbose=*)
        export RCLONE_VERBOSE=${param#*=} ;;
      mount-verb=*)
        mount_verb=${param#*=} ;;
      nowait)
        wait=no ;;
      foreground)
        foreground=yes ;;
      bglog)
        bglog=yes ;;
      # vfs options
      cache-dir=*)
        export RCLONE_CACHE_DIR=${param#*=} ;;
      vfs-cache-mode=*)
        export RCLONE_VFS_CACHE_MODE=${param#*=} ;;
      dir-cache-time=*)
        export RCLONE_DIR_CACHE_TIME=${param#*=} ;;
      # fuse options
      uid=*)
        export RCLONE_UID=${param#*=} ;;
      gid=*)
        export RCLONE_GID=${param#*=} ;;
      allow_root)
        export RCLONE_ALLOW_ROOT=true ;;
      allow_other)
        export RCLONE_ALLOW_OTHER=true ;;
      # other rclone options
      *) args="$args --$param" ;;
    esac
  done
done

if [ $bglog = yes ]; then
  stamp=$(date '+%y%m%d-%H%M%S')
  pid=$$
  where=$(basename "$mountpoint")
  logfile=/tmp/rclone-${stamp}-${pid}-${where}.log
  touch "$logfile"
  chmod 666 "$logfile"
  # activate verbose background logging
  export RCLONE_VERBOSE=3
  export RCLONE_LOG_FORMAT=date,time,microseconds
  export RCLONE_LOG_FILE=$logfile
  # deactivate systemd log flavor in rclone
  unset INVOCATION_ID
fi

# exec rclone (shellcheck note: args must stay unquoted)
if [ $foreground = yes ]; then
  # shellcheck disable=SC2086
  exec "$rclone" mount $args "$remote" "$mountpoint"
else
  # NOTE: --daemon hangs under systemd automount, using `&`
  # shellcheck disable=SC2086
  "$rclone" "$mount_verb" $args "$remote" "$mountpoint" </dev/null >&/dev/null &
  while [ $wait = yes ] && [ "$(grep -c " ${mountpoint} fuse.rclone " /proc/mounts)" = 0 ]; do
    sleep 0.5
  done
fi
