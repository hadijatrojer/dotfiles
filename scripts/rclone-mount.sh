#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <remote_name:> <mount_point>" >&2
  exit 1
fi

REMOTE_NAME="$1"
MOUNT_POINT="$2"

mkdir -p -- "${MOUNT_POINT}"

exec rclone mount "${REMOTE_NAME}" "${MOUNT_POINT}" --vfs-cache-mode full --dir-cache-time 5000h --vfs-cache-max-age 5000h
