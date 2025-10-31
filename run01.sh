#!/bin/bash
set -e

install_dir="/home/elitesec/"
archive_file="kali-linux-2025.2-qemu-amd64.7z"
kali_qcow="${install_dir}/kali-linux-2025.2-qemu-amd64.qcow2"

mkdir -p "$install_dir"

if [ ! -f "$kali_qcow" ]; then
    if [ ! -f "$archive_file" ] || ! file "$archive_file" | grep -q "7-zip"; then
        echo "Downloading $archive_file"
        
        rm -f "$archive_file"
        
        wget "https://cdimage.kali.org/kali-2025.2/$archive_file" || {
            echo "Download failed! Please check your internet connection"
            exit 1
        }
        
        echo "Download complete!"
    fi
    
    if ! pip show py7zr &> /dev/null; then
        echo "Installing py7zr"
        pip install py7zr --break-system-packages
    fi
    
    echo "Extracting $archive_file"
    python3 -m py7zr x "$archive_file" || {
        echo "Extraction failed! The archive might be corrupted."
        echo "Removing corrupted file..."
        rm -f "$archive_file"
        exit 1
    }
    
    if [ -f "kali-linux-2025.2-qemu-amd64.qcow2" ]; then
        mv "kali-linux-2025.2-qemu-amd64.qcow2" "$kali_qcow"
    fi
    
    echo "Extraction complete!"
    
    rm -f "$archive_file"
    
    if [ -f "run01.sh" ]; then
        cp run01.sh ~/run.sh
        chmod u+x ~/run.sh
    else
        echo "Warning: run01.sh not found"
    fi
fi

if [ ! -f "$kali_qcow" ]; then
    echo "Error: QEMU image not found at $kali_qcow"
    exit 1
fi

IMAGE_PATH="$kali_qcow"
SSHPORT=2222

echo "Starting Kali Linux VM..."
qemu-system-x86_64 \
    -display gtk,zoom-to-fit=on,grab-on-hover=on,window-close=off \
    -cpu host \
    -full-screen \
    -enable-kvm \
    -netdev user,id=hostnet0,hostfwd=tcp::${SSHPORT}-:22 \
    -usb -device qemu-xhci,id=xhci -device usb-mouse -device usb-kbd \
    -device virtio-vga \
    -device intel-hda \
    -device hda-duplex \
    -device virtio-net,netdev=hostnet0 \
    -m 12G \
    -smp 20 \
    -daemonize \
    "${IMAGE_PATH}"