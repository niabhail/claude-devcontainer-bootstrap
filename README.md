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
✅ **Flexible MCP Integration** - SuperClaude enterprise framework by default, plus support for custom MCP servers  
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
      "installTaskMaster": false,
      "installDevcontainersCLI": true,
      "installGitDelta": true,
      "installSuperClaude": "{\"core\":true,\"ui\":true,\"codeOps\":true}",
      "addLLAlias": true,
      "extraNpmPackages": ""
    }
  },
  "postCreateCommand": "bash .devcontainer/scripts/setup-certificates.sh && sudo bash .devcontainer/scripts/init-firewall.sh && bash .devcontainer/scripts/setup-superclaude.sh"
}
```

**SuperClaude Categories:**
- **`core`**: Documentation (context7) and reasoning (sequential-thinking)
- **`ui`**: Component generation (magic) and browser testing (playwright)  
- **`codeOps`**: Code transformation (morphllm-fast-apply) and semantic analysis (serena)

### MCP Server Configuration

The bootstrap automatically generates `.mcp.json` with SuperClaude servers by default, which you can customize:

**Default Generated Configuration:**
```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"]
    },
    "sequential-thinking": {
      "command": "npx", 
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
    },
    "magic": {
      "command": "npx",
      "args": ["@21st-dev/magic"],
      "env": {"TWENTYFIRST_API_KEY": "${TWENTYFIRST_API_KEY}"}
    }
    // ... additional servers based on your SuperClaude configuration
  }
}
```

**Add Your Own MCP Servers:**
Edit `.mcp.json` in your project to add custom servers:

```json
{
  "mcpServers": {
    // SuperClaude servers (generated automatically)
    "context7": { "command": "npx", "args": ["-y", "@upstash/context7-mcp@latest"] },
    
    // Your custom MCP servers
    "my-custom-server": {
      "command": "python",
      "args": ["/path/to/my-mcp-server.py"],
      "env": { "API_KEY": "${MY_API_KEY}" }
    },
    "database-mcp": {
      "command": "npx",
      "args": ["@myorg/database-mcp"],
      "env": { "DATABASE_URL": "${DATABASE_URL}" }
    }
  }
}
```

**Template Customization:**
Edit `templates/mcp-servers.json` to change defaults for all new projects.

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

- **Enterprise AI Framework**: SuperClaude with 6 specialized MCP servers
- **Corporate Security**: Runtime certificate trust and network egress controls
- **Developer Tools**: VS Code extensions, git-delta, shell enhancements
- **Template System**: Consistent project scaffolding and configuration

### MCP Server Ecosystem

**Built-in SuperClaude Framework** (Enterprise AI development):

**Core Category**: Documentation & reasoning
- **context7**: Up-to-date library documentation and framework patterns
- **sequential-thinking**: Structured multi-step reasoning and hypothesis testing

**UI Category**: Component generation & testing
- **magic**: Modern UI component generation from 21st.dev patterns
- **playwright**: Browser automation and E2E testing

**CodeOps Category**: Code transformation & analysis
- **morphllm-fast-apply**: Pattern-based code editing with token optimization
- **serena**: Semantic code understanding with project memory

**Optional Additions**:
- **task-master-ai**: AI-powered task management (when enabled)

**Custom MCP Server Support**:
- Add any MCP-compatible server to `.mcp.json`
- Database connectors, API integrations, custom tools
- Organization-specific MCP servers
- Community MCP servers from npm registry
- Python-based MCP servers via uv or pip
- Local development MCP servers


## 🧪 Testing

```bash
# Run complete test suite
./test-devcontainer.sh

# Test basic project creation
./create.sh test-project /tmp && rm -rf /tmp/test-project
```


## 🔧 Requirements

- **Git, Docker, jq** – Core dependencies
- **VS Code** with Dev Containers extension  
- **Corporate SSL certificate** (if behind corporate proxy)

*See full requirements and troubleshooting in the generated `docs/` folder.*

## 🐛 Common Issues

- **Corporate Network**: Ensure SSL certificate is placed before running `create.sh`
- **MCP Servers**: Restart Claude Code session after container initialization  
- **Network Access**: Update `docs/firewall-allowlist.txt` for additional domains

*Full troubleshooting guide available in project `docs/` folder.*

---

## 🎯 Use Cases

- **Enterprise Development**: Corporate network and security compliance with runtime configuration
- **Team Standardization**: Consistent tooling across development teams via consolidated features  
- **Claude Code Projects**: Optimized for AI-assisted development workflows with hybrid architecture
- **Rapid Prototyping**: Zero-config project scaffolding with automated runtime setup
- **Security-First Development**: Network controls and certificate management by default