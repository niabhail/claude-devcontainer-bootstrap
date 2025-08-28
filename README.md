# Claude DevContainer Bootstrap

A modern, hybrid bootstrap tool for creating Claude Code projects with devcontainer support. Built with consolidated features and runtime configuration for enterprise environments, corporate networks, and flexible team workflows.

## 🏗️ Architecture Overview

This bootstrap uses a **hybrid build-time + runtime approach** where system tools are installed via devcontainer features during build, while workspace-dependent configuration (certificates, firewall rules) is handled via runtime scripts after container startup.

### Bootstrap Project Structure

```bash
claude-devcontainer-bootstrap/
├── create.sh                       # Main bootstrap script
├── test-devcontainer.sh            # Complete test suite
├── README.md                       # This file
├── CLAUDE.md                       # Claude Code guidance and architecture docs
├── templates/                      # Files and scripts copied to new projects
│   ├── .env.example               # Environment variables template
│   ├── devcontainer.json.in       # Devcontainer template with feature references
│   ├── mcp-servers.json           # MCP server configuration
│   ├── firewall-allowlist.txt     # Network egress allowlist template
│   ├── claude-setup-prompts.md    # User onboarding and setup guide
│   └── scripts/                   # Runtime configuration scripts
│       ├── setup-certificates.sh  # Corporate certificate installation
│       └── init-firewall.sh       # Firewall rule application
└── features/                      # Consolidated devcontainer feature
    └── core-devtools/             # All developer tools, certificate tools, and firewall tools
```

### Generated Project Structure

```bash
myproject/
├── .devcontainer/
│   ├── devcontainer.json          # Generated from template with core-devtools feature
│   └── scripts/                   # Runtime configuration scripts
│       ├── setup-certificates.sh  # Certificate installation (runtime)
│       └── init-firewall.sh       # Firewall configuration (runtime)
├── .env                           # Project environment variables
├── .mcp.json                      # MCP server configuration
├── docs/
│   ├── firewall-allowlist.txt     # Project-specific network allowlist
│   └── claude-setup-prompts.md    # Setup guide and onboarding checklist
└── ... (your project source code)
```

## 🚀 Quick Start

```bash
# Make executable (first time only)
chmod +x create.sh

# Create project in current directory
./create.sh myproject

# Create project in specific directory
./create.sh myproject /path/to/workspace

# Examples
./create.sh api-service                    # Creates ./api-service
./create.sh frontend-app ~/projects        # Creates ~/projects/frontend-app
./create.sh data-pipeline ../workspace     # Creates ../workspace/data-pipeline
```

## ⚙️ Setup & Configuration

### 1. Corporate SSL Certificates (Optional)

For corporate networks with custom CA certificates:

```bash
# Place your corporate certificate in common locations
mkdir -p ~/.ssl/certs
cp your-corporate-cert.crt ~/.ssl/certs/zscaler.crt

# Alternative locations also supported:
# ~/Downloads/zscaler-root-ca.crt
# Other standard certificate paths
```

The runtime certificate script automatically detects and configures certificates for npm, git, and shell environments during container startup.

### 2. Perplexity API (Optional)

For enhanced task-master-ai MCP server capabilities:

```bash
export PERPLEXITY_API_KEY="your-api-key"
# Add to your shell profile for persistence
```

### 3. Network Security Setup

Projects include egress control via runtime firewall configuration:

- Default allowlist in `templates/firewall-allowlist.txt`
- Per-project customization in `docs/firewall-allowlist.txt`
- Automatic firewall rule enforcement during container startup

## 🔧 Key Features

### Hybrid Build-Time + Runtime Architecture

**🛠️ Build-Time Preparation (core-devtools feature)**

- Installs all system tools during container build
- Certificate management utilities (openssl, ca-certificates)
- Firewall tools (iptables, ipset)
- Developer tools (task-master-ai, git-delta, shell aliases)
- Configurable options for individual tool components

**⚡ Runtime Configuration (postCreateCommand)**

- Certificate installation after workspace files are mounted
- Firewall rule application with NET_ADMIN capabilities
- Clean separation eliminates build-time vs workspace-file conflicts
- Runs automatically during container startup

### Developer Experience

✅ **Zero Manual Configuration** - Automated build-time + runtime setup  
✅ **Corporate Network Ready** - Runtime SSL cert detection and trust  
✅ **Security by Default** - Runtime network egress controls and allowlists  
✅ **MCP Integration** - Pre-configured task-master-ai and Context7 servers  
✅ **VS Code Ready** - TypeScript, React, and productivity extensions  
✅ **Team Standardization** - Consistent tooling via consolidated features  
✅ **Template-Based** - All scripts generated from maintained templates  

## 🎯 Customization

### Environment Variables

Edit `templates/.env.example` to set default variables for all new projects:

```bash
# API keys, database URLs, default settings
NODE_ENV=development
LOG_LEVEL=info
```

### Network Allowlist

Customize `templates/firewall-allowlist.txt` for organization-wide defaults:

```txt
# Corporate services
api.mycompany.com
*.internal.corp
registry.npmjs.org

# Development services  
api.openai.com
api.perplexity.ai
```

### Feature Configuration

Per-project feature customization in generated `devcontainer.json`:

```json
{
  "features": {
    "./features/core-devtools": {
      "taskmaster": true,
      "devcontainer-cli": false,
      "git-delta": true,
      "certificates": true,
      "firewall": true
    }
  },
  "postCreateCommand": "bash .devcontainer/scripts/setup-certificates.sh && sudo bash .devcontainer/scripts/init-firewall.sh"
}
```

### MCP Server Configuration

Edit `templates/mcp-servers.json` for default MCP configurations:

```json
{
  "mcpServers": {
    "task-master-ai": {
      "command": "task-master-ai",
      "args": ["--perplexity-key", "$PERPLEXITY_API_KEY"]
    }
  }
}
```

## 📋 Post-Creation Workflow

After running the bootstrap script:

1. **Open in VS Code**: `code myproject`
2. **Reopen in Container**: VS Code will prompt automatically
3. **Wait for Runtime Configuration**: postCreateCommand will run automatically
4. **Follow setup guide**: Review `docs/claude-setup-prompts.md` in your project
5. **Configure Claude Code**: Authenticate and set default model
6. **Initialize MCP**: TaskMaster AI and Context7 will be ready
7. **Customize allowlist**: Edit `docs/firewall-allowlist.txt` as needed

## 🔍 What's Included

### Build-Time Installation (core-devtools feature)

- Certificate management tools (openssl, ca-certificates)
- Firewall tools (iptables, ipset, net-tools)
- Developer tools (task-master-ai, @devcontainers/cli, git-delta)
- Shell aliases and productivity enhancements
- Node.js and TypeScript support

### Runtime Configuration Scripts

- **setup-certificates.sh**: Corporate certificate trust configuration
- **init-firewall.sh**: Network egress control and allowlist enforcement
- Generated from templates for consistency and maintainability

### Pre-Configured Extensions

- TypeScript and JavaScript development tools
- Error Lens and Pretty TypeScript Errors
- Tailwind CSS IntelliSense
- Path IntelliSense and Auto Rename Tag
- TODO Tree and Highlight
- Prisma, YAML, and DotENV support

### MCP Servers

- **task-master-ai**: AI-powered task management with Perplexity integration
- **Context7**: Advanced context and file management
- Ready for additional custom MCP servers

### Security & Compliance

- Runtime corporate certificate trust (Zscaler, etc.)
- Network egress controls with allowlist enforcement
- Version-controlled security policies
- Audit-ready configuration

## 🧪 Testing & Validation

```bash
# Run complete test suite
./test-devcontainer.sh

# Test project creation
./create.sh test-project /tmp

# Validate devcontainer config
cat /tmp/test-project/.devcontainer/devcontainer.json

# Check generated runtime scripts
ls /tmp/test-project/.devcontainer/scripts/
cat /tmp/test-project/.devcontainer/scripts/setup-certificates.sh

# Check MCP configuration
cat /tmp/test-project/.mcp.json

# Check docs and allowlist
ls /tmp/test-project/docs/
cat /tmp/test-project/docs/firewall-allowlist.txt

# Test with DevContainer CLI
devcontainer build --workspace-folder /tmp/test-project
devcontainer up --workspace-folder /tmp/test-project
devcontainer exec --workspace-folder /tmp/test-project -- claude --version

# Cleanup
rm -rf /tmp/test-project
```

## 🆚 Migration from Previous Versions

**Architecture Changes:**

- **Removed problematic features**: `zscaler-certs` and `egress-control` features that failed during build due to timing conflicts
- **Consolidated tools**: All system tools now installed via single `core-devtools` feature
- **Added runtime configuration**: Uses `postCreateCommand` for workspace-dependent operations
- **Template-based scripts**: Runtime scripts generated from templates during bootstrap

**Migration Benefits:**

- ✅ Eliminates build-time vs workspace-file timing conflicts
- ✅ More reliable certificate and firewall configuration
- ✅ Better security with runtime capability management
- ✅ Easier maintenance with template-based script generation
- ✅ Comprehensive test suite covering full lifecycle
- ✅ Corporate compliance with audit-ready configs

## 🔧 Requirements

### Host System

- **Git** – For cloning repositories
- **Docker** – For running devcontainers  
- **jq** – For JSON processing during bootstrap
- VS Code with Dev Containers extension

### For Corporate Environments

- **Corporate SSL certificate**: Place at `~/.ssl/certs/zscaler.crt`, `~/Downloads/zscaler-root-ca.crt`, or similar common locations before running bootstrap

### For Full Testing

- **DevContainer CLI**: `npm install -g @devcontainers/cli` (for testing outside VS Code)

## 🐛 Troubleshooting

**Corporate Network Issues:**
Ensure your certificate is properly placed before running `create.sh`. The runtime certificate script will automatically detect and configure it during container startup.

**MCP Servers Not Working:**
Restart your Claude Code session after container initialization. Check `.mcp.json` configuration and environment variables.

**Network Access Blocked:**
Review and update `docs/firewall-allowlist.txt` in your project. The runtime firewall script enforces strict allowlisting.

**Runtime Scripts Not Executing:**
Check container logs for postCreateCommand execution. Ensure the container has proper capabilities (NET_ADMIN for firewall rules).

**Build vs Runtime Issues:**
The hybrid architecture separates build-time tool installation from runtime configuration. If you see timing conflicts, verify that workspace-dependent operations are in runtime scripts, not features.

---

## 🎯 Use Cases

- **Enterprise Development**: Corporate network and security compliance with runtime configuration
- **Team Standardization**: Consistent tooling across development teams via consolidated features  
- **Claude Code Projects**: Optimized for AI-assisted development workflows with hybrid architecture
- **Rapid Prototyping**: Zero-config project scaffolding with automated runtime setup
- **Security-First Development**: Network controls and certificate management by default