#!/bin/bash
# Pre-create hook - runs during devcontainer creation
# Configures SSL certificates at user level (no sudo required)

echo "Running pre-create setup..."

# Auto-detect and install corporate certificates from host
if [ -f "${localEnv:HOME}/.ssl/certs/zscaler.crt" ]; then
    echo "Found corporate certificate, configuring for user..."
    
    # Create user certificate directory
    mkdir -p ~/.local/share/ca-certificates
    cp "${localEnv:HOME}/.ssl/certs/zscaler.crt" ~/.local/share/ca-certificates/
    
    # Create combined certificate bundle for user
    cat /etc/ssl/certs/ca-certificates.crt ~/.local/share/ca-certificates/zscaler.crt > ~/.local/share/ca-certificates/combined-ca-bundle.crt 2>/dev/null || true
    
    # Configure npm (user-level)
    npm config set cafile ~/.local/share/ca-certificates/combined-ca-bundle.crt
    
    # Configure git (user-level)
    git config --global http.sslCAInfo ~/.local/share/ca-certificates/combined-ca-bundle.crt
    
    # Set environment variables for other tools
    echo 'export SSL_CERT_FILE=~/.local/share/ca-certificates/combined-ca-bundle.crt' >> ~/.bashrc
    echo 'export REQUESTS_CA_BUNDLE=~/.local/share/ca-certificates/combined-ca-bundle.crt' >> ~/.bashrc
    echo 'export CURL_CA_BUNDLE=~/.local/share/ca-certificates/combined-ca-bundle.crt' >> ~/.bashrc
    echo 'export NODE_EXTRA_CA_CERTS=~/.local/share/ca-certificates/combined-ca-bundle.crt' >> ~/.bashrc
    
    # Also add to zsh if available
    if [ -f ~/.zshrc ]; then
        echo 'export SSL_CERT_FILE=~/.local/share/ca-certificates/combined-ca-bundle.crt' >> ~/.zshrc
        echo 'export REQUESTS_CA_BUNDLE=~/.local/share/ca-certificates/combined-ca-bundle.crt' >> ~/.zshrc
        echo 'export CURL_CA_BUNDLE=~/.local/share/ca-certificates/combined-ca-bundle.crt' >> ~/.zshrc
        echo 'export NODE_EXTRA_CA_CERTS=~/.local/share/ca-certificates/combined-ca-bundle.crt' >> ~/.zshrc
    fi
    
    echo "Corporate certificate configured for all dev tools (user-level)"
else
    echo "No corporate certificate found, using default SSL configuration"
fi

echo "Pre-create setup complete!"