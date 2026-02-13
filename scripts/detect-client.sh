#!/usr/bin/env bash
# Detects installed torrent clients and outputs JSON.
# Usage: ./detect-client.sh

set -euo pipefail

# --- OS Detection ---
os_name=$(uname -s)
distro="unknown"

case "$os_name" in
  Linux)
    if [ -f /etc/os-release ]; then
      # shellcheck source=/dev/null
      distro=$(. /etc/os-release && echo "${ID:-unknown}")
    fi
    ;;
  Darwin)
    distro="macos"
    ;;
  MINGW*|MSYS*|CYGWIN*)
    os_name="Windows"
    distro="windows"
    ;;
esac

# --- Client Detection ---

# Transmission
transmission_path=$(command -v transmission-remote 2>/dev/null || true)
transmission_installed="false"
transmission_daemon="false"
if [ -n "$transmission_path" ]; then
  transmission_installed="true"
  if transmission-remote -l >/dev/null 2>&1; then
    transmission_daemon="true"
  fi
fi

# aria2
aria2_path=$(command -v aria2c 2>/dev/null || true)
aria2_installed="false"
aria2_daemon="false"
if [ -n "$aria2_path" ]; then
  aria2_installed="true"
  if curl -sf http://localhost:6800/jsonrpc -d '{"jsonrpc":"2.0","id":"test","method":"aria2.getVersion"}' >/dev/null 2>&1; then
    aria2_daemon="true"
  fi
fi

# --- Preferred Client ---
preferred="none"
if [ "$transmission_installed" = "true" ]; then
  preferred="transmission"
elif [ "$aria2_installed" = "true" ]; then
  preferred="aria2"
fi

# --- JSON Output ---
cat <<EOF
{
  "os": "$os_name",
  "distro": "$distro",
  "clients": {
    "transmission": {
      "installed": $transmission_installed,
      "path": $([ -n "$transmission_path" ] && echo "\"$transmission_path\"" || echo "null"),
      "daemonRunning": $transmission_daemon
    },
    "aria2": {
      "installed": $aria2_installed,
      "path": $([ -n "$aria2_path" ] && echo "\"$aria2_path\"" || echo "null"),
      "daemonRunning": $aria2_daemon
    }
  },
  "preferred": "$preferred"
}
EOF
