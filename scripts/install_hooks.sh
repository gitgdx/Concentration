#!/bin/sh
# Installe les hooks git versionnés du dépôt (à exécuter une fois par clone).
# Usage : sh scripts/install_hooks.sh
set -e

cd "$(dirname "$0")/.."

git config core.hooksPath scripts/githooks

# Git for Windows exécute les hooks via sh ; le bit exécutable est requis sur Unix.
chmod +x scripts/githooks/pre-commit scripts/githooks/commit-msg scripts/githooks/pre-push 2>/dev/null || true

echo "✅ core.hooksPath → scripts/githooks"
echo "   Hooks actifs : pre-commit (traçabilité + SCB + secrets), commit-msg (convention + trailer US), pre-push (branche principale interdite)"
