#!/bin/bash
set -e

echo "Setting up corporate certificate trust..."

CERT_PATH=".devcontainer/certs/zscaler.crt"
USERNAME="${_REMOTE_USER:-node}"
USER_HOME=$(getent passwd "$USERNAME" | cut -d: -f6 2>/dev/null || echo "/home/$USERNAME")

if [ -f "$CERT_PATH" ]; then
    echo "Corporate certificate found"
    
    # Validate certificate format
    if ! openssl x509 -in "$CERT_PATH" -text -noout >/dev/null 2>&1; then
        echo "ERROR: Invalid certificate format in $CERT_PATH"
        exit 1
    fi
    
    # System-level certificate installation
    echo "Installing system certificate..."
    sudo cp "$CERT_PATH" /usr/local/share/ca-certificates/zscaler.crt
    sudo chmod 644 /usr/local/share/ca-certificates/zscaler.crt
    sudo update-ca-certificates
    
    # User-level configuration
    echo "Configuring development tools..."
    mkdir -p "$USER_HOME/.local/share/ca-certificates"
    cp /usr/local/share/ca-certificates/zscaler.crt "$USER_HOME/.local/share/ca-certificates/"
    cat /etc/ssl/certs/ca-certificates.crt "$USER_HOME/.local/share/ca-certificates/zscaler.crt" > \
        "$USER_HOME/.local/share/ca-certificates/combined-ca-bundle.crt"
    
    # Configure tools (with error handling)
    if command -v npm >/dev/null 2>&1; then
        sudo -u "$USERNAME" npm config set cafile "$USER_HOME/.local/share/ca-certificates/combined-ca-bundle.crt" 2>/dev/null || true
    fi
    
    if command -v git >/dev/null 2>&1; then
        sudo -u "$USERNAME" git config --global http.sslCAInfo "$USER_HOME/.local/share/ca-certificates/combined-ca-bundle.crt" 2>/dev/null || true
    fi
    
    # Set environment variables in shell configs
    for shell_rc in "$USER_HOME/.bashrc" "$USER_HOME/.zshrc"; do
        if [ -f "$shell_rc" ] || [ "$shell_rc" = "$USER_HOME/.bashrc" ]; then
            # Remove existing entries to avoid duplicates
            grep -v "combined-ca-bundle.crt" "$shell_rc" > "${shell_rc}.tmp" 2>/dev/null || true
            mv "${shell_rc}.tmp" "$shell_rc" 2>/dev/null || true
            
            # Add certificate environment variables
            {
                echo ""
                echo "# Corporate certificate configuration"
                echo "export SSL_CERT_FILE=$USER_HOME/.local/share/ca-certificates/combined-ca-bundle.crt"
                echo "export REQUESTS_CA_BUNDLE=$USER_HOME/.local/share/ca-certificates/combined-ca-bundle.crt"
                echo "export CURL_CA_BUNDLE=$USER_HOME/.local/share/ca-certificates/combined-ca-bundle.crt"
                echo "export NODE_EXTRA_CA_CERTS=$USER_HOME/.local/share/ca-certificates/combined-ca-bundle.crt"
            } >> "$shell_rc"
        fi
    done
    
    # Fix ownership
    chown -R "$USERNAME:$USERNAME" "$USER_HOME/.local/share/ca-certificates" 2>/dev/null || true
    
    echo "Corporate certificate installed and configured"
    echo "Configured: system CA, Node.js, npm, git"
else
    echo "WARNING: No corporate certificate found at $CERT_PATH"
    echo "To add certificate: copy your root CA to .devcontainer/certs/zscaler.crt"
    echo "Container will work without it, but HTTPS through corporate proxy may fail"
fi

echo "Certificate setup complete!"