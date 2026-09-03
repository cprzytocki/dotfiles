#!/usr/bin/env bash
# Add (or remove) your current public IP on the Azure SQL Server, Key Vault and
# DocumentDB firewalls for each environment. Tenant, subscription ids and
# resource naming live in ankored-firewall.env beside this script, which is not
# committed; see ankored-firewall.env.example.
set -euo pipefail

CONFIG_FILE="${ANKORED_FW_CONFIG:-$(dirname "${BASH_SOURCE[0]}")/ankored-firewall.env}"
if [[ ! -f $CONFIG_FILE ]]; then
  echo "error: missing config $CONFIG_FILE" >&2
  echo "       copy ankored-firewall.env.example beside this script and fill it in" >&2
  exit 1
fi
# shellcheck disable=SC1090
. "$CONFIG_FILE"

for required in ANKORED_TENANT ANKORED_SUB_PROD ANKORED_SUB_NONPROD \
  ANKORED_RG_PROD ANKORED_RG_NAME ANKORED_KV_NAME ANKORED_SQL_NAME ANKORED_DOCDB_NAME; do
  if [[ -z ${!required:-} ]]; then
    echo "error: $required is not set in $CONFIG_FILE" >&2
    exit 1
  fi
done

readonly ALL_ENVS=(dev qa prod)
# First-party first: the answer becomes a firewall allowlist entry, so prefer a
# source we run over ones we do not.
IP_SERVICES=(https://api.ipify.org https://icanhazip.com https://4.ident.me)
if [[ -n ${ANKORED_IP_SERVICE:-} ]]; then
  IP_SERVICES=("$ANKORED_IP_SERVICE" "${IP_SERVICES[@]}")
fi
readonly IP_SERVICES
readonly DOCDB_API=2026-06-01
readonly TENANT=$ANKORED_TENANT

usage() {
  command cat <<'EOF'
Usage: ankored-firewall-ip [options] [env ...]

Environments: dev qa prod (default: all three)

Options:
  -r, --remove            Remove the IP instead of adding it
  -s, --services LIST     Comma-separated subset of: keyvault,sqlserver,documentdb
  -i, --ip ADDRESS        Use this IP instead of auto-detecting (validated)
  -n, --rule-name NAME    Firewall rule name (default: $ANKORED_FW_RULE_NAME or $USER)
      --status            Show the table and exit without changing anything
      --dry-run           Show the table, then print the az commands unrun
  -y, --yes               Skip the confirmation prompt
      --no-login          Fail instead of running az login when signed out
  -v, --verbose           Print the full Azure error when a change fails
  -h, --help              Show this help

The public IP comes from the first-party endpoint in ankored-firewall.env when
set, falling back to third-party lookup services. Any run that includes prod
requires two sources to agree.

SQL and DocumentDB reuse one named rule per env, so they replace in place. Key
Vault network rules have no names, so the IP still recorded on your named SQL
(or DocumentDB) rule is what gets pruned from the vault.
EOF
}

sub_for_env() {
  if [[ $1 == prod ]]; then echo "$ANKORED_SUB_PROD"; else echo "$ANKORED_SUB_NONPROD"; fi
}

rg_for_env() {
  if [[ $1 == prod ]]; then echo "$ANKORED_RG_PROD"; else echo "${ANKORED_RG_NAME//\{env\}/$1}"; fi
}

kv_for_env() { echo "${ANKORED_KV_NAME//\{env\}/$1}"; }
sql_for_env() { echo "${ANKORED_SQL_NAME//\{env\}/$1}"; }
docdb_for_env() { echo "${ANKORED_DOCDB_NAME//\{env\}/$1}"; }

docdb_url() {
  local sub=$1 rg=$2 cluster=$3 rule=${4:-}
  printf 'https://management.azure.com/subscriptions/%s/resourceGroups/%s/providers/Microsoft.DocumentDB/mongoClusters/%s%s?api-version=%s' \
    "$sub" "$rg" "$cluster" "${rule:+/firewallRules/$rule}" "$DOCDB_API"
}

valid_ip() {
  local octet
  case "$1" in
    ""|*[!0-9.]*|.*|*.|*..*) return 1 ;;
  esac
  local IFS=.
  set -- $1
  [[ $# -eq 4 ]] || return 1
  for octet in "$@"; do
    [[ ${#octet} -le 3 ]] || return 1
    [[ $((10#$octet)) -le 255 ]] || return 1
  done
  return 0
}

# With prod in scope a single hijacked lookup service could hand us an attacker's
# address to allowlist, so require two independent sources to agree.
detect_ip() {
  local confirm=$1 service ip first=""
  for service in "${IP_SERVICES[@]}"; do
    ip=$(curl -fsS --max-time 5 "$service" 2>/dev/null | tr -d '[:space:]') || continue
    valid_ip "$ip" || continue
    if [[ $confirm == false ]]; then
      echo "$ip"
      return 0
    fi
    if [[ -z $first ]]; then
      first=$ip
      continue
    fi
    if [[ $ip == "$first" ]]; then
      echo "$ip"
      return 0
    fi
    echo "error: IP lookup services disagree ($first vs $ip); pass -i to choose" >&2
    return 1
  done
  if [[ -n $first ]]; then
    echo "error: only one source answered ($first); pass -i to confirm it" >&2
    return 1
  fi
  echo "error: could not determine public IP" >&2
  return 1
}

LAST_ERROR=""

run() {
  if [[ $DRY_RUN == true ]]; then
    printf '  + %s\n' "$*"
    return 0
  fi
  # az writes progress and errors to stderr; capturing it keeps the counter line
  # intact and lets the caller summarise the failure in one line.
  if ! LAST_ERROR=$("$@" 2>&1 >/dev/null); then
    return 1
  fi
  LAST_ERROR=""
  return 0
}

error_reason() {
  case "$LAST_ERROR" in
    *"does not have authorization"*|*AuthorizationFailed*|*Forbidden*)
      echo "no write permission" ;;
    *AuthenticationFailed*|*"expired"*|*"re-authenticate"*)
      echo "credentials expired" ;;
    *ResourceNotFound*|*"was not found"*)
      echo "resource not found" ;;
    "")
      echo "unknown error" ;;
    *)
      printf '%s' "$LAST_ERROR" | tr '\n' ' ' | cut -c1-90 ;;
  esac
}

missing_subs() {
  local sub
  for sub in "$@"; do
    if ! az account get-access-token --subscription "$sub" -o none 2>/dev/null; then
      echo "$sub"
    fi
  done
}

# A subscription that fails the token check is either signed out or simply not
# granted to this account; only the all-fail case is worth re-running login for.
UNREACHABLE_SUBS=" "

ensure_access() {
  local missing count

  missing=$(missing_subs "$@")
  if [[ -z $missing ]]; then
    return 0
  fi

  count=$(printf '%s\n' $missing | wc -l | tr -d ' ')
  if [[ $count -eq $# ]]; then
    if [[ $AUTO_LOGIN == false || ! -t 0 ]]; then
      command cat >&2 <<EOF
error: not signed in to Azure (or the token expired) for:
$(printf '  %s\n' $missing)

  az login --tenant $TENANT
EOF
      exit 1
    fi

    echo "Azure sign-in needed, opening a browser..."
    if ! az login --tenant "$TENANT" -o none; then
      echo "error: az login failed" >&2
      exit 1
    fi
    missing=$(missing_subs "$@")
  fi

  UNREACHABLE_SUBS=" $(echo $missing) "
}

sub_unreachable() {
  case "$UNREACHABLE_SUBS" in
    *" $1 "*) return 0 ;;
  esac
  return 1
}

# The named SQL rule doubles as the record of the last IP this operator applied:
# unlike a local file it is per-person, shared across machines, and cannot drift
# out of sync with the vault. DocumentDB is the fallback when SQL has no rule.
previous_ip() {
  local sub=$1 rg=$2 env=$3 ip

  if ip=$(az sql server firewall-rule show --name "$RULE_NAME" --server "$(sql_for_env "$env")" \
    --resource-group "$rg" --subscription "$sub" --query startIpAddress -o tsv 2>/dev/null); then
    echo "$ip"
    return 0
  fi

  if ip=$(az rest --method get --subscription "$sub" \
    --url "$(docdb_url "$sub" "$rg" "$(docdb_for_env "$env")" "$RULE_NAME")" \
    --query properties.startIpAddress -o tsv 2>/dev/null); then
    echo "$ip"
  fi
}

PROGRESS_DONE=0
PROGRESS_TOTAL=0

# Both phases are one az call per resource, so keep the wait visible on a terminal.
progress() {
  PROGRESS_DONE=$((PROGRESS_DONE + 1))
  if [[ -t 2 ]]; then
    printf '\r  %s %s %s (%d/%d)\033[K' "$1" "$2" "$3" "$PROGRESS_DONE" "$PROGRESS_TOTAL" >&2
  fi
}

progress_clear() {
  if [[ -t 2 ]]; then
    printf '\r\033[K' >&2
  fi
}

# Each row is env|service|resource|current|plan|extra, where plan drives apply_row.
ROWS=()

survey_keyvault() {
  local env=$1 sub=$2 rg=$3 vault=$4 prev=$5
  local acl mode has_ip has_prev current plan

  # tsv renders a JMESPath list one value per line, so join into a single row.
  if ! acl=$(az keyvault network-rule list --name "$vault" --resource-group "$rg" \
    --subscription "$sub" -o tsv --query "join('|', [
      defaultAction,
      to_string(length(ipRules[?value=='$IP' || value=='$IP/32'])),
      to_string(length(ipRules[?value=='$prev' || value=='$prev/32']))])" 2>/dev/null); then
    ROWS+=("$env|keyvault|$vault|no access|skip|")
    return 0
  fi

  IFS='|' read -r mode has_ip has_prev <<<"$acl"

  if [[ $mode != Deny ]]; then
    ROWS+=("$env|keyvault|$vault|open ($mode)|none|")
    return 0
  fi

  [[ -z $prev || $prev == "$IP" ]] && has_prev=0

  if [[ $ACTION == remove ]]; then
    if [[ $has_ip -gt 0 && $has_prev -gt 0 ]]; then
      ROWS+=("$env|keyvault|$vault|allowed, stale $prev|remove+clean|$prev")
    elif [[ $has_ip -gt 0 ]]; then
      ROWS+=("$env|keyvault|$vault|allowed|remove|")
    elif [[ $has_prev -gt 0 ]]; then
      ROWS+=("$env|keyvault|$vault|stale $prev|clean|$prev")
    else
      ROWS+=("$env|keyvault|$vault|not allowed|none|")
    fi
    return 0
  fi

  if [[ $has_ip -gt 0 ]]; then
    current="allowed"
    plan=none
  else
    current="not allowed"
    plan=add
  fi
  if [[ $has_prev -gt 0 ]]; then
    current="$current, stale $prev"
    [[ $plan == none ]] && plan=clean || plan=add+clean
  fi
  ROWS+=("$env|keyvault|$vault|$current|$plan|$prev")
}

# Shared shape for the two services that key off a single named rule.
record_named_rule() {
  local env=$1 service=$2 resource=$3 found=$4 rule_ip=$5 reachable=$6

  if [[ $found == false ]]; then
    if [[ $reachable == false ]]; then
      ROWS+=("$env|$service|$resource|no access|skip|")
    elif [[ $ACTION == remove ]]; then
      ROWS+=("$env|$service|$resource|no rule|none|")
    else
      ROWS+=("$env|$service|$resource|no rule|create|")
    fi
  elif [[ $ACTION == remove ]]; then
    ROWS+=("$env|$service|$resource|rule $rule_ip|delete|")
  elif [[ $rule_ip == "$IP" ]]; then
    ROWS+=("$env|$service|$resource|allowed|none|")
  else
    ROWS+=("$env|$service|$resource|stale $rule_ip|update|")
  fi
}

survey_sqlserver() {
  local env=$1 sub=$2 rg=$3 server=$4 rule_ip reachable=true

  if rule_ip=$(az sql server firewall-rule show --name "$RULE_NAME" --server "$server" \
    --resource-group "$rg" --subscription "$sub" --query startIpAddress -o tsv 2>/dev/null); then
    record_named_rule "$env" sql "$server" true "$rule_ip" true
    return 0
  fi

  az sql server show --name "$server" --resource-group "$rg" --subscription "$sub" \
    -o none 2>/dev/null || reachable=false
  record_named_rule "$env" sql "$server" false "" "$reachable"
}

survey_documentdb() {
  local env=$1 sub=$2 rg=$3 cluster=$4 rule_ip reachable=true

  if rule_ip=$(az rest --method get --subscription "$sub" \
    --url "$(docdb_url "$sub" "$rg" "$cluster" "$RULE_NAME")" \
    --query properties.startIpAddress -o tsv 2>/dev/null) && [[ -n $rule_ip ]]; then
    record_named_rule "$env" documentdb "$cluster" true "$rule_ip" true
    return 0
  fi

  az rest --method get --subscription "$sub" --url "$(docdb_url "$sub" "$rg" "$cluster")" \
    -o none 2>/dev/null || reachable=false
  record_named_rule "$env" documentdb "$cluster" false "" "$reachable"
}

print_table() {
  local row env service resource current plan
  printf '\n%-5s  %-10s  %-19s  %-26s  %s\n' ENV SERVICE RESOURCE CURRENT ACTION
  for row in "${ROWS[@]}"; do
    IFS='|' read -r env service resource current plan _ <<<"$row"
    [[ $plan == none ]] && plan="-"
    printf '%-5s  %-10s  %-19s  %-26s  %s\n' "$env" "$service" "$resource" "$current" "$plan"
  done
  printf '\n'
}

# DocumentDB rule writes are long-running; ARM returns before the rule is live.
wait_for_docdb() {
  local sub=$1 url=$2 want=$3 attempt state
  for ((attempt = 0; attempt < 40; attempt++)); do
    if state=$(az rest --method get --subscription "$sub" --url "$url" \
      --query properties.provisioningState -o tsv 2>/dev/null); then
      [[ $want == gone ]] || { [[ $state == Succeeded ]] && return 0; }
      [[ $state == Failed || $state == Canceled ]] && return 1
    elif [[ $want == gone ]]; then
      return 0
    fi
    sleep 5
  done
  LAST_ERROR="timed out waiting for the rule to finish provisioning"
  return 1
}

apply_row() {
  local env=$1 service=$2 resource=$3 plan=$4 extra=$5
  local sub rg verb url
  sub=$(sub_for_env "$env")
  rg=$(rg_for_env "$env")

  case "$service:$plan" in
    keyvault:add|keyvault:add+clean|keyvault:clean)
      if [[ $plan != add ]]; then
        run az keyvault network-rule remove --name "$resource" --resource-group "$rg" \
          --subscription "$sub" --ip-address "$extra" || return 1
      fi
      if [[ $plan != clean ]]; then
        run az keyvault network-rule add --name "$resource" --resource-group "$rg" \
          --subscription "$sub" --ip-address "$IP" || return 1
      fi
      ;;
    keyvault:remove|keyvault:remove+clean)
      run az keyvault network-rule remove --name "$resource" --resource-group "$rg" \
        --subscription "$sub" --ip-address "$IP" || return 1
      if [[ $plan == remove+clean ]]; then
        run az keyvault network-rule remove --name "$resource" --resource-group "$rg" \
          --subscription "$sub" --ip-address "$extra" || return 1
      fi
      ;;
    sql:create|sql:update)
      [[ $plan == create ]] && verb=create || verb=update
      run az sql server firewall-rule "$verb" --name "$RULE_NAME" --server "$resource" \
        --resource-group "$rg" --subscription "$sub" \
        --start-ip-address "$IP" --end-ip-address "$IP" || return 1
      ;;
    sql:delete)
      run az sql server firewall-rule delete --name "$RULE_NAME" --server "$resource" \
        --resource-group "$rg" --subscription "$sub" || return 1
      ;;
    documentdb:create|documentdb:update)
      url=$(docdb_url "$sub" "$rg" "$resource" "$RULE_NAME")
      run az rest --method put --subscription "$sub" --url "$url" \
        --body "{\"properties\":{\"startIpAddress\":\"$IP\",\"endIpAddress\":\"$IP\"}}" || return 1
      if [[ $DRY_RUN == false ]]; then wait_for_docdb "$sub" "$url" live || return 1; fi
      ;;
    documentdb:delete)
      url=$(docdb_url "$sub" "$rg" "$resource" "$RULE_NAME")
      run az rest --method delete --subscription "$sub" --url "$url" || return 1
      if [[ $DRY_RUN == false ]]; then wait_for_docdb "$sub" "$url" gone || return 1; fi
      ;;
  esac
  return 0
}

ACTION=add
DRY_RUN=false
STATUS_ONLY=false
ASSUME_YES=false
AUTO_LOGIN=true
VERBOSE=false
SERVICES=keyvault,sqlserver,documentdb
RULE_NAME=${ANKORED_FW_RULE_NAME:-$(whoami)}
IP=""
ENVS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -r|--remove) ACTION=remove; shift ;;
    -s|--services) SERVICES=$2; shift 2 ;;
    -i|--ip) IP=$2; shift 2 ;;
    -n|--rule-name) RULE_NAME=$2; shift 2 ;;
    --status) STATUS_ONLY=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    -y|--yes) ASSUME_YES=true; shift ;;
    --no-login) AUTO_LOGIN=false; shift ;;
    -v|--verbose) VERBOSE=true; shift ;;
    -h|--help) usage; exit 0 ;;
    dev|qa|prod) ENVS+=("$1"); shift ;;
    *) echo "error: unknown argument '$1'" >&2; usage >&2; exit 2 ;;
  esac
done

[[ ${#ENVS[@]} -eq 0 ]] && ENVS=("${ALL_ENVS[@]}")
if [[ -n $IP ]] && ! valid_ip "$IP"; then
  echo "error: invalid IP address '$IP'" >&2
  exit 2
fi

if [[ -z $IP ]]; then
  confirm_ip=false
  for env in "${ENVS[@]}"; do
    if [[ $env == prod ]]; then confirm_ip=true; fi
  done
  IP=$(detect_ip "$confirm_ip") || exit 1
fi

want_keyvault=false
want_sqlserver=false
want_documentdb=false
IFS=, read -ra requested <<<"$SERVICES"
for service in "${requested[@]}"; do
  case "${service// /}" in
    keyvault) want_keyvault=true ;;
    sqlserver|sql) want_sqlserver=true ;;
    documentdb|docdb) want_documentdb=true ;;
    *) echo "error: unknown service '$service'" >&2; exit 2 ;;
  esac
done

subs=()
for env in "${ENVS[@]}"; do subs+=("$(sub_for_env "$env")"); done
ensure_access $(printf '%s\n' "${subs[@]}" | sort -u)

reachable=()
skipped=()
for env in "${ENVS[@]}"; do
  if sub_unreachable "$(sub_for_env "$env")"; then
    skipped+=("$env")
  else
    reachable+=("$env")
  fi
done

if [[ ${#reachable[@]} -eq 0 ]]; then
  echo "error: no access to any requested environment: ${ENVS[*]}" >&2
  exit 1
fi

service_count=0
for want in "$want_keyvault" "$want_sqlserver" "$want_documentdb"; do
  if [[ $want == true ]]; then service_count=$((service_count + 1)); fi
done
PROGRESS_TOTAL=$((${#reachable[@]} * service_count))

echo "Public IP $IP   mode $ACTION   rule '$RULE_NAME'"
echo "Reading $PROGRESS_TOTAL firewalls across ${#reachable[@]} environment(s)..."

for env in "${ENVS[@]}"; do
  sub=$(sub_for_env "$env")
  rg=$(rg_for_env "$env")
  if sub_unreachable "$sub"; then
    if [[ $want_keyvault == true ]]; then ROWS+=("$env|keyvault|$(kv_for_env "$env")|no access|skip|"); fi
    if [[ $want_sqlserver == true ]]; then ROWS+=("$env|sql|$(sql_for_env "$env")|no access|skip|"); fi
    if [[ $want_documentdb == true ]]; then ROWS+=("$env|documentdb|$(docdb_for_env "$env")|no access|skip|"); fi
    continue
  fi
  prev=""
  if [[ $want_keyvault == true ]]; then
    prev=$(previous_ip "$sub" "$rg" "$env")
    progress checking "$env" keyvault
    survey_keyvault "$env" "$sub" "$rg" "$(kv_for_env "$env")" "$prev"
  fi
  if [[ $want_sqlserver == true ]]; then
    progress checking "$env" sql
    survey_sqlserver "$env" "$sub" "$rg" "$(sql_for_env "$env")"
  fi
  if [[ $want_documentdb == true ]]; then
    progress checking "$env" documentdb
    survey_documentdb "$env" "$sub" "$rg" "$(docdb_for_env "$env")"
  fi
done
progress_clear

print_table

if [[ ${#skipped[@]} -gt 0 ]]; then
  echo "No access to ${skipped[*]}, skipped."
fi

pending=()
for row in "${ROWS[@]}"; do
  IFS='|' read -r _ _ _ _ plan _ <<<"$row"
  [[ $plan == none || $plan == skip ]] || pending+=("$row")
done

if [[ ${#pending[@]} -eq 0 ]]; then
  echo "Everything is already set correctly."
  exit 0
fi

[[ $STATUS_ONLY == true ]] && exit 0

if [[ $ASSUME_YES == false && $DRY_RUN == false ]]; then
  read -rp "Apply ${#pending[@]} change(s)? [y/N] " reply
  [[ $reply == [yY]* ]] || { echo "Aborted."; exit 1; }
fi

failed=0
failed_envs=" "
failed_reasons=""
reason=""
PROGRESS_DONE=0
PROGRESS_TOTAL=${#pending[@]}
for row in "${pending[@]}"; do
  IFS='|' read -r env service resource current plan extra <<<"$row"
  progress applying "$env" "$service"
  if apply_row "$env" "$service" "$resource" "$plan" "$extra"; then
    :
  else
    reason=$(error_reason)
    progress_clear
    echo "  $env $service: failed ($reason)" >&2
    if [[ $VERBOSE == true && -n $LAST_ERROR ]]; then
      printf '%s\n' "$LAST_ERROR" >&2
    fi
    failed=$((failed + 1))
    failed_envs="$failed_envs$env "
    case "$failed_reasons" in
      *"$env: $reason"*) ;;
      *) failed_reasons="$failed_reasons$env: $reason; " ;;
    esac
  fi
done
progress_clear

if [[ $failed -gt 0 ]]; then
  echo "$failed of ${#pending[@]} change(s) failed -- ${failed_reasons%; }" >&2
  ok_envs=""
  for env in "${ENVS[@]}"; do
    case "$failed_envs" in
      *" $env "*) ;;
      *) ok_envs="$ok_envs $env" ;;
    esac
  done
  if [[ -n $ok_envs && $VERBOSE == false ]]; then
    echo "Rerun as 'firewall$ok_envs' to skip what you cannot change, or -v for the full error." >&2
  fi
  exit 1
fi

if [[ $DRY_RUN == false ]]; then
  echo "Applied ${#pending[@]} change(s)."
fi
