#!/usr/bin/env bash

target_dir="$1"

if [ -z "$target_dir" ]; then
  echo "Usage: $0 <docker-folder-path>"
  exit 1
fi

if [ ! -d "$target_dir" ]; then
  echo "Docker folder not found: $target_dir"
  exit 1
fi

cd "$target_dir" || exit 1

docker compose pull
docker compose up -d --force-recreate
