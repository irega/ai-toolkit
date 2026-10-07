#!/usr/bin/env bash
set -euo pipefail

SRC=${1:?Usage: expand-servers.sh config.json env-file}
ENV_FILE=${2:?Usage: expand-servers.sh config.json env-file}
servers='[]'

for i in $(jq -r '.servers | keys[]' "$SRC"); do
  server=$(jq -c ".servers[$i]" "$SRC")
  env_key=$(jq -r '.organizationsEnv // empty' <<< "$server")

  if [ -z "$env_key" ]; then
    servers=$(jq -c --argjson server "$server" '. + [$server]' <<< "$servers")
    continue
  fi

  orgs=${!env_key:-}
  if [ -z "$orgs" ] && [ -f "$ENV_FILE" ]; then
    orgs=$(grep -m1 "^${env_key}=" "$ENV_FILE" 2>/dev/null | cut -d= -f2- || true)
  fi
  if [ -z "$orgs" ]; then
    echo "WARNING: Skipping $(jq -r .name <<< "$server"): set $env_key to enable it" >&2
    continue
  fi
  if [[ "$orgs" == \"*\" ]]; then orgs=${orgs:1:${#orgs}-2}; fi
  if [[ "$orgs" == \'*\' ]]; then orgs=${orgs:1:${#orgs}-2}; fi
  jq -e 'any(.args[]?; . == "${org}")' <<< "$server" >/dev/null || {
    echo "ERROR: Server $(jq -r .name <<< "$server") must use \"\${org}\" in args" >&2
    exit 1
  }

  IFS=',' read -r -a org_list <<< "$orgs"
  for org in "${org_list[@]}"; do
    org=$(printf '%s' "$org" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    [[ "$org" =~ ^[A-Za-z0-9-]+$ ]] || {
      echo "ERROR: Invalid organization slug '$org' in $env_key" >&2
      exit 1
    }
    expanded=$(jq -c --arg org "$org" '
      .name += "-" + $org
      | del(.organizationsEnv)
      | .args |= map(if . == "${org}" then $org else . end)
    ' <<< "$server")
    servers=$(jq -c --argjson server "$expanded" '. + [$server]' <<< "$servers")
  done
done

jq -n --argjson servers "$servers" '{servers: $servers}'
