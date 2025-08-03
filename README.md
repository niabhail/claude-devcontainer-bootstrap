# Claude DevContainer Bootstrap

A customizable bootstrap tool for creating projects with Claude Code devcontainer support, optimized for both home and corporate environments.

## Features

- ✅ Automatic devcontainer setup with Claude Code
- ✅ Corporate SSL certificate support (Zscaler, etc.)
- ✅ Pre-configured MCP servers (task-master-ai, Context7)
- ✅ VS Code extensions for TypeScript/JavaScript development
- ✅ Lifecycle hooks for custom initialization
- ✅ Firewall allowlist configuration

## Usage

```bash
# Make the script executable (first time only)
chmod +x create.sh

# Create project in current directory
./create.sh <project_name>

# Create project in specific directory
./create.sh <project_name> <workdir>

# Examples:
./create.sh myproject                    # Creates ./myproject
./create.sh myproject /home/user/work    # Creates /home/user/work/myproject
./create.sh myproject ../projects        # Creates ../projects/myproject (relative to bootstrap dir)
```

## Setup Instructions

### 1. Corporate Certificate (Optional - for Zscaler/SSL environments)
Place your corporate SSL certificate at `~/.ssl/certs/zscaler.crt` on your host machine:
```bash
mkdir -p ~/.ssl/certs
cp /path/to/your/corporate-cert.crt ~/.ssl/certs/zscaler.crt
```
The certificate will be automatically detected and configured for all development tools.

### 2. Perplexity API Key (Optional - for enhanced task-master-ai)
Set the environment variable before opening the devcontainer:
```bash
export PERPLEXITY_API_KEY="your-key"
# Or add to your shell profile for permanent setup
```

## Customization

### 1. Environment Variables
Edit `templates/.env.example` to define default environment variables for new projects.

### 2. Firewall Allowlist
Add allowed domains to `templates/firewall-allowlist.txt`:
```
api.mycompany.com
*.internal.corp
database.staging.com
```

### 3. Lifecycle Hooks
The bootstrap includes two lifecycle hooks:
- **`pre-create.sh`**: Runs before container setup (SSL certs, system config)
- **`post-create.sh`**: Runs after container is ready (npm installs, user config)

Edit these in `templates/init-scripts/` to customize initialization.

### 4. MCP Servers
Edit `templates/mcp-servers.json` to configure MCP servers:
- task-master-ai (pre-configured with Perplexity support)
- Context7
- Add your own MCP servers

### 5. Post-Login Setup
After VS Code devcontainer is running and Claude Code is authenticated:
1. Run the setup prompts from `templates/claude-setup-prompts.md`
2. Configure Claude Code default model (Sonnet recommended)
3. Initialize TaskMaster AI with project-specific settings
4. Set up PRD analysis and development team subagents

## What Gets Created

Each new project includes:
- 📁 `.devcontainer/` - Full devcontainer configuration
- 📄 `.env` - Environment variables from template
- 📄 `.mcp.json` - MCP server configuration
- 📄 `templates/claude-setup-prompts.md` - Post-login setup instructions
- 🔧 Customized devcontainer with:
  - Project-specific container name
  - VS Code extensions for TypeScript/React development
  - Lifecycle hooks for initialization
  - Corporate SSL certificate support
  - Firewall rules

## VS Code Extensions Included

- TypeScript development tools
- Pretty TypeScript errors
- Error Lens
- Path IntelliSense
- TODO Tree & Highlight
- Auto rename/close tags
- Tailwind CSS
- Prisma
- DotENV
- YAML support

## Structure
```
templates/
├── .env.example              # Environment variables template
├── firewall-allowlist.txt   # Additional allowed domains
├── mcp-servers.json         # MCP server configuration
├── claude-setup-prompts.md  # Post-login Claude Code setup instructions
└── init-scripts/            # Lifecycle hooks
    ├── pre-create.sh        # Pre-container setup (SSL certs)
    └── post-create.sh       # Post-container setup (npm installs)
```

## Requirements

- Docker Desktop
- VS Code with Dev Containers extension
- Git
- Node.js/npm
- DevContainer CLI (`npm install -g @devcontainers/cli`) - for testing

## Troubleshooting

**SSL/Certificate Issues in Corporate Environment:**
Ensure your certificate is at `~/.ssl/certs/zscaler.crt` before creating the project.

**MCP Servers Not Working:**
Restart Claude Code session after modifying `.mcp.json`.

**Extensions Not Loading:**
Rebuild the container after modifying extensions.