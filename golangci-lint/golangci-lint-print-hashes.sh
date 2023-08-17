#!/usr/bin/env nix-shell
#! nix-shell -i bash -p curl jq
# shellcheck shell=bash
set -euo pipefail

VERSION=${1:-}
BASEURL=https://github.com/golangci/golangci-lint/releases/download/v${VERSION}/golangci-lint-${VERSION}-checksums.txt

if [[ -z ${VERSION} ]]; then
  echo "No version supplied"
  exit 1
fi

wget -q -O /tmp/checksums.txt "${BASEURL}"

while read -r line
do
sum=$(echo $line | cut -d ' ' -f1)
file=$(echo $line | cut -d ' ' -f2 | sed -E 's/golangci-lint-[[:digit:].]*-([[:alnum:]-]*).*/\1/')
hash=$(echo $sum | xxd -r -p | base64)
echo "$file = sha256-$(echo $hash)"
done < "/tmp/checksums.txt"

rm /tmp/checksums.txt
