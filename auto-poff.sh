#!/usr/bin/env bash

DOWNLOAD_DIR="$HOME/Downloads"

echo "Waiting for downloads to finish..."

while true; do
    sleep 15

    if ! find "$DOWNLOAD_DIR" -type f -name "*.part" | grep -q .; then
        echo "All downloads completed. Shutting down..."
        shutdown now
        break
    fi
done
