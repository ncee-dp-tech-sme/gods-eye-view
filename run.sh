#!/usr/bin/env sh
# run.sh — one-command launcher for the God's Eye View container
# Changed: Tue Sep  1 00:00:00 CEST 2026 — initial file
# Changed: Tue Sep  1 00:00:00 CEST 2026 — rewritten for Bash + ZSH compatibility (POSIX sh shebang,
#           removed BASH_SOURCE, BASH_REMATCH, empty-array expansion under set -u,
#           and boolean-command anti-pattern)
#
# ─────────────────────────────────────────────────────────────────────────────
# What this script does (plain English):
#
#   1. Checks that Podman (or Docker) is installed.
#   2. Checks that your .env file exists and contains the required Google Maps key.
#   3. Builds the container image (this takes a few minutes the first time;
#      subsequent builds are much faster because unchanged steps are cached).
#   4. Starts the container, forwarding port 4173 to your machine.
#   5. Prints the URL to open in your browser and waits until you press Ctrl+C.
#
# Usage:
#   ./run.sh            — build (if needed) and start
#   ./run.sh --rebuild  — force a full rebuild of the image before starting
#   ./run.sh --stop     — stop a running container
# ─────────────────────────────────────────────────────────────────────────────
set -eu

IMAGE_NAME="gods-eye-view"
CONTAINER_NAME="gods-eye-view-dev"
PORT="${PORT:-4173}"
ENV_FILE=".env"
# Resolve script directory in a way that works in both Bash and ZSH.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "${SCRIPT_DIR}"

# ── Colour helpers ────────────────────────────────────────────────────────────
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
info()    { printf "${CYAN}▶${NC} %s\n" "$*"; }
success() { printf "${GREEN}✔${NC} %s\n" "$*"; }
warn()    { printf "${YELLOW}⚠${NC}  %s\n" "$*" >&2; }
error()   { printf "${RED}✖${NC}  %s\n" "$*" >&2; }

# ── Detect container runtime ──────────────────────────────────────────────────
if command -v podman >/dev/null 2>&1; then
  RUNTIME="podman"
elif command -v docker >/dev/null 2>&1; then
  RUNTIME="docker"
else
  error "Neither Podman nor Docker is installed."
  echo  "  Install Podman: https://podman.io/getting-started/installation"
  exit 1
fi
info "Using container runtime: ${RUNTIME}"

# ── Handle --stop ─────────────────────────────────────────────────────────────
if [ "${1:-}" = "--stop" ]; then
  if "${RUNTIME}" ps --format '{{.Names}}' 2>/dev/null | grep -q "^${CONTAINER_NAME}$"; then
    info "Stopping container '${CONTAINER_NAME}'..."
    "${RUNTIME}" stop "${CONTAINER_NAME}"
    success "Container stopped."
  else
    warn "No running container named '${CONTAINER_NAME}' found."
  fi
  exit 0
fi

# ── Check .env ────────────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
info "Checking configuration..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ ! -f "${ENV_FILE}" ]; then
  error "No .env file found."
  echo ""
  echo "  You need to create a .env file with your API keys before starting."
  echo "  The quickest way:"
  echo ""
  echo "    cp .env.example .env"
  echo "    # then open .env in a text editor and fill in GOOGLE_MAPS_API_KEY"
  echo ""
  echo "  See README.md for a step-by-step guide to getting your keys."
  exit 1
fi

# Read a key's value from .env without sourcing the file as shell code.
# Usage: read_env_key KEY  → prints value, or empty string if not found/commented.
read_env_key() {
  local _key="$1"
  local _val=""
  # grep for the first uncommented assignment, then strip the key= prefix and any quotes.
  _val="$(grep -m1 "^${_key}=" "${ENV_FILE}" 2>/dev/null | cut -d'=' -f2- || true)"
  # Strip surrounding double or single quotes
  _val="${_val%\"}" ; _val="${_val#\"}"
  _val="${_val%\'}" ; _val="${_val#\'}"
  printf '%s' "${_val}"
}

MAPS_KEY="$(read_env_key "GOOGLE_MAPS_API_KEY")"

if [ -z "${MAPS_KEY}" ] || [ "${MAPS_KEY}" = "your_google_maps_api_key_here" ]; then
  error "GOOGLE_MAPS_API_KEY is not set in your .env file."
  echo ""
  echo "  The Google Maps key is the only required key — without it the 3D"
  echo "  globe will not load.  See SETUP.md Step 1 for instructions."
  exit 1
fi

success ".env found with Google Maps API key."

# Warn about optional keys that are missing (informational only — not fatal).
check_optional_key() {
  local _key="$1" _label="$2" _guide="$3"
  local _val
  _val="$(read_env_key "${_key}")"
  if [ -z "${_val}" ]; then
    warn "${_label} not set — ${_guide}"
  else
    success "${_label} configured."
  fi
}
check_optional_key "CESIUM_ION_TOKEN"  "Cesium Ion token"  "Bing map stacks will be unavailable (optional)"
check_optional_key "OPENAI_API_KEY"    "OpenAI key"        "Voice control + AI HUD summary disabled (optional)"
check_optional_key "AISSTREAM_API_KEY" "AISStream key"     "Live ships layer will be empty (optional)"
check_optional_key "TOMTOM_API_KEY"    "TomTom key"        "Traffic shows simulation instead of live data (optional)"
check_optional_key "FIRMS_MAP_KEY"     "NASA FIRMS key"    "Active fires layer disabled (optional)"

# ── Stop any previous instance ────────────────────────────────────────────────
if "${RUNTIME}" ps --format '{{.Names}}' 2>/dev/null | grep -q "^${CONTAINER_NAME}$"; then
  info "Stopping previous container instance..."
  "${RUNTIME}" stop "${CONTAINER_NAME}" >/dev/null
fi

# ── Build ─────────────────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
info "Building container image '${IMAGE_NAME}'..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  The first build downloads the base image and installs all JavaScript"
echo "  dependencies.  This normally takes 3-8 minutes depending on your"
echo "  internet speed.  Subsequent builds reuse cached layers and finish"
echo "  in under a minute."
echo ""

# Build the image.
# --no-cache is added only when --rebuild is passed; otherwise the positional
# parameter is absent and we pass nothing extra — avoiding the empty-array
# expansion problem that breaks under set -u in both Bash and ZSH.
if [ "${1:-}" = "--rebuild" ]; then
  "${RUNTIME}" build --no-cache --format docker \
    -f Containerfile -t "${IMAGE_NAME}:latest" .
else
  "${RUNTIME}" build --format docker \
    -f Containerfile -t "${IMAGE_NAME}:latest" .
fi

success "Image built successfully."

# ── Run ───────────────────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
info "Starting God's Eye View on http://localhost:${PORT} ..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# --rm          removes the container when it stops (keeps things tidy)
# --name        gives the container a stable name so --stop works
# -p 4173:4173  maps the container's port 4173 to your machine's port 4173
# --env-file    injects all the keys from your .env file at run time
#               (the image itself never contains your keys)
"${RUNTIME}" run \
  --rm \
  --name "${CONTAINER_NAME}" \
  -p "${PORT}:${PORT}" \
  --env-file "${ENV_FILE}" \
  "${IMAGE_NAME}:latest" &

CONTAINER_PID=$!

# ── Wait for health check to pass ────────────────────────────────────────────
echo ""
echo "  Waiting for the dev server to be ready..."
READY="false"
i=0
while [ "${i}" -lt 30 ]; do
  sleep 2
  i=$((i + 1))
  STATUS=$("${RUNTIME}" inspect --format '{{.State.Health.Status}}' "${CONTAINER_NAME}" 2>/dev/null || echo "starting")
  if [ "${STATUS}" = "healthy" ]; then
    READY="true"
    break
  fi
  printf "  (%ds elapsed)\r" "$((i * 2))"
done
echo ""

if [ "${READY}" = "true" ]; then
  success "Server is ready!"
else
  warn "Health check has not passed yet — the server may still be starting up."
  warn "Try opening the URL in a few more seconds."
fi

echo ""
echo "  ┌─────────────────────────────────────────────────────┐"
echo "  │                                                     │"
printf "  │   ${GREEN}Open in your browser:${NC}                              │\n"
echo "  │                                                     │"
printf "  │   ${CYAN}http://localhost:${PORT}${NC}                         │\n"
echo "  │                                                     │"
echo "  │   Press Ctrl+C to stop the container.              │"
echo "  │                                                     │"
echo "  └─────────────────────────────────────────────────────┘"
echo ""

# Keep the script alive (the container is running in the background).
wait "${CONTAINER_PID}" 2>/dev/null || true

echo ""
info "Container stopped.  Run './run.sh' again to restart."
