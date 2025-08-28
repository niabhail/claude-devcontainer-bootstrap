#!/bin/bash
set -e

echo "Setting up egress control firewall..."

ALLOWLIST_PATH="/workspaces/${LOCAL_WORKSPACE_FOLDER}/docs/firewall-allowlist.txt"
FALLBACK_ALLOWLIST_PATH="docs/firewall-allowlist.txt"

# Try to find allowlist file
if [ -f "$ALLOWLIST_PATH" ]; then
    ACTIVE_ALLOWLIST="$ALLOWLIST_PATH"
elif [ -f "$FALLBACK_ALLOWLIST_PATH" ]; then
    ACTIVE_ALLOWLIST="$FALLBACK_ALLOWLIST_PATH"
else
    echo "WARNING: No firewall allowlist found"
    echo "Firewall rules will not be applied"
    echo "Expected locations:"
    echo "  - $ALLOWLIST_PATH"
    echo "  - $FALLBACK_ALLOWLIST_PATH"
    exit 0
fi

echo "Using allowlist: $ACTIVE_ALLOWLIST"

# Check if we have required capabilities
if ! iptables -L INPUT >/dev/null 2>&1; then
    echo "ERROR: Cannot access iptables. Container may be missing NET_ADMIN capability"
    echo "Add this to devcontainer.json runArgs: \"--cap-add=NET_ADMIN\", \"--cap-add=NET_RAW\""
    exit 1
fi

# Flush existing rules
echo "Flushing existing iptables rules..."
iptables -F OUTPUT 2>/dev/null || true
iptables -F INPUT 2>/dev/null || true

# Set default policies
echo "Setting default firewall policies..."
iptables -P OUTPUT DROP
iptables -P INPUT DROP
iptables -P FORWARD DROP

# Allow loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Allow established connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow essential services
echo "Allowing essential services..."

# DNS
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT

# HTTP/HTTPS for package managers
iptables -A OUTPUT -p tcp --dport 80 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT

# SSH (for git over SSH)
iptables -A OUTPUT -p tcp --dport 22 -j ACCEPT

# Process allowlist file
echo "Processing allowlist entries..."
if [ -f "$ACTIVE_ALLOWLIST" ]; then
    while IFS= read -r line; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        
        # Extract domain/IP and optional port
        domain=$(echo "$line" | awk '{print $1}')
        port=$(echo "$line" | awk '{print $2}')
        
        if [[ -n "$domain" ]]; then
            if [[ "$domain" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                # IP address
                if [[ -n "$port" ]]; then
                    iptables -A OUTPUT -d "$domain" -p tcp --dport "$port" -j ACCEPT
                else
                    iptables -A OUTPUT -d "$domain" -j ACCEPT
                fi
            else
                # Domain name - resolve and allow
                if command -v nslookup >/dev/null 2>&1; then
                    ips=$(nslookup "$domain" | awk '/^Address: / { print $2 }' | grep -v '#')
                    for ip in $ips; do
                        if [[ -n "$port" ]]; then
                            iptables -A OUTPUT -d "$ip" -p tcp --dport "$port" -j ACCEPT
                        else
                            iptables -A OUTPUT -d "$ip" -j ACCEPT
                        fi
                    done
                fi
            fi
            echo "Allowed: $domain${port:+ :$port}"
        fi
    done < "$ACTIVE_ALLOWLIST"
fi

# Allow internal container communication
iptables -A OUTPUT -d 10.0.0.0/8 -j ACCEPT
iptables -A OUTPUT -d 172.16.0.0/12 -j ACCEPT  
iptables -A OUTPUT -d 192.168.0.0/16 -j ACCEPT

# Allow GitHub (essential for development)
github_ips="140.82.112.0/20 192.30.252.0/22 185.199.108.0/22"
for ip_range in $github_ips; do
    iptables -A OUTPUT -d "$ip_range" -j ACCEPT
done

echo "Firewall rules applied successfully"
echo "Egress control is now active"

# Optional: Show active rules summary
echo "Active OUTPUT rules:"
iptables -L OUTPUT -n | head -20