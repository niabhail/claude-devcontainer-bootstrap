#!/usr/bin/env bash
set -e

# --- Install certificate management tools FIRST ---
echo "[core-devtools] Installing certificate management tools..."
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y ca-certificates openssl curl

# --- Install firewall tools for enterprise security ---
echo "[core-devtools] Installing firewall tools..."
apt-get install -y iptables ipset dnsutils jq aggregate

echo "[core-devtools] Installing selected developer tools..."

USER_HOME=$(getent passwd $USERNAME | cut -d: -f6)

# --- Install selected npm CLIs ---
if [ "${_OPTION_INSTALLTASKMASTER}" = "true" ]; then
  sudo -u $USERNAME npm install -g task-master-ai
fi
if [ "${_OPTION_INSTALLDEVCONTAINERSCLI}" = "true" ]; then
  sudo -u $USERNAME npm install -g @devcontainers/cli
fi

# --- Git-delta block (Debian example; customize for your stack) ---
if [ "${_OPTION_INSTALLGITDELTA}" = "true" ]; then
  ARCH=$(dpkg --print-architecture)
  export DEBIAN_FRONTEND=noninteractive
  GIT_DELTA_VERSION="0.18.2"
  wget -q "https://github.com/dandavison/delta/releases/download/${GIT_DELTA_VERSION}/git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb"
  apt-get update && apt-get install -y ./"git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb"
  rm -f "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb"
fi

# --- Extra npm packages (as string) ---
EXTRA_PKGS="${_OPTION_EXTRANPMPACKAGES}"
for pkg in $EXTRA_PKGS; do
  sudo -u $USERNAME npm install -g "$pkg"
done

# --- Add ll alias to shells if enabled ---
if [ "${_OPTION_ADDLLALIAS}" = "true" ]; then
  for shell_rc in "$USER_HOME/.bashrc" "$USER_HOME/.zshrc"; do
    if [ -f "$shell_rc" ] || [ "$shell_rc" = "$USER_HOME/.bashrc" ]; then
      echo "alias ll='ls -la'" >> "$shell_rc"
    fi
  done
fi

# --- Install SuperClaude framework if any category is enabled ---
# Parse SuperClaude configuration JSON
SUPERCLAUDE_CONFIG="${_OPTION_INSTALLSUPERCLAUDE}"
if [ -n "$SUPERCLAUDE_CONFIG" ] && [ "$SUPERCLAUDE_CONFIG" != "{\"core\":false,\"ui\":false,\"codeOps\":false}" ]; then
  echo "[core-devtools] Installing SuperClaude framework..."
  
  # Parse JSON config to extract boolean values
  SUPERCLAUDE_CORE=$(echo "$SUPERCLAUDE_CONFIG" | jq -r '.core // false')
  SUPERCLAUDE_UI=$(echo "$SUPERCLAUDE_CONFIG" | jq -r '.ui // false') 
  SUPERCLAUDE_CODEOPS=$(echo "$SUPERCLAUDE_CONFIG" | jq -r '.codeOps // false')
  
  # Only install if at least one category is enabled
  if [ "$SUPERCLAUDE_CORE" = "true" ] || [ "$SUPERCLAUDE_UI" = "true" ] || [ "$SUPERCLAUDE_CODEOPS" = "true" ]; then
    # Install git if not present (required for cloning)
    if ! command -v git >/dev/null 2>&1; then
      apt-get install -y git
    fi
    
    # Clone SuperClaude repository to user's home directory
    SUPERCLAUDE_DIR="$USER_HOME/.superclaude"
    
    # Remove existing installation if present
    if [ -d "$SUPERCLAUDE_DIR" ]; then
      rm -rf "$SUPERCLAUDE_DIR"
    fi
    
    # Clone and install as the user
    sudo -u $USERNAME git clone https://github.com/NomenAK/SuperClaude.git "$SUPERCLAUDE_DIR"
    
    # Make install script executable and run it
    chmod +x "$SUPERCLAUDE_DIR/install.sh"
    cd "$SUPERCLAUDE_DIR"
    sudo -u $USERNAME ./install.sh
    
    # Add SuperClaude to PATH in shell configs
    for shell_rc in "$USER_HOME/.bashrc" "$USER_HOME/.zshrc"; do
      if [ -f "$shell_rc" ] || [ "$shell_rc" = "$USER_HOME/.bashrc" ]; then
        # Remove existing SuperClaude PATH entries to avoid duplicates
        grep -v "superclaude" "$shell_rc" > "${shell_rc}.tmp" 2>/dev/null || true
        mv "${shell_rc}.tmp" "$shell_rc" 2>/dev/null || true
        
        # Add SuperClaude PATH and completion
        {
          echo ""
          echo "# SuperClaude framework"
          echo "export PATH=\"\$HOME/.superclaude:\$PATH\""
        } >> "$shell_rc"
      fi
    done
    
    # Log which categories are enabled
    echo "[core-devtools] SuperClaude categories enabled:"
    [ "$SUPERCLAUDE_CORE" = "true" ] && echo "  - Core (documentation & reasoning)"
    [ "$SUPERCLAUDE_UI" = "true" ] && echo "  - UI (component generation & testing)"  
    [ "$SUPERCLAUDE_CODEOPS" = "true" ] && echo "  - CodeOps (transformation & semantic analysis)"
    
    echo "[core-devtools] SuperClaude framework installed successfully"
  fi
fi

echo "[core-devtools] Done."