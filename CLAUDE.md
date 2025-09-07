# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) and all users working with code in this repository.

---

## Repository Overview

This is a Claude Code devcontainer bootstrap project that provides a bash script to quickly scaffold new projects with advanced, feature-driven Claude Code devcontainer support, optimized for both home and corporate environments.

---

## Commands

### Create a new project with devcontainer support

```bash
./create.sh <project_name> [workdir]
```

- `project_name`: Name for the new project directory
- `workdir`: (optional) Where to place the new directory. Defaults to the current folder.

---

## Architecture

The main shell script (`create.sh`):

1. Creates a new project directory structure.
2. Populates all recommended config and docs from templates (not from cloning anthropics repo).
3. Generates a `.devcontainer/devcontainer.json` **from a template**, referencing:
    - The official Anthropic Claude Code container image.
    - Modular devcontainer feature for:
      - Core developer tools (`core-devtools` - includes certificate tools, firewall tools, and dev utilities)
      - Node.js and VS Code extension support
4. Generates runtime scripts for workspace-dependent configuration:
    - Certificate installation script (`setup-certificates.sh`)
    - Firewall initialization script (`init-firewall.sh`)
5. Sets up a project-local `.env` based on template and populates critical env vars.
6. Generates conditional MCP server configuration via `.mcp.json` based on feature flags (task-master-ai if enabled, SuperClaude servers if enabled).
7. Copies documentation and setup prompts into a top-level `/docs` directory for user onboarding and security (including `firewall-allowlist.txt`, `claude-setup-prompts.md`).
8. **Uses postCreateCommand for runtime configuration** - certificates, firewall rules, and SuperClaude framework are configured after workspace mount when capabilities are available.

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

- Outbound network rules are enforced using iptables/ipset, powered by project-specific `/docs/firewall-allowlist.txt`.
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

**After creating a project:**

- See `/docs/claude-setup-prompts.md` for detailed setup, tips, and post-login Claude configuration.
- Review and adapt `/docs/firewall-allowlist.txt` for any new network egress needs your project will have.
- Certificate installation will happen automatically if corporate certificates are detected during bootstrap.
- Firewall rules will be applied automatically during container startup.

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

### Test project creation

```bash
./create.sh test-project /tmp 
```

### Verify devcontainer configuration

```bash
cat /tmp/test-project/.devcontainer/devcontainer.json
```

### Check generated scripts

```bash
ls /tmp/test-project/.devcontainer/scripts/
cat /tmp/test-project/.devcontainer/scripts/setup-certificates.sh
```

### Check MCP configuration

```bash
cat /tmp/test-project/.mcp.json
```

### Check docs and allowlist

```bash
ls /tmp/test-project/docs/
cat /tmp/test-project/docs/firewall-allowlist.txt
```

### Test with DevContainer CLI

```sh
devcontainer build --workspace-folder /tmp/test-project
devcontainer up --workspace-folder /tmp/test-project
devcontainer exec --workspace-folder /tmp/test-project -- claude --version
```

### Clean up test

```bash
rm -rf /tmp/test-project
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
- **Improved testing**: Comprehensive test suite validates entire bootstrap → build → runtime lifecycle