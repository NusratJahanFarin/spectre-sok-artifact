#!/bin/bash
# Fetch the BinSec/Haunted docker image pinned by DOI 10.5281/zenodo.4442337.
# Safe to re-run: skips the download if the file already exists and its
# md5 checksum already matches.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILE="binsec-haunted.tar"
URL="https://zenodo.org/records/4442337/files/${FILE}?download=1"
EXPECTED_MD5="0b7e09b6d4a17592a628204fbc12bf4f"

cd "$SCRIPT_DIR"

if [ -f "$FILE" ]; then
    ACTUAL_MD5=$(md5sum "$FILE" | cut -d' ' -f1)
    if [ "$ACTUAL_MD5" = "$EXPECTED_MD5" ]; then
        echo "[=] $FILE already present and checksum OK, skipping download."
        exit 0
    fi
    echo "[!] $FILE exists but checksum doesn't match, re-downloading."
fi

echo "[*] Downloading $FILE (~3.2 GB) from Zenodo..."
curl -L -o "$FILE" "$URL"

ACTUAL_MD5=$(md5sum "$FILE" | cut -d' ' -f1)
if [ "$ACTUAL_MD5" != "$EXPECTED_MD5" ]; then
    echo "[!] Checksum mismatch!" >&2
    echo "    expected: $EXPECTED_MD5" >&2
    echo "    actual:   $ACTUAL_MD5" >&2
    exit 1
fi

echo "[✓] Downloaded and verified $FILE"
echo "    Load it with: docker load -i $FILE"
