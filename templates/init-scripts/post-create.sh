#!/bin/bash
# Post-create hook - runs after devcontainer is ready
# Use for user-level installs and configurations

echo "Running post-create setup..."

# Install task-master-ai globally for direct CLI access
npm install -g task-master-ai

# Example: Set up custom aliases
# echo "alias ll='ls -la'" >> ~/.bashrc
# echo "alias taskmaster='task-master-ai'" >> ~/.bashrc

# Example: Configure git
# git config --global user.name "Your Name"
# git config --global user.email "your.email@example.com"

echo "Post-create setup complete!"