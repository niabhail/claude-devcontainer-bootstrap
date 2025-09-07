#!/bin/bash
set -e

echo "Configuring SuperClaude framework..."

USERNAME="${_REMOTE_USER:-node}"
USER_HOME=$(getent passwd "$USERNAME" | cut -d: -f6 2>/dev/null || echo "/home/$USERNAME")
SUPERCLAUDE_DIR="$USER_HOME/.superclaude"

# Check if SuperClaude is installed
if [ ! -d "$SUPERCLAUDE_DIR" ]; then
    echo "WARNING: SuperClaude not found at $SUPERCLAUDE_DIR"
    echo "This script requires SuperClaude to be installed during container build"
    exit 0
fi

echo "SuperClaude installation found at: $SUPERCLAUDE_DIR"

# Ensure SuperClaude has proper permissions
chown -R "$USERNAME:$USERNAME" "$SUPERCLAUDE_DIR" 2>/dev/null || true

# Initialize SuperClaude configuration directory
CLAUDE_CONFIG_DIR="$USER_HOME/.claude"
SUPERCLAUDE_CONFIG_DIR="$CLAUDE_CONFIG_DIR/superclaude"

sudo -u "$USERNAME" mkdir -p "$SUPERCLAUDE_CONFIG_DIR"

# Read category selections from devcontainer environment or defaults
SUPERCLAUDE_CORE="${SUPERCLAUDE_CORE:-true}"
SUPERCLAUDE_UI="${SUPERCLAUDE_UI:-true}"
SUPERCLAUDE_CODEOPS="${SUPERCLAUDE_CODEOPS:-true}"

# Create SuperClaude configuration file based on enabled categories
SUPERCLAUDE_CONFIG="$SUPERCLAUDE_CONFIG_DIR/config.json"
if [ ! -f "$SUPERCLAUDE_CONFIG" ]; then
    echo "Generating SuperClaude configuration based on enabled categories..."
    
    # Base configuration
    sudo -u "$USERNAME" cat > "$SUPERCLAUDE_CONFIG" << EOF
{
  "version": "1.0",
  "categories": {
    "core": $SUPERCLAUDE_CORE,
    "ui": $SUPERCLAUDE_UI,
    "codeOps": $SUPERCLAUDE_CODEOPS
  },
  "features": {
    "tokenOptimization": true,
    "gitCheckpoints": true,
    "advancedPersonas": true,
    "mcpIntegration": true
  },
  "components": {
    "core": true,
    "modes": true,
    "commands": true,
    "agents": $SUPERCLAUDE_CODEOPS,
    "mcpDocs": true
  },
  "mcpServers": {
    "context7": $SUPERCLAUDE_CORE,
    "sequentialThinking": $SUPERCLAUDE_CORE,
    "magic": $SUPERCLAUDE_UI,
    "playwright": $SUPERCLAUDE_UI,
    "morphllm": $SUPERCLAUDE_CODEOPS,
    "serena": $SUPERCLAUDE_CODEOPS
  }
}
EOF
    echo "Created SuperClaude configuration at: $SUPERCLAUDE_CONFIG"
    
    # Log enabled categories
    echo "SuperClaude categories configured:"
    [ "$SUPERCLAUDE_CORE" = "true" ] && echo "  ✓ Core: Documentation and reasoning tools"
    [ "$SUPERCLAUDE_UI" = "true" ] && echo "  ✓ UI: Component generation and testing tools"
    [ "$SUPERCLAUDE_CODEOPS" = "true" ] && echo "  ✓ CodeOps: Code transformation and semantic analysis tools"
fi

# Set up git configuration for SuperClaude checkpoints
if command -v git >/dev/null 2>&1; then
    # Configure git for SuperClaude checkpoints (if not already configured)
    if ! sudo -u "$USERNAME" git config --global user.name >/dev/null 2>&1; then
        sudo -u "$USERNAME" git config --global user.name "SuperClaude DevContainer"
        sudo -u "$USERNAME" git config --global user.email "superclaude@devcontainer.local"
        echo "Configured git for SuperClaude checkpoints"
    fi
fi

# Create SuperClaude workspace directory for session history
WORKSPACE_DIR="/workspaces/${LOCAL_WORKSPACE_FOLDER:-$(basename "$PWD")}"
SUPERCLAUDE_WORKSPACE="$WORKSPACE_DIR/.superclaude"

if [ -d "$WORKSPACE_DIR" ]; then
    sudo -u "$USERNAME" mkdir -p "$SUPERCLAUDE_WORKSPACE/sessions"
    sudo -u "$USERNAME" mkdir -p "$SUPERCLAUDE_WORKSPACE/checkpoints"
    
    # Create initial session marker
    sudo -u "$USERNAME" cat > "$SUPERCLAUDE_WORKSPACE/sessions/session_$(date +%Y%m%d_%H%M%S).json" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "container": "devcontainer",
  "features": ["certificates", "firewall", "superclaude"],
  "status": "initialized"
}
EOF
    echo "Initialized SuperClaude workspace at: $SUPERCLAUDE_WORKSPACE"
fi

# Add environment variables for SuperClaude optimization
for shell_rc in "$USER_HOME/.bashrc" "$USER_HOME/.zshrc"; do
    if [ -f "$shell_rc" ] || [ "$shell_rc" = "$USER_HOME/.bashrc" ]; then
        # Remove existing SuperClaude env entries to avoid duplicates
        grep -v "SUPERCLAUDE_" "$shell_rc" > "${shell_rc}.tmp" 2>/dev/null || true
        mv "${shell_rc}.tmp" "$shell_rc" 2>/dev/null || true
        
        # Add SuperClaude environment variables
        {
            echo ""
            echo "# SuperClaude framework configuration"
            echo "export SUPERCLAUDE_HOME=\"$SUPERCLAUDE_DIR\""
            echo "export SUPERCLAUDE_CONFIG=\"$SUPERCLAUDE_CONFIG\""
            echo "export SUPERCLAUDE_TOKEN_OPTIMIZATION=true"
            echo "export SUPERCLAUDE_GIT_CHECKPOINTS=true"
        } >> "$shell_rc"
    fi
done

echo "SuperClaude framework configured successfully!"
echo "Available features:"
echo "  - 19 specialized commands for development workflow"
echo "  - 9 cognitive personas (Architect, Frontend, Backend, Security, etc.)"
echo "  - Token optimization (70% reduction for large projects)"
echo "  - Git-based checkpoints and session history"
echo "  - Enhanced MCP integration (Sequential, Magic, Playwright)"
echo ""
echo "To get started, try: /sc:help or /sc:status"