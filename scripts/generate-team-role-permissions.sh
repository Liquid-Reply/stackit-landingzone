#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Generate the permissions list for the "team-editor" custom role
#
# Fetches ALL project-level permissions from the STACKIT Authorization API,
# then removes the ones listed in DENIED_PERMISSIONS below.
#
# Output: a Terraform-compatible list that can be pasted into
#         modules/custom-role/team-editor-permissions.auto.tfvars
#
# Prerequisites:
#   - stackit CLI installed and authenticated (stackit auth login)
#
# Usage:
#   ./scripts/generate-team-role-permissions.sh
#   ./scripts/generate-team-role-permissions.sh > team-editor-permissions.auto.tfvars
# ---------------------------------------------------------------------------
set -euo pipefail

# ── Permissions to DENY (add more as needed) ──────────────────────────────
#
# Run ./scripts/discover-permissions.sh project publicip  to find the exact
# permission names in your environment.
#
DENIED_PERMISSIONS=(
  # Public IP - prevent teams from exposing workloads directly to the internet
  "iaas.public-ip.create"
  "iaas.public-ip.delete"
  "iaas.public-ip.update"

  # Server public IP association - prevent attaching/detaching public IPs on VMs
  "iaas.server.public-ip.add"
  "iaas.server.public-ip.remove"

  # Security groups - prevent teams from modifying SG rules (cross-env isolation)
  "iaas.security-group.create"
  "iaas.security-group.delete"
  "iaas.security-group.update"
  "iaas.security-group.rule.create"
  "iaas.security-group.rule.delete"
  "iaas.security-group.rule.update"

  # IAM - prevent teams from escalating their own permissions
  "iam.member.add"
  "iam.member.remove"
  "iam.role.add"
  "iam.role.edit"
  "iam.role.remove"

  # Service accounts - prevent teams from creating SAs that could escalate privileges
  "iam.service-account.create"
  "iam.service-account.delete"
  "iam.service-account.impersonate"
  "iam.service-account.act-as"
  "iam.service-account-key.create"
  "iam.service-account-key.delete"
  "iam.service-account-key.edit"
  "iam.service-account-federation.create"
  "iam.service-account-federation.delete"
  "iam.service-account-federation.edit"
  "iam.service-account-token.create"
  "iam.service-account-token.delete"

  # Project metadata controls SNA attachment and must remain platform-owned.
  "resource-manager.project.delete"
  "resource-manager.project.edit"
  "resource-manager.resource.project.edit"

  # VPN lifecycle is managed exclusively by the platform network layer.
  "vpn.connection.add"
  "vpn.connection.remove"
  "vpn.connection.update"
  "vpn.gateway.create"
  "vpn.gateway.delete"
  "vpn.gateway.update"
)

echo "Fetching all project-level permissions..." >&2

ALL_PERMISSIONS=$(
  stackit curl "https://authorization.api.stackit.cloud/v2/permissions?resourceType=project" 2>/dev/null \
    | jq -r '.permissions[].name'
)

# Build a grep pattern from denied list
DENY_PATTERN=$(printf "%s\n" "${DENIED_PERMISSIONS[@]}")

# Filter out denied permissions
ALLOWED=$(echo "$ALL_PERMISSIONS" | grep -vxF "$DENY_PATTERN" || true)

COUNT_ALL=$(echo "$ALL_PERMISSIONS" | wc -l | tr -d ' ')
COUNT_DENIED=${#DENIED_PERMISSIONS[@]}
COUNT_ALLOWED=$(echo "$ALLOWED" | wc -l | tr -d ' ')

echo "Total permissions:   $COUNT_ALL" >&2
echo "Denied permissions:  $COUNT_DENIED" >&2
echo "Allowed permissions: $COUNT_ALLOWED" >&2
echo "" >&2

# Output as Terraform variable
echo 'team_editor_permissions = ['
echo "$ALLOWED" | while read -r perm; do
  echo "  \"$perm\","
done
echo ']'
