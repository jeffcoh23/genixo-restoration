#!/usr/bin/env bash
# Generate the Android upload keystore for Play App Signing.
#
# Run this ONCE from `mobile/`:
#   ./scripts/generate-android-keystore.sh
#
# You'll be prompted for a password. Save it to 1Password — losing it means
# you can't ship updates to the Play Console upload track until you ask
# Google to reset the upload key (possible, but painful).

set -euo pipefail

KEYSTORE_DIR="android/keystore"
KEYSTORE_PATH="$KEYSTORE_DIR/genixo-upload.jks"
KEY_ALIAS="genixo-upload"

if [ -f "$KEYSTORE_PATH" ]; then
  echo "Keystore already exists at $KEYSTORE_PATH"
  echo "Refusing to overwrite. Delete it manually if you really want to regenerate."
  exit 1
fi

mkdir -p "$KEYSTORE_DIR"

echo "Generating upload keystore for com.genixo.restoration ..."
echo "Use the SAME password for both the keystore and the key alias when prompted."
echo

keytool -genkeypair \
  -v \
  -keystore "$KEYSTORE_PATH" \
  -alias "$KEY_ALIAS" \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -dname "CN=Genixo Restoration, O=Genixo, L=Charlotte, ST=NC, C=US"

echo
echo "Keystore written: $KEYSTORE_PATH"
echo
echo "Next steps:"
echo "  1. Copy the .jks file + password to 1Password right now."
echo "  2. Copy keystore.properties.example -> keystore.properties and fill in the passwords."
echo "  3. Run: keytool -list -v -keystore $KEYSTORE_PATH -alias $KEY_ALIAS"
echo "     Capture the SHA-256 fingerprint and share it with Claude to wire into assetlinks.json."
