# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Claude Code devcontainer bootstrap project that provides a bash script to quickly set up new projects with Claude Code devcontainer support, optimized for both home and corporate environments.

## Commands

### Create a new project with devcontainer support
```bash
./create.sh <project_name> [workdir]
```

## Architecture

The repository contains a main shell script (`create.sh`) that:
1. Creates a new project directory
2. Clones the Claude Code devcontainer configuration from the official anthropics/claude-code repository
3. Customizes the devcontainer with:
   - Project-specific container name
   - Lifecycle hooks (pre-create and post-create)
   - VS Code extensions for TypeScript/JavaScript development
   - Corporate SSL certificate support
4. Sets up an `.env` file from template
5. Configures MCP servers (task-master-ai with Perplexity support, Context7)
6. Applies firewall allowlist rules
7. Installs task-master-ai globally for direct CLI access
8. Provides claude-setup-prompts.md for post-login configuration

## Key Features

### Claude CLI Authentication in Devcontainer
- Port 54545 is automatically forwarded to allow OAuth callback from browser to devcontainer
- When running `claude login` inside devcontainer, the browser will redirect to localhost:54545/callback
- This port forwarding ensures the authentication flow completes successfully

### Lifecycle Hooks
- **pre-create.sh**: Runs during container creation, handles SSL certificates from `~/.ssl/certs/zscaler.crt`
- **post-create.sh**: Runs after container is ready, installs task-master-ai globally

### MCP Configuration
- task-master-ai configured with Perplexity API key support
- Uses claude-code/sonnet model by default
- Manual setup required via templates/claude-setup-prompts.md after login

### Corporate Environment Support
- Automatic SSL certificate detection and configuration
- Configures npm, git, Node.js, and other tools with corporate certs
- Works seamlessly in both home and office environments

## Testing Commands

When testing changes to the bootstrap:
```bash
# Test project creation
./create.sh test-project /tmp

# Verify devcontainer customizations
cat /tmp/test-project/.devcontainer/devcontainer.json

# Check MCP configuration
cat /tmp/test-project/.mcp.json

# Test with DevContainer CLI (faster than VS Code)
devcontainer build --workspace-folder /tmp/test-project
devcontainer up --workspace-folder /tmp/test-project
devcontainer exec --workspace-folder /tmp/test-project -- claude --version

# Run comprehensive test suite
./test-bootstrap.sh /tmp

# Clean up test
rm -rf /tmp/test-project
```