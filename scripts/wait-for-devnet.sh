#!/usr/bin/env bash

set -euo pipefail

DEVNET_HTTP_URL="${ZNN_TEST_HTTP_URL:-http://127.0.0.1:35997}"
EXPECTED_CHAIN_ID="${ZNN_TEST_CHAIN_ID:-69}"
MAX_ATTEMPTS="${ZNN_TEST_DEVNET_WAIT_ATTEMPTS:-10}"
SLEEP_SECONDS="${ZNN_TEST_DEVNET_WAIT_SLEEP_SECONDS:-6}"
FRONTIER_MOMENTUM_PAYLOAD='{"jsonrpc":"2.0","id":1,"method":"ledger.getFrontierMomentum","params":[]}'
SYNC_INFO_PAYLOAD='{"jsonrpc":"2.0","id":1,"method":"stats.syncInfo","params":[]}'

last_response=""

rpc_call() {
  local payload="$1"

  curl -fsS \
    -H 'Content-Type: application/json' \
    -d "${payload}" \
    "${DEVNET_HTTP_URL}"
}

has_expected_chain_id() {
  local response="$1"

  case "${response}" in
    *'"chainIdentifier":'"${EXPECTED_CHAIN_ID}"*|*'"chainIdentifier": '"${EXPECTED_CHAIN_ID}"*)
      return 0
      ;;
  esac

  return 1
}

extract_momentum_height() {
  local response="$1"

  if [[ "${response}" =~ \"height\"[[:space:]]*:[[:space:]]*([0-9]+) ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}"
    return 0
  fi

  return 1
}

is_sync_done() {
  local response="$1"

  # SyncState.syncDone is index 2 in znn_sdk_dart. Accept the string form too
  # in case the node response changes to enum names in the future.
  case "${response}" in
    *'"state":2'*|*'"state": 2'*|*'"state":"syncDone"'*|*'"state": "syncDone"'*)
      return 0
      ;;
  esac

  return 1
}

for attempt in $(seq 1 "${MAX_ATTEMPTS}"); do
  if last_response=$(rpc_call "${FRONTIER_MOMENTUM_PAYLOAD}" 2>&1) &&
    has_expected_chain_id "${last_response}"; then
    initial_height=$(extract_momentum_height "${last_response}" || true)
    if [[ -n "${initial_height}" ]]; then
      echo "Devnet responded with chain ID ${EXPECTED_CHAIN_ID} at momentum ${initial_height}."
      break
    fi
  fi

  echo "Waiting for devnet chain ID ${EXPECTED_CHAIN_ID} (${attempt}/${MAX_ATTEMPTS})..."
  sleep "${SLEEP_SECONDS}"
done

if [[ -z "${initial_height:-}" ]]; then
  echo "Timed out waiting for devnet at ${DEVNET_HTTP_URL} with chain ID ${EXPECTED_CHAIN_ID}."
  echo "Last response: ${last_response}"
  exit 1
fi

for attempt in $(seq 1 "${MAX_ATTEMPTS}"); do
  if last_response=$(rpc_call "${SYNC_INFO_PAYLOAD}" 2>&1) &&
    is_sync_done "${last_response}"; then
    echo "Devnet sync is done."
    break
  fi

  echo "Waiting for devnet sync done (${attempt}/${MAX_ATTEMPTS})..."
  sleep "${SLEEP_SECONDS}"
done

if ! is_sync_done "${last_response}"; then
  echo "Timed out waiting for devnet sync done at ${DEVNET_HTTP_URL}."
  echo "Last response: ${last_response}"
  exit 1
fi

for attempt in $(seq 1 "${MAX_ATTEMPTS}"); do
  if last_response=$(rpc_call "${FRONTIER_MOMENTUM_PAYLOAD}" 2>&1) &&
    has_expected_chain_id "${last_response}"; then
    current_height=$(extract_momentum_height "${last_response}" || true)
    if [[ -n "${current_height}" && "${current_height}" -gt "${initial_height}" ]]; then
      echo "Devnet is ready at ${DEVNET_HTTP_URL}; momentum advanced from ${initial_height} to ${current_height}."
      exit 0
    fi
  fi

  echo "Waiting for a fresh devnet momentum after ${initial_height} (${attempt}/${MAX_ATTEMPTS})..."
  sleep "${SLEEP_SECONDS}"
done

echo "Timed out waiting for a fresh devnet momentum after ${initial_height}."
echo "Last response: ${last_response}"
exit 1
