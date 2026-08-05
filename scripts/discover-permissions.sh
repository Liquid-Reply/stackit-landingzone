#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Discover all STACKIT permissions via the Authorization API
#
# Prerequisites:
#   - stackit CLI installed and authenticated (stackit auth login)
#
# Usage:
#   ./scripts/discover-permissions.sh                  # list ALL permissions
#   ./scripts/discover-permissions.sh project           # filter by resource type
#   ./scripts/discover-permissions.sh project publicip   # grep for a keyword
# ---------------------------------------------------------------------------
set -euo pipefail

RESOURCE_TYPE="${1:-}"
FILTER="${2:-}"

URL="https://authorization.api.stackit.cloud/v2/permissions"
if [[ -n "$RESOURCE_TYPE" ]]; then
  URL="${URL}?resourceType=${RESOURCE_TYPE}"
fi

echo "Fetching permissions from: $URL" >&2

RESPONSE=$(stackit curl "$URL" 2>/dev/null)

if [[ -n "$FILTER" ]]; then
  echo "$RESPONSE" | jq -r '.permissions[] | "\(.name)\t\(.description)"' | grep -i "$FILTER"
else
  echo "$RESPONSE" | jq -r '.permissions[] | "\(.name)\t\(.description)"'
fi
