#!/usr/bin/env bash

set -euo pipefail

DEVNET_HTTP_URL="${ZNN_TEST_HTTP_URL:-http://127.0.0.1:35997}"
EXPECTED_CHAIN_ID="${ZNN_TEST_CHAIN_ID:-69}"
MAX_ATTEMPTS="${ZNN_TEST_DEVNET_WAIT_ATTEMPTS:-5}"
SLEEP_SECONDS="${ZNN_TEST_DEVNET_WAIT_SLEEP_SECONDS:-2}"
PAYLOAD='{"jsonrpc":"2.0","id":1,"method":"ledger.getFrontierMomentum","params":[]}'

last_response=""

for attempt in $(seq 1 "${MAX_ATTEMPTS}"); do
  if last_response=$(curl -fsS \
    -H 'Content-Type: application/json' \
    -d "${PAYLOAD}" \
    "${DEVNET_HTTP_URL}" 2>&1); then
    case "${last_response}" in
      *'"chainIdentifier":'"${EXPECTED_CHAIN_ID}"*|*'"chainIdentifier": '"${EXPECTED_CHAIN_ID}"*)
        echo "Devnet is ready at ${DEVNET_HTTP_URL} with chain ID ${EXPECTED_CHAIN_ID}."
        exit 0
        ;;
    esac
  fi

  echo "Waiting for devnet (${attempt}/${MAX_ATTEMPTS})..."
  sleep "${SLEEP_SECONDS}"
done

echo "Timed out waiting for devnet at ${DEVNET_HTTP_URL} with chain ID ${EXPECTED_CHAIN_ID}."
echo "Last response: ${last_response}"
exit 1
