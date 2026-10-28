#!/usr/bin/env bash
# ==============================================================================
# DevOps Lab: Inter-VM Connectivity & Private DNS Verification Script
# Run this script inside VM2 (vm-app-02) to verify connectivity to VM1 (vm-web-01)
# ==============================================================================

set -euo pipefail

TARGET_IP="10.0.1.4"
TARGET_FQDN="web.corp.internal"
TARGET_PORT="80"

echo "============================================================"
echo "🧪 Starting DevOps Lab Verification from $(hostname)"
echo "Target VM1 IP:   $TARGET_IP"
echo "Target VM1 FQDN: $TARGET_FQDN"
echo "============================================================"

# Test 1: Direct ICMP Ping to VM1 Private IP
echo ""
echo "▶ [Test 1/3] Testing Ping to VM1 Private IP ($TARGET_IP)..."
if ping -c 4 "$TARGET_IP" > /dev/null 2>&1; then
    echo "✅ [SUCCESS] ICMP Ping to IP $TARGET_IP succeeded!"
else
    echo "❌ [FAILED] Unable to ping $TARGET_IP. Check NSG rules."
fi

# Test 2: DNS Resolution & Ping to VM1 via Azure Private DNS Zone
echo ""
echo "▶ [Test 2/3] Testing DNS Resolution & Ping to FQDN ($TARGET_FQDN)..."
if ping -c 4 "$TARGET_FQDN" > /dev/null 2>&1; then
    RESOLVED_IP=$(getent hosts "$TARGET_FQDN" | awk '{print $1}')
    echo "✅ [SUCCESS] Private DNS resolved $TARGET_FQDN to $RESOLVED_IP and Ping succeeded!"
else
    echo "❌ [FAILED] Unable to resolve or ping $TARGET_FQDN. Check Private DNS Zone link."
fi

# Test 3: HTTP Request to VM1 Nginx Server
echo ""
echo "▶ [Test 3/3] Testing HTTP Curl to Nginx on VM1 (http://$TARGET_FQDN)..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://$TARGET_FQDN" || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ [SUCCESS] HTTP GET returned 200 OK from Nginx web server!"
    echo "--- Server Response Snippet ---"
    curl -s "http://$TARGET_FQDN" | head -n 15
else
    echo "❌ [FAILED] HTTP request failed with code: $HTTP_CODE. Check if Nginx is running."
fi

echo ""
echo "============================================================"
echo "🎉 Lab Verification Complete!"
echo "============================================================"
