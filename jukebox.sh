#!/bin/bash

set -e

if [[ $EUID -ne 0 ]]; then
    echo "Please run as root (required for mounting and unmounting)"
    exit 1
fi

DEVICE="/dev/sr0"
MOUNT_POINT="/mnt/cdrom"

mkdir -p "$MOUNT_POINT"

amixer cset numid=3 1 > /dev/null 2>&1
amixer set Master 50% unmute > /dev/null 2>&1

echo "MIDI CD Jukebox Started"

while true; do
    echo "Waiting for CD..."
    while ! blkid "$DEVICE" > /dev/null 2>&1; do
        sleep 1
    done

    while ! sudo mount "$DEVICE" "$MOUNT_POINT" > /dev/null 2>&1; do
        sleep 1
    done

    echo "CD Mounted at $MOUNT_POINT"

    if ! find "$MOUNT_POINT" -type f -iname "*.mid" -print0 | grep -qz .; then
        echo "No MIDI files found!"
    else
        echo "Playing MIDI files:"
        find "$MOUNT_POINT" -type f -iname "*.mid" -print0 | sort -z | while IFS= read -r -d '' FILE; do
            echo "Playing $FILE"
            ALSA_PCM_CARD=0 fluidsynth -i "$FILE" > /dev/null 2>&1
        done
    fi

    echo "Ejecting CD..."
    sudo umount "$MOUNT_POINT"
    eject "$DEVICE"

    while blkid "$DEVICE" > /dev/null 2>&1; do
        sleep 1
    done
done
