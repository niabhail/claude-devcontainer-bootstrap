#!/bin/bash

# Usage: ./create.sh <project_name> [workdir]
if [ -z "$1" ]; then
  echo "Usage: $0 <project_name> [workdir]"
  echo "  project_name: Name of the project to create"
  echo "  workdir: Optional working directory (absolute or relative path)"
  echo "           If not provided, creates in current directory"
  echo "Examples:"
  echo "  $0 myproject                    # Creates ./myproject"
  echo "  $0 myproject /home/user/work    # Creates /home/user/work/myproject"
  echo "  $0 myproject ../projects         # Creates ../projects/myproject"
  exit 1
fi

PROJECT="$1"
WORKDIR="${2:-.}"  # Default to current directory if not provided

# Extract just the project name (basename) for use in devcontainer.json
PROJECT_NAME="$(basename "$PROJECT")"

TEMPLATE_REPO="https://github.com/anthropics/claude-code.git"
DEVCONTAINER_DIR=".devcontainer"
MCP_JSON=".mcp.json"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Handle relative paths - make them relative to the bootstrap directory
if [[ ! "$WORKDIR" = /* ]]; then
  WORKDIR="$SCRIPT_DIR/$WORKDIR"
fi

# Create working directory if it doesn't exist
mkdir -p "$WORKDIR"

echo "Creating new project: $PROJECT in $WORKDIR"
PROJECT_PATH="$WORKDIR/$PROJECT"
mkdir -p "$PROJECT_PATH"
cd "$PROJECT_PATH" || exit 1

echo "Cloning Claude Code devcontainer setup..."
git clone --depth 1 "$TEMPLATE_REPO" temp_claude_code
cp -r temp_claude_code/$DEVCONTAINER_DIR ./
rm -rf temp_claude_code

echo "Customizing devcontainer configuration..."

# 1. Update devcontainer.json settings
# Set project name
echo "  - Setting container name from 'Claude Code Sandbox' to '$PROJECT_NAME'"
sed -i "s/\"name\": \"Claude Code Sandbox\"/\"name\": \"$PROJECT_NAME\"/" .devcontainer/devcontainer.json

# Add port forwarding for Claude CLI OAuth callback (port 54545) and Next.js (port 3000)
# This allows claude login to work properly in devcontainer and Next.js apps to be accessible
if ! grep -q "forwardPorts" .devcontainer/devcontainer.json; then
    echo "  - Adding port forwarding for ports 3000 (Next.js) and 54545 (Claude OAuth)"
    sed -i '/"workspaceFolder": "\/workspace",/a\  "forwardPorts": [3000, 54545],\n  "portsAttributes": {\n    "3000": {\n      "label": "Next.js App",\n      "onAutoForward": "openBrowser"\n    },\n    "54545": {\n      "label": "Claude OAuth",\n      "onAutoForward": "ignore",\n      "requireLocalPort": false\n    }\n  },' .devcontainer/devcontainer.json
else
    echo "  - Port forwarding already exists, skipping"
fi

# Add lifecycle hooks - use more specific patterns to avoid duplicates
# Add onCreateCommand after workspaceFolder (only if not already present)
if ! grep -q "onCreateCommand" .devcontainer/devcontainer.json; then
    echo "  - Adding onCreateCommand to run pre-create.sh"
    sed -i '/"workspaceFolder": "\/workspace",/a\  "onCreateCommand": "chmod +x .devcontainer/pre-create.sh \&\& .devcontainer/pre-create.sh",' .devcontainer/devcontainer.json
else
    echo "  - onCreateCommand already exists, skipping"
fi

# Update postCreateCommand to include post-create hook
echo "  - Updating postCreateCommand to include post-create.sh"
sed -i 's|"postCreateCommand": "sudo /usr/local/bin/init-firewall.sh"|"postCreateCommand": "sudo /usr/local/bin/init-firewall.sh \&\& chmod +x .devcontainer/post-create.sh \&\& .devcontainer/post-create.sh"|' .devcontainer/devcontainer.json

# Add environment variable handling using safe hybrid approach
echo "  - Adding safe environment variable support (host > container > .env precedence)"
# Check if remoteEnv exists and add PERPLEXITY_API_KEY if not already present
if grep -q '"remoteEnv"' .devcontainer/devcontainer.json; then
    # remoteEnv exists, check if PERPLEXITY_API_KEY is already there
    if ! grep -q '"PERPLEXITY_API_KEY"' .devcontainer/devcontainer.json; then
        # Add PERPLEXITY_API_KEY to existing remoteEnv (before closing brace)
        sed -i '/"remoteEnv": {/,/}/ { /}/i\    "PERPLEXITY_API_KEY": "${localEnv:PERPLEXITY_API_KEY}",
        }' .devcontainer/devcontainer.json
        # Remove trailing comma if it's the last entry
        sed -i '/"remoteEnv": {/,/}/ { s/,\([[:space:]]*}\)/\1/g }' .devcontainer/devcontainer.json
        echo "    - Added PERPLEXITY_API_KEY to existing remoteEnv"
    else
        echo "    - PERPLEXITY_API_KEY already exists in remoteEnv, skipping"
    fi
else
    # No remoteEnv, add it after containerEnv closing brace
    sed -i '/},/{
        N
        s/},\n  "workspaceMount"/},\n  "remoteEnv": {\n    "PERPLEXITY_API_KEY": "${localEnv:PERPLEXITY_API_KEY}"\n  },\n  "workspaceMount"/
    }' .devcontainer/devcontainer.json
    echo "    - Created remoteEnv with PERPLEXITY_API_KEY"
fi

# Add VS Code extensions - each on its own line for clarity
sed -i 's|"eamodio.gitlens"|"eamodio.gitlens",\
        "ms-vscode.vscode-typescript-next",\
        "yoavbls.pretty-ts-errors",\
        "usernamehw.errorlens",\
        "christian-kohler.path-intellisense",\
        "gruntfuggly.todo-tree",\
        "wayou.vscode-todo-highlight",\
        "formulahendry.auto-rename-tag",\
        "formulahendry.auto-close-tag",\
        "bradlc.vscode-tailwindcss",\
        "prisma.prisma",\
        "mikestead.dotenv",\
        "redhat.vscode-yaml"|' .devcontainer/devcontainer.json

# 2. Apply firewall customizations
if [ -f "$SCRIPT_DIR/templates/firewall-allowlist.txt" ]; then
    echo "  - Adding firewall allowlist..."
    echo "" >> .devcontainer/init-firewall.sh
    echo "# Custom firewall allowlist" >> .devcontainer/init-firewall.sh
    cat "$SCRIPT_DIR/templates/firewall-allowlist.txt" >> .devcontainer/init-firewall.sh
fi

# 3. Copy custom init scripts
if [ -d "$SCRIPT_DIR/templates/init-scripts" ]; then
    echo "  - Adding custom init scripts..."
    cp -r "$SCRIPT_DIR/templates/init-scripts"/* .devcontainer/
    chmod +x .devcontainer/*.sh
fi

# 4. Copy Claude setup prompts to devcontainer docs
if [ -f "$SCRIPT_DIR/templates/claude-setup-prompts.md" ]; then
    echo "  - Adding Claude setup prompts..."
    mkdir -p .devcontainer/docs
    cp "$SCRIPT_DIR/templates/claude-setup-prompts.md" .devcontainer/docs/
fi

echo "Initializing project environment..."
# Setup .env file
if [ -f "$SCRIPT_DIR/templates/.env.example" ]; then
    cp "$SCRIPT_DIR/templates/.env.example" .env
    
    # Populate PERPLEXITY_API_KEY from host environment if available
    if [ -n "$PERPLEXITY_API_KEY" ]; then
        sed -i "s/PERPLEXITY_API_KEY=/PERPLEXITY_API_KEY=$PERPLEXITY_API_KEY/" .env
        echo "  - Created .env from template and populated PERPLEXITY_API_KEY"
    else
        echo "  - Created .env from template (PERPLEXITY_API_KEY not set in host environment)"
    fi
else
    touch .env
    echo "# Custom ENV variables can go here" >> .env
    if [ -n "$PERPLEXITY_API_KEY" ]; then
        echo "PERPLEXITY_API_KEY=$PERPLEXITY_API_KEY" >> .env
    fi
fi

echo "Setting up MCP servers configuration..."
if [ -f "$SCRIPT_DIR/templates/mcp-servers.json" ]; then
    echo "Loading MCP servers from template..."
    cp "$SCRIPT_DIR/templates/mcp-servers.json" "$MCP_JSON"
else
    echo "Creating empty MCP config..."
    cat <<EOF > "$MCP_JSON"
{
  "mcpServers": {}
}
EOF
fi

echo 'Initial setup complete for: '"$PROJECT"
echo
echo "Next steps:"
echo "1. Verify PERPLEXITY_API_KEY is set in .env file for enhanced task-master-ai features"
echo "2. Open VS Code in this project directory and select 'Reopen in Container' when prompted."
echo "3. Authenticate Claude Code if required."
echo "4. MCP servers (task-master-ai, Context7) are pre-configured in $MCP_JSON"
echo "   - Customize by editing the file if needed"
echo "   - Restart Claude Code session after any MCP changes"
echo "5. After login to Claude Code, run the setup prompts from .devcontainer/docs/claude-setup-prompts.md"
echo "   - Change default model to Sonnet"
echo "   - Initialize TaskMaster AI with proper configuration"
echo "   - Set up PRD analysis and development team subagents"
