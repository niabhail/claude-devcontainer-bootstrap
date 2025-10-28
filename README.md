# Claude DevContainer Bootstrap

Quickly set up Claude Code projects with devcontainer support. Works for new and existing projects with interactive configuration.

## 🚀 Quick Start

### New Project (Interactive)

```bash
./create.sh my-project
```

Answer a few prompts about which MCP servers you want, and you're done!

### Existing Project

```bash
cd your-existing-project
/path/to/create.sh .
```

Adds `.devcontainer/` to your project without touching your source files.

### Team Setup (Config File)

```bash
# Create once, share with team
cat > team-config.json << 'EOF'
{
  "taskmaster": false,
  "superclaude": {
    "core": true,
    "ui": true,
    "codeOps": false
  }
}
EOF

# Everyone uses the same config
./create.sh my-project --config team-config.json
```

## 📦 What You Get

**Self-contained setup** in `.devcontainer/` folder:
- DevContainer configuration
- MCP server setup (Claude Code tools)
- Corporate certificate support
- Network security (firewall rules)
- Setup documentation

**No mess** - your source files stay clean!

## ⚙️ Configuration Options

### Interactive Mode (Default)

Run `./create.sh my-project` and choose:
- **SuperClaude Core**: Documentation and reasoning tools
- **SuperClaude UI**: Component generation and testing
- **SuperClaude CodeOps**: Code transformation and analysis
- **TaskMaster**: Task automation (optional)

### Config File Mode

Use `--config` flag with a JSON file:

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

Perfect for:
- Team consistency
- CI/CD automation
- Sharing configurations

## 🎯 Common Use Cases

### Backend Developer
```bash
./create.sh api-service
# Select: Core + CodeOps
# Skip: UI
```

### Frontend Developer
```bash
./create.sh react-app
# Select: Core + UI
# Skip: CodeOps
```

### Existing React Project
```bash
cd my-react-app
/path/to/create.sh .
# Select: Core + UI
```

## 🔧 Requirements

- Docker
- VS Code with Dev Containers extension
- Git and jq

**Optional:**
- Corporate SSL certificate (for corporate networks)

## 📋 After Setup

1. Open project in VS Code: `code my-project`
2. Click "Reopen in Container" when prompted
3. Wait for container to build (first time only)
4. Claude Code is ready to use!

See `.devcontainer/docs/claude-setup-prompts.md` in your project for detailed setup.

## 🛠️ Features

### For Everyone
- ✅ Interactive setup - no config files needed
- ✅ Works with existing projects
- ✅ Self-contained - everything in `.devcontainer/`
- ✅ VS Code extensions included

### For Teams
- ✅ Share config files in version control
- ✅ Consistent setups across team
- ✅ Editable after generation

### For Corporate Environments
- ✅ Corporate SSL certificate support
- ✅ Network firewall controls
- ✅ Security by default

## 🆘 Common Issues

**MCP servers not working?**
- Restart Claude Code session after container starts
- Check `.mcp.json` was generated

**Corporate network issues?**
- Place SSL certificate at `~/.ssl/certs/zscaler.crt` before running
- Certificate setup runs automatically

**Need to change configuration?**
- Edit `.devcontainer/devcontainer.json` before first container build
- Or run `./create.sh .` again (backs up existing config)

## 📚 Documentation

- `CLAUDE.md` - Detailed architecture and configuration
- `.devcontainer/docs/` in your project - Setup guides
- `devcontainer-config.example.json` - Config file example

## ⚡ Help

```bash
./create.sh --help
```

Shows all options and examples.

---

**Simple. Clean. Ready for Claude Code development.**
