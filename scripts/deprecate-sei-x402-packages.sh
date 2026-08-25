#!/usr/bin/env bash
#
# Deprecates the retired @sei-js x402 packages on npm.
#
# Sei is supported natively in the upstream x402 SDK, so this fork is retired.
# See MIGRATION.md for the user-facing migration path.
#
# Requires an npm login with publish rights on the @sei-js scope.
#
# Usage:
#   ./scripts/deprecate-sei-x402-packages.sh            # apply
#   DRY_RUN=1 ./scripts/deprecate-sei-x402-packages.sh  # print only

set -euo pipefail

DRY_RUN="${DRY_RUN:-0}"
GUIDE="https://github.com/sei-protocol/x402/blob/main/MIGRATION.md"

# Shared caveat for the packages that resolve a Sei mainnet default asset. The
# fork points chain 1329 at an IBC-bridged USDC with no EIP-3009 support, so the
# exact scheme cannot settle against it.
USDC_NOTE="It also defaults Sei mainnet to a bridged USDC without EIP-3009 support, so 'exact' payments cannot settle."

deprecate() {
  local pkg="$1"
  local replacement="$2"
  local note="${3:-}"

  local msg="Deprecated and unmaintained. Sei is now supported natively upstream: use ${replacement} instead."
  if [[ -n "$note" ]]; then
    msg="${msg} ${note}"
  fi
  msg="${msg} Migration guide: ${GUIDE}"

  if [[ "$DRY_RUN" == "1" ]]; then
    printf 'DRY RUN  %s\n         -> %s\n\n' "$pkg" "$msg"
    return
  fi

  echo "Deprecating ${pkg} ..."
  npm deprecate "${pkg}@*" "$msg"
}

if [[ "$DRY_RUN" != "1" ]]; then
  if ! npm whoami >/dev/null 2>&1; then
    echo "error: not authenticated to npm. Run 'npm login' first." >&2
    exit 1
  fi
  echo "Authenticated as $(npm whoami)."
  echo
fi

deprecate "@sei-js/x402"         "@x402/core and @x402/evm" "$USDC_NOTE"
deprecate "@sei-js/x402-fetch"   "@x402/fetch"              "$USDC_NOTE"
deprecate "@sei-js/x402-axios"   "@x402/axios"              "$USDC_NOTE"
deprecate "@sei-js/x402-express" "@x402/express"            "$USDC_NOTE"
deprecate "@sei-js/x402-hono"    "@x402/hono"               "$USDC_NOTE"
deprecate "@sei-js/x402-next"    "@x402/next"               "$USDC_NOTE"
deprecate "@sei-js/coinbase-x402" "@coinbase/x402"

echo
echo "Done. Verify with:"
echo "  npm view @sei-js/x402 deprecated"
