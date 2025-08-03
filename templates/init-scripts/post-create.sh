#!/bin/bash
# Post-create hook - runs after devcontainer is ready
# Use for user-level installs and configurations

echo "Running post-create setup..."

# Install task-master-ai globally for direct CLI access
npm install -g task-master-ai

# Install DevContainer CLI for container management
npm install -g @devcontainers/cli

# Set up safe .env loading in shell profiles (only sets vars that aren't already set)
echo "Setting up .env auto-loading with safe precedence..."
cat >> ~/.bashrc << 'EOF'

# Auto-load .env file with safe precedence (only if vars not already set)
if [ -f /workspace/.env ]; then
  while IFS= read -r line; do
    # Skip comments and empty lines
    if [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "$line" ]]; then
      continue
    fi
    # Process variable assignments
    if [[ "$line" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; then
      var_name="${line%%=*}"
      # Only export if not already set (preserves host/container env vars)
      if [ -z "${!var_name}" ]; then
        export "$line"
      fi
    fi
  done < /workspace/.env
fi
EOF

# Also add to zsh if it exists
if [ -f ~/.zshrc ]; then
  cat >> ~/.zshrc << 'EOF'

# Auto-load .env file with safe precedence (only if vars not already set)
if [ -f /workspace/.env ]; then
  while IFS= read -r line; do
    # Skip comments and empty lines
    if [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "$line" ]]; then
      continue
    fi
    # Process variable assignments
    if [[ "$line" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; then
      var_name="${line%%=*}"
      # Only export if not already set (preserves host/container env vars)
      if [ -z "${!var_name}" ]; then
        export "$line"
      fi
    fi
  done < /workspace/.env
fi
EOF
fi

# Example: Set up custom aliases
# echo "alias ll='ls -la'" >> ~/.bashrc
# echo "alias taskmaster='task-master-ai'" >> ~/.bashrc

# Example: Configure git
# git config --global user.name "Your Name"
# git config --global user.email "your.email@example.com"

echo "Post-create setup complete!"