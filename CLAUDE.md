# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) and all users working with code in this repository.

---

## Repository Overview

This is a Claude Code devcontainer bootstrap project that provides a bash script to quickly scaffold new projects with advanced, feature-driven Claude Code devcontainer support, optimized for both home and corporate environments.

---

## Commands

### Bootstrap with Interactive Configuration (Default)

```bash
./create.sh my-project
```

Prompts you to configure MCP servers interactively:
- Enable/disable MCP servers
- Select SuperClaude categories (Core, UI, CodeOps)
- Enable/disable TaskMaster

**Example:**
```bash
./create.sh my-new-app

⚙️  DevContainer Configuration

Enable MCP servers? (Y/n): y

Select SuperClaude categories (press Enter for defaults):

  📖 Core (context7, sequential-thinking)? (Y/n):
  🎨 UI (magic, playwright)? (Y/n): n
  🔧 CodeOps (morphllm, serena)? (Y/n):

Enable TaskMaster? (y/N): n
```

### Bootstrap with Configuration File

```bash
./create.sh my-project --config devcontainer-config.json
```

Use a JSON configuration file to skip interactive prompts. Perfect for:
- Team collaboration (share config in version control)
- Automation/CI pipelines
- Consistent project setups

**Configuration file format:**
```json
{
  "taskmaster": false,
  "superclaude": {
    "core": true,
    "ui": false,
    "codeOps": true
  }
}
```

**Example:**
```bash
# Create team config once
cat > team-devcontainer.json << 'EOF'
{
  "taskmaster": false,
  "superclaude": {
    "core": true,
    "ui": true,
    "codeOps": false
  }
}
EOF

# Use it for projects
./create.sh frontend-app --config team-devcontainer.json
```

### Bootstrap an Existing Project

```bash
cd /path/to/existing-project
/path/to/claude-devcontainer-bootstrap/create.sh .
```

or simply:

```bash
cd /path/to/existing-project
/path/to/claude-devcontainer-bootstrap/create.sh
```

Adds `.devcontainer/` to your existing project without touching source files. Works with both interactive and `--config` modes.

**Note:** If `.devcontainer/` already exists, you'll be prompted to back it up before overwriting.

---

## Architecture

### Compact Self-Contained Structure

**Devcontainer tooling stays self-contained** - no interference with your project files:

```
project/
├── .mcp.json                   # MCP servers (only if enabled) - required by Claude Code
└── .devcontainer/
    ├── devcontainer.json       # Main configuration (uses remoteEnv for tool config)
    ├── features/               # Local devcontainer features
    │   └── core-devtools/     # Certificate, firewall, dev tools
    ├── certs/                  # SSL certificates (if corporate proxy)
    ├── scripts/                # Runtime configuration scripts
    │   ├── setup-certificates.sh
    │   ├── init-firewall.sh
    │   └── setup-superclaude.sh
    └── docs/                   # Documentation & configuration
        ├── claude-setup-prompts.md
        └── firewall-allowlist.txt
```

**Key design decisions:**
- `.mcp.json` at root: Required by Claude Code, only created if MCP servers are enabled
- No `.env` files: Your project's `.env` files remain untouched; tool config uses `remoteEnv` in `devcontainer.json`
- Self-contained: Everything else in `.devcontainer/` - commit to share with team or gitignore for personal use

### Bootstrap Process

The main shell script (`create.sh`):

1. **Detects project mode**: New directory vs. existing project (via `.` argument or no directory).
2. **Creates compact structure**: All configuration, docs, and scripts in `.devcontainer/`.
3. **Generates devcontainer.json** from template, referencing:
   - Official Anthropic Claude Code container image
   - Local `core-devtools` feature (certificates, firewall, dev utilities)
   - Uses `remoteEnv` for tool configuration (no `.env` files needed)
4. **Generates runtime scripts** for workspace-dependent configuration:
   - Certificate installation (`setup-certificates.sh`)
   - Firewall initialization (`init-firewall.sh`)
   - SuperClaude framework setup (`setup-superclaude.sh`)
5. **Conditionally generates `.mcp.json`** at project root:
   - Only created if MCP servers are enabled (TaskMaster or SuperClaude categories)
   - Skipped if all MCP options disabled - keeps project root clean
6. **Copies documentation** to `.devcontainer/docs/` (setup prompts, firewall allowlist).
7. **Runtime configuration via postCreateCommand** - certificates, firewall, SuperClaude configured after workspace mount.

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

Configuration is set during bootstrap via:
1. **Interactive prompts** (default) - Answer questions during setup
2. **Config file** (`--config`) - Use JSON file for automation/team sharing
3. **Post-bootstrap editing** - Edit generated `.devcontainer/devcontainer.json` before building container

### Example 1: Backend Developer (Config File)

```json
{
  "taskmaster": false,
  "superclaude": {
    "core": true,
    "ui": false,
    "codeOps": true
  }
}
```
```bash
./create.sh backend-api --config backend-config.json
```
**Result**: Documentation, reasoning, and code transformation tools (no UI components).

### Example 2: Frontend Developer (Config File)

```json
{
  "taskmaster": false,
  "superclaude": {
    "core": true,
    "ui": true,
    "codeOps": false
  }
}
```
```bash
./create.sh react-app --config frontend-config.json
```
**Result**: Documentation, reasoning, and UI development tools (no heavy code transformation).

### Example 3: Maximum Capabilities (Interactive)

During bootstrap, answer:
- Enable MCP servers? **Y**
- Core? **Y**
- UI? **Y**
- CodeOps? **Y**
- TaskMaster? **Y**

**Result**: Complete ecosystem with all MCP servers and task automation.

### Example 4: Minimal Setup (Config File)

```json
{
  "taskmaster": false,
  "superclaude": {
    "core": false,
    "ui": false,
    "codeOps": false
  }
}
```
```bash
./create.sh minimal-project --config minimal-config.json
```
**Result**: No MCP servers configured. Pure Claude Code experience.

### Example 5: Team Config File

Create once, share in repository:
```bash
# In your bootstrap repo or team shared location
cat > .devcontainer-team-default.json << 'EOF'
{
  "taskmaster": false,
  "superclaude": {
    "core": true,
    "ui": true,
    "codeOps": true
  }
}
EOF

# Everyone uses the same config
./create.sh new-feature --config .devcontainer-team-default.json
```

**Customization after bootstrap:**
The generated `.devcontainer/devcontainer.json` is the source of truth and can be edited before building the container or committed to share with your team.

---

## Template System

### Script Templates
- `templates/scripts/setup-certificates.sh` - Runtime certificate installation
- `templates/scripts/init-firewall.sh` - Runtime firewall configuration
- `templates/scripts/setup-superclaude.sh` - SuperClaude framework setup

### Configuration Templates
- `templates/devcontainer.json.in` - DevContainer configuration with variable substitution and remoteEnv
- `templates/mcp-servers.json` - Conditional MCP server configuration (TaskMaster, SuperClaude categories)
- `devcontainer-config.example.json` - Example configuration file for `--config` flag

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
cat test-project/.mcp.json                     # At root (only if MCP servers enabled)
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