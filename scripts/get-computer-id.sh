#!/bin/bash
# Get the computer's MAC address (lowercase, no separators)
# Works on macOS and Linux

if command -v ifconfig &> /dev/null; then
    # macOS
    MAC=$(ifconfig en0 2>/dev/null | grep ether | awk '{print $2}' | tr -d ':')
    if [ -n "$MAC" ]; then
        echo "$MAC"
        exit 0
    fi
    # Try other interfaces
    MAC=$(ifconfig | grep ether | head -1 | awk '{print $2}' | tr -d ':')
    if [ -n "$MAC" ]; then
        echo "$MAC"
        exit 0
    fi
fi

if command -v ip &> /dev/null; then
    # Linux
    MAC=$(cat /sys/class/net/eth0/address 2>/dev/null | tr -d ':')
    if [ -n "$MAC" ]; then
        echo "$MAC"
        exit 0
    fi
    MAC=$(ip link show 2>/dev/null | grep 'link/ether' | head -1 | awk '{print $2}')
    if [ -n "$MAC" ]; then
        echo "$MAC" | tr -d ':'
        exit 0
    fi
fi

echo "unknown"
