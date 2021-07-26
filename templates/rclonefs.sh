#!/bin/bash
#set -x

remote="$1"
mountpoint="${2%%/}"
shift 2

rclone="{{ lin_rclone_binary }}"
args=""
method=mount
bglog=no

export PATH=/bin:/usr/bin
export RCLONE_CONFIG="{{ lin_rclone_config }}"
export RCLONE_VERBOSE=0
export RCLONE_DAEMON=true
export RCLONE_DAEMON_TIMEOUT=30s

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
    p=${param#*=}
    case "$param" in
      # generic mount options
      rw|ro|dev|nodev|suid|nosuid|exec|noexec|auto|noauto|user)
        continue ;;
      # systemd options
      _netdev|nofail|x-systemd.*)
        continue ;;
      # wrapper options
      proxy=*)
        export http_proxy=$p
        export https_proxy=$p ;;
      config=*)
        export RCLONE_CONFIG=$p ;;
      verbose=*)
        export RCLONE_VERBOSE=$p ;;
      method=*)
        method=$p ;;
      bglog|bglog=*)
        bglog=yes ;;
      # vfs options
      cache-dir=*)
        export RCLONE_CACHE_DIR=$p ;;
      vfs-cache-mode=*)
        export RCLONE_VFS_CACHE_MODE=$p ;;
      dir-cache-time=*)
        export RCLONE_DIR_CACHE_TIME=$p ;;
      daemon-timeout=*)
        export RCLONE_DAEMON_TIMEOUT=$p ;;
      # fuse options
      uid=*)
        export RCLONE_UID=$p ;;
      gid=*)
        export RCLONE_GID=$p ;;
      allow_root|allow-root)
        export RCLONE_ALLOW_ROOT=true ;;
      allow_other|allow-other)
        export RCLONE_ALLOW_OTHER=true ;;
      # other rclone options
      *) args="$args --$param" ;;
    esac
  done
done

if [[ $bglog = yes ]]; then
    stamp=$(date "+%y%m%d-%H%M%S")
    where=$(basename "$mountpoint" | sed -e 's/ /_/g')
    log=/tmp/rclone-${stamp}-$$-${where}.log
    touch "$log"
    # activate verbose background logging
    if [[ $RCLONE_VERBOSE = 0 ]]; then
        export RCLONE_VERBOSE=1
    fi
    export RCLONE_LOG_FORMAT=date,time,microseconds
    export RCLONE_LOG_FILE="$log"
    # deactivate systemd logging in rclone
    unset INVOCATION_ID
fi

# shellcheck disable=SC2086
exec "$rclone" "$method" "$remote" "$mountpoint" ${args} </dev/null
