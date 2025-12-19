#!/bin/sh

# Define paths
# Current directory (Source Build Root - Read Only)
RO_DIR="$(pwd)"
APP_BIN="$RO_DIR/app"
GEN_KEYS_BIN="$RO_DIR/generate-keys"

# Writable working directory (Leapcell usually allows writing to /tmp)
WORK_DIR="/tmp/dendrite"
mkdir -p "$WORK_DIR"

echo "Initializing Dendrite environment in $WORK_DIR..."

# 1. Prepare Config
# Copy the config to the writable directory so we can run from there (dendrite writes logs/media relative to CWD)
cp "$RO_DIR/dendrite-leapcell.yaml" "$WORK_DIR/dendrite.yaml"

# 2. Generate Keys
# We execute the binary from the RO_DIR, but tell it to write the key to WORK_DIR
if [ ! -f "$WORK_DIR/matrix_key.pem" ]; then
    echo "Generating matrix_key.pem..."
    "$GEN_KEYS_BIN" --private-key "$WORK_DIR/matrix_key.pem"
else
    echo "Key already exists."
fi

# 3. Start Dendrite
# Switch to WORK_DIR so that relative paths (media logs, etc) in the config are created in the writable /tmp
cd "$WORK_DIR" || exit 1

echo "Starting Dendrite server..."
# Run the app binary (absolute path) with the local config in /tmp
# Added --skip-db-sanity because Leapcell/Neon connection pooling often reports 
# max_connections values that confuse Dendrite's safety checks.
exec "$APP_BIN" --config dendrite.yaml --skip-db-sanity
