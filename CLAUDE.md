# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) and all users working with code in this repository.

---

## Repository Overview

This is a Claude Code devcontainer bootstrap project that provides a bash script to quickly scaffold new projects with advanced, feature-driven Claude Code devcontainer support, optimized for both home and corporate environments.

---

## Commands

### Bootstrap a new project with devcontainer support

```bash
./create.sh <project_name>
```

Creates a new project directory with `.devcontainer/` setup.

**Example:**
```bash
./create.sh my-new-app          # Creates ./my-new-app/.devcontainer/
./create.sh /path/to/new-app    # Creates /path/to/new-app/.devcontainer/
```

### Bootstrap an existing project

```bash
cd /path/to/existing-project
/path/to/claude-devcontainer-bootstrap/create.sh .
```

or simply:

```bash
cd /path/to/existing-project
/path/to/claude-devcontainer-bootstrap/create.sh
```

Adds `.devcontainer/` to your existing project without touching source files.

**Note:** If `.devcontainer/` already exists, you'll be prompted to back it up before overwriting.

---

## Architecture

### Compact Self-Contained Structure

**Everything lives in `.devcontainer/`** - no source file pollution:

```
.devcontainer/
├── devcontainer.json           # Main configuration
├── mcp-servers.json           # MCP server configuration
├── .env.example               # Environment template
├── features/                  # Local devcontainer features
│   └── core-devtools/        # Certificate, firewall, dev tools
├── certs/                     # SSL certificates (if corporate proxy)
├── scripts/                   # Runtime configuration scripts
│   ├── setup-certificates.sh
│   ├── init-firewall.sh
│   └── setup-superclaude.sh
└── docs/                      # Documentation & configuration
    ├── claude-setup-prompts.md
    └── firewall-allowlist.txt
```

Plus: `.mcp.json` symlink at project root → `.devcontainer/mcp-servers.json` for Claude Code compatibility.

### Bootstrap Process

The main shell script (`create.sh`):

1. **Detects project mode**: New directory vs. existing project (via `.` argument or no directory).
2. **Creates compact structure**: All configuration, docs, and scripts in `.devcontainer/`.
3. **Generates devcontainer.json** from template, referencing:
   - Official Anthropic Claude Code container image
   - Local `core-devtools` feature (certificates, firewall, dev utilities)
4. **Generates runtime scripts** for workspace-dependent configuration:
   - Certificate installation (`setup-certificates.sh`)
   - Firewall initialization (`init-firewall.sh`)
   - SuperClaude framework setup (`setup-superclaude.sh`)
5. **Creates environment template** at `.devcontainer/.env.example`.
6. **Generates MCP server configuration** at `.devcontainer/mcp-servers.json` based on feature flags (TaskMaster, SuperClaude categories).
7. **Copies documentation** to `.devcontainer/docs/` (setup prompts, firewall allowlist).
8. **Creates symlink** `.mcp.json` → `.devcontainer/mcp-servers.json` for Claude Code.
9. **Runtime configuration via postCreateCommand** - certificates, firewall, SuperClaude configured after workspace mount.

---

## Key Features

### Hybrid Build-Time + Runtime Architecture

- **Build-time preparation**: The `core-devtools` feature installs all system tools (certificate management, firewall tools, development utilities) during container build.
- **Runtime configuration**: Certificate installation and firewall rule application happen via `postCreateCommand` after workspace files are mounted and container has proper capabilities.
- **Clean separation**: Eliminates build-time vs workspace-file timing conflicts while maintaining security and functionality.

### Corporate Certificate Support

- Automatic detection and installation of corporate CA certificates during bootstrap.
- Runtime certificate installation configures system trust store, npm, git, and shell environment variables.
- Supports Zscaler and other corporate proxy certificates with graceful fallback when certificates are not present.

### Network Policy Enforcement

- Outbound network rules are enforced using iptables/ipset, powered by project-specific `.devcontainer/docs/firewall-allowlist.txt`.
- Firewall rules applied at runtime via `postCreateCommand` when container has NET_ADMIN capabilities.
- Every domain/IP your devcontainer can reach must be declared and permitted, supporting robust security and compliance.
- The egress allowlist is fully version-controlled and auditable in each project.

### Consolidated Developer Tools

- All development tools (certificate management, firewall tools, `task-master-ai`, `@devcontainers/cli`, git-delta, npm CLIs, shell aliases) are provided via the single `core-devtools` feature.
- Projects can enable or disable any sub-component via feature options.
- Node.js, TypeScript, and other runtime support is included via standard devcontainer features.

### SuperClaude Framework Integration

- **Enhanced Claude Code capabilities**: 19 specialized commands and 9 cognitive personas for advanced development workflows.
- **Token optimization**: 70% reduction for large projects through intelligent compression and symbol-based communication.
- **Category-based MCP servers**: Modular selection of Core, UI, and CodeOps server groups based on development needs.
- **Complete ecosystem**: Full SuperClaude MCP suite (context7, sequential-thinking, magic, playwright, morphllm-fast-apply, serena).
- **Git-based session management**: Automatic checkpoints and session history for continuity across development sessions.
- **Developer-focused configuration**: Three simple categories (Core, UI, CodeOps) that map to SuperClaude's internal structure.

### Category-Based MCP Architecture

- **Core Category**: Essential documentation (context7) and reasoning (sequential-thinking) tools for all developers.
- **UI Category**: Frontend development tools including component generation (magic) and browser testing (playwright).
- **CodeOps Category**: Code transformation (morphllm-fast-apply) and semantic analysis (serena) plus intelligent agents.
- **Flexible selection**: Enable only the categories needed for your development workflow.
- **Full mapping**: Categories map to SuperClaude's actual component and MCP server installation options behind the scenes.

## Configuration Examples

### Default Configuration (All SuperClaude categories enabled)
```json
"./features/core-devtools": {
  "installTaskMaster": false,
  "installSuperClaude": "{\"core\":true,\"ui\":true,\"codeOps\":true}"
}
```
**Result**: Complete SuperClaude ecosystem with all MCP servers and components.

### Backend Developer Focus
```json
"./features/core-devtools": {
  "installTaskMaster": false,
  "installSuperClaude": "{\"core\":true,\"ui\":false,\"codeOps\":true}"
}
```
**Result**: Documentation, reasoning, and code transformation tools (no UI components).

### Frontend Developer Focus
```json
"./features/core-devtools": {
  "installTaskMaster": false,
  "installSuperClaude": "{\"core\":true,\"ui\":true,\"codeOps\":false}"
}
```
**Result**: Documentation, reasoning, and UI development tools (no heavy code transformation).

### Analysis Only
```json
"./features/core-devtools": {
  "installTaskMaster": false,
  "installSuperClaude": "{\"core\":true,\"ui\":false,\"codeOps\":false}"
}
```
**Result**: Just documentation and reasoning capabilities for analysis work.

### TaskMaster + SuperClaude Combination
```json
"./features/core-devtools": {
  "installTaskMaster": true,
  "installSuperClaude": "{\"core\":true,\"ui\":true,\"codeOps\":true}"
}
```
**Result**: Maximum capabilities with both basic task automation and complete SuperClaude ecosystem.

### Minimal Setup (Everything disabled)
```json
"./features/core-devtools": {
  "installTaskMaster": false,
  "installSuperClaude": "{\"core\":false,\"ui\":false,\"codeOps\":false}"
}
```
**Result**: No MCP servers configured. Pure Claude Code experience.

---

## Template System

### Script Templates
- `templates/scripts/setup-certificates.sh` - Runtime certificate installation
- `templates/scripts/init-firewall.sh` - Runtime firewall configuration

### Configuration Templates
- `templates/devcontainer.json.in` - DevContainer configuration with variable substitution
- `templates/.env.example` - Environment variables template
- `templates/mcp-servers.json` - MCP server configuration

### Documentation Templates  
- `templates/claude-setup-prompts.md` - User onboarding guide
- `templates/firewall-allowlist.txt` - Network allowlist template

---

## Onboarding & Documentation

**After bootstrapping:**

- See `.devcontainer/docs/claude-setup-prompts.md` for detailed setup, tips, and post-login Claude configuration.
- Review and adapt `.devcontainer/docs/firewall-allowlist.txt` for any new network egress needs your project will have.
- Certificate installation will happen automatically if corporate certificates are detected during bootstrap.
- Firewall rules will be applied automatically during container startup.
- All configuration is self-contained in `.devcontainer/` - commit it to share with team, or add to `.gitignore` for personal use.

---

## Requirements

### Host System Requirements

- **Git** – For cloning repositories
- **Docker** – For running devcontainers  
- **jq** – For JSON processing during bootstrap

### For Corporate Environments

- **Corporate SSL certificate**: Place at `~/.ssl/certs/zscaler.crt`, `~/Downloads/zscaler-root-ca.crt`, or similar common locations before running bootstrap

### For Full Testing

- **DevContainer CLI** – `npm install -g @devcontainers/cli`
  - For validating or debugging devcontainer configuration outside of VS Code

---

## Testing Commands

### Run complete test suite

```bash
./test-devcontainer.sh
```

### Test new project creation

```bash
./create.sh test-project
cd test-project
```

### Test existing project bootstrap

```bash
mkdir -p /tmp/existing-app/src
cd /tmp/existing-app
/path/to/create.sh .
```

### Verify devcontainer configuration

```bash
cat test-project/.devcontainer/devcontainer.json
```

### Check generated scripts

```bash
ls test-project/.devcontainer/scripts/
cat test-project/.devcontainer/scripts/setup-certificates.sh
```

### Check MCP configuration

```bash
cat test-project/.mcp.json                              # Symlink at root
cat test-project/.devcontainer/mcp-servers.json        # Actual config file
```

### Check docs and allowlist

```bash
ls test-project/.devcontainer/docs/
cat test-project/.devcontainer/docs/firewall-allowlist.txt
cat test-project/.devcontainer/docs/claude-setup-prompts.md
```

### Verify compact structure

```bash
tree test-project/.devcontainer/ -L 2
```

### Test with DevContainer CLI

```sh
devcontainer build --workspace-folder test-project
devcontainer up --workspace-folder test-project
devcontainer exec --workspace-folder test-project -- claude --version
```

### Clean up test

```bash
rm -rf test-project /tmp/existing-app
```

---

## Architecture Notes

### Why Hybrid Build-Time + Runtime?

- **DevContainer features run during Docker build** - they cannot access workspace files or require runtime capabilities like NET_ADMIN
- **Corporate certificates and firewall rules need workspace files and capabilities** - these must run after container starts
- **Solution**: Features prepare the system (install tools), runtime scripts handle configuration (apply settings)

### PostCreateCommand Coordination

The generated `postCreateCommand` runs three scripts in sequence:
```bash
"postCreateCommand": "bash .devcontainer/scripts/setup-certificates.sh && sudo bash .devcontainer/scripts/init-firewall.sh && bash .devcontainer/scripts/setup-superclaude.sh"
```

This ensures certificates are installed, then firewall rules are applied, and finally SuperClaude framework is configured - all after workspace files are available.

---

## Migrated Architecture from Previous Versions

- **Removed problematic features**: `zscaler-certs` and `egress-control` features that failed during build due to timing conflicts
- **Consolidated tools**: All system tools now installed via single `core-devtools` feature
- **Added runtime configuration**: Uses `postCreateCommand` for workspace-dependent operations
- **Template-based scripts**: Runtime scripts generated from templates during bootstrap for consistency and maintainability
- **Compact self-contained structure**: All configuration files now in `.devcontainer/` (no docs/, .env, .mcp.json in project root)
- **Existing project support**: Can bootstrap devcontainer in existing projects without touching source files
- **Improved testing**: Comprehensive test suite validates entire bootstrap → build → runtime lifecycle