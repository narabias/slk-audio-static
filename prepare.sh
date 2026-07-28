#!/usr/bin/env sh
set -eu
command -v node >/dev/null 2>&1 || { echo "Node.js 18+ is required."; exit 1; }
npm run setup:vendor
echo "Vendor files prepared."
