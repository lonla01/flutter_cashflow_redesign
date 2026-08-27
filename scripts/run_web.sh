#!/bin/bash

PORT=8080

echo ""
echo "=========================================="
echo "       MoMo Ledger - Flutter Web"
echo "=========================================="
echo ""
echo "Codespace: $CODESPACE_NAME"
echo ""
echo "Remote URL:"
echo "https://${CODESPACE_NAME}-${PORT}.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
echo ""
echo "=========================================="
echo ""

flutter run \
  -d web-server \
  --web-hostname 0.0.0.0 \
  --web-port $PORT
