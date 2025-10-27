#!/bin/bash

running_containers=$(docker ps -q)

for container_id in $running_containers; do
  hostname=$(docker exec "$container_id" hostname)

  if [[ "$hostname" =~ ^(host_|router_).+ ]]; then
    filename="$hostname"

    if [[ ! -f "$filename" ]]; then
      echo "File $filename not found. Skipping container $hostname."
      continue
    fi

    echo "Applying configuration $filename on container $hostname ($container_id)..."

    docker cp "$filename" "$container_id":/
    docker exec "$container_id" ash "/$filename"

    echo "Configuration applied on $hostname ($container_id)."
  else
    echo "Skipping container $hostname ($container_id), hostname does not match."
  fi
done
