for id in $(docker ps -q); do
  name=$(docker inspect --format '{{.Name}}' "$id" | tr -d '/')
  version=$(docker exec "$id" sh -c 'php -v 2>/dev/null' 2>/dev/null | head -n 1)
  if [ -n "$version" ]; then
    echo "$name: $version"
  fi
done