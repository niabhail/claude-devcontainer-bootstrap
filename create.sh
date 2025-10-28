#!/usr/bin/env bash

# Global variables
PROJECT=""
PROJECT_NAME=""
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BOOTSTRAP_DIR="$SCRIPT_DIR"
PROJECT_PATH=""
DEVCONTAINER_PATH=""
CONFIG_FILE=""

# Configuration variables (can be set via interactive prompts or config file)
INSTALL_TASKMASTER="false"
SUPERCLAUDE_CORE="true"
SUPERCLAUDE_UI="true"
SUPERCLAUDE_CODEOPS="true"

# ---- Read configuration from JSON file ----
read_config_file() {
  local config_file="$1"

  if [[ ! -f "$config_file" ]]; then
    echo "❌ Error: Config file not found: $config_file"
    exit 1
  fi

  echo "📄 Reading configuration from: $config_file"

  # Validate JSON
  if ! jq empty "$config_file" 2>/dev/null; then
    echo "❌ Error: Invalid JSON in config file"
    exit 1
  fi

  # Read configuration values (handle missing keys with defaults)
  INSTALL_TASKMASTER=$(jq -r 'if .taskmaster == null then "false" else (.taskmaster | tostring) end' "$config_file")
  SUPERCLAUDE_CORE=$(jq -r 'if .superclaude.core == null then "true" else (.superclaude.core | tostring) end' "$config_file")
  SUPERCLAUDE_UI=$(jq -r 'if .superclaude.ui == null then "true" else (.superclaude.ui | tostring) end' "$config_file")
  SUPERCLAUDE_CODEOPS=$(jq -r 'if .superclaude.codeOps == null then "true" else (.superclaude.codeOps | tostring) end' "$config_file")

  echo "  ✓ Configuration loaded"
}

# ---- Interactive configuration prompts ----
prompt_user_configuration() {
  echo ""
  echo "⚙️  DevContainer Configuration"
  echo ""

  # Ask about MCP servers
  read -p "Enable MCP servers? (Y/n): " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Nn]$ ]]; then
    INSTALL_TASKMASTER="false"
    SUPERCLAUDE_CORE="false"
    SUPERCLAUDE_UI="false"
    SUPERCLAUDE_CODEOPS="false"
    echo "  ℹ️  All MCP servers disabled"
    return
  fi

  echo ""
  echo "Select SuperClaude categories (press Enter for defaults):"
  echo ""

  # SuperClaude Core
  read -p "  📖 Core (context7, sequential-thinking)? (Y/n): " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Nn]$ ]]; then
    SUPERCLAUDE_CORE="false"
  else
    SUPERCLAUDE_CORE="true"
  fi

  # SuperClaude UI
  read -p "  🎨 UI (magic, playwright)? (Y/n): " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Nn]$ ]]; then
    SUPERCLAUDE_UI="false"
  else
    SUPERCLAUDE_UI="true"
  fi

  # SuperClaude CodeOps
  read -p "  🔧 CodeOps (morphllm, serena)? (Y/n): " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Nn]$ ]]; then
    SUPERCLAUDE_CODEOPS="false"
  else
    SUPERCLAUDE_CODEOPS="true"
  fi

  echo ""

  # TaskMaster
  read -p "Enable TaskMaster? (y/N): " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    INSTALL_TASKMASTER="true"
  else
    INSTALL_TASKMASTER="false"
  fi

  echo ""
  echo "Configuration summary:"
  echo "  - TaskMaster: $INSTALL_TASKMASTER"
  echo "  - SuperClaude Core: $SUPERCLAUDE_CORE"
  echo "  - SuperClaude UI: $SUPERCLAUDE_UI"
  echo "  - SuperClaude CodeOps: $SUPERCLAUDE_CODEOPS"
  echo ""
}

# ---- Argument validation and setup ----
validate_arguments() {
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --config)
        CONFIG_FILE="$2"
        shift 2
        ;;
      --help|-h)
        echo "Usage: $0 [project_name] [--config config.json]"
        echo ""
        echo "Arguments:"
        echo "  project_name           Project directory name (default: current directory)"
        echo "                        Use '.' for current directory"
        echo ""
        echo "Options:"
        echo "  --config FILE         Read configuration from JSON file"
        echo "                        (skips interactive prompts)"
        echo ""
        echo "Examples:"
        echo "  $0                    # Interactive setup in current directory"
        echo "  $0 my-project         # Interactive setup for new project"
        echo "  $0 . --config dev.json  # Use config file in current directory"
        echo "  $0 my-project --config team-config.json"
        exit 0
        ;;
      *)
        PROJECT="$1"
        shift
        ;;
    esac
  done

  local target="${PROJECT:-.}"

  # Handle "." or no argument = current directory
  if [[ "$target" == "." ]] || [[ -z "$1" ]]; then
    PROJECT_PATH="$(pwd)"
    PROJECT_NAME="$(basename "$PROJECT_PATH")"
    DEVCONTAINER_PATH="$PROJECT_PATH/.devcontainer"
    echo "📍 Bootstrapping current folder: $PROJECT_NAME"
  else
    # Handle absolute or relative paths
    if [[ "$target" = /* ]]; then
      PROJECT_PATH="$target"
    else
      PROJECT_PATH="$(pwd)/$target"
    fi

    PROJECT_NAME="$(basename "$PROJECT_PATH")"
    DEVCONTAINER_PATH="$PROJECT_PATH/.devcontainer"

    # Check if project folder exists
    if [[ -d "$PROJECT_PATH" ]]; then
      echo "📂 Found existing folder: $PROJECT_NAME"
    else
      echo "🆕 Creating new project: $PROJECT_NAME"
    fi
  fi

  # Safety check: does .devcontainer already exist?
  if [[ -d "$DEVCONTAINER_PATH" ]]; then
    echo ""
    echo "⚠️  WARNING: .devcontainer/ already exists in $PROJECT_NAME"
    echo ""
    read -p "Overwrite? Existing config will be backed up to .devcontainer.backup (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "❌ Aborted. Existing .devcontainer/ was not modified."
      exit 0
    fi

    # Backup existing .devcontainer
    local backup_path="${DEVCONTAINER_PATH}.backup.$(date +%Y%m%d-%H%M%S)"
    mv "$DEVCONTAINER_PATH" "$backup_path"
    echo "💾 Backed up existing config to: $(basename "$backup_path")"
  fi
}

# ---- Project structure setup ----
setup_project_structure() {
  echo "🚀 Setting up devcontainer structure..."

  # Create project folder if it doesn't exist
  mkdir -p "$PROJECT_PATH"

  # Create .devcontainer structure (everything contained here)
  mkdir -p "$DEVCONTAINER_PATH/docs"
  mkdir -p "$DEVCONTAINER_PATH/certs"
  mkdir -p "$DEVCONTAINER_PATH/scripts"

  echo "  ✓ Created compact .devcontainer/ structure"
}

# ---- Copy local devcontainer features ----
copy_local_features() {
  echo "📦 Copying local devcontainer features..."
  local features_source="$BOOTSTRAP_DIR/features"
  local features_dest="$DEVCONTAINER_PATH/features"
  
  if [[ -d "$features_source" ]]; then
    cp -r "$features_source" "$DEVCONTAINER_PATH/"
    echo "  ✓ Copied local features to .devcontainer/features/"
    
    # List copied features for confirmation
    if [[ -d "$features_dest" ]]; then
      echo "  📋 Available features:"
      for feature_dir in "$features_dest"/*; do
        if [[ -d "$feature_dir" ]]; then
          local feature_name=$(basename "$feature_dir")
          echo "     - $feature_name"
        fi
      done
    fi
  else
    echo "  ⚠ Warning: No features directory found at $features_source"
    echo "     Local features won't be available in this project."
    return 1
  fi
  return 0
}

# ---- Process MCP server template based on feature flags ----
generate_mcp_config() {
  echo "⚙️ Generating MCP server configuration..."
  local template_file="$BOOTSTRAP_DIR/templates/mcp-servers.json"
  local output_file="$PROJECT_PATH/.mcp.json"

  # Read feature flags from generated devcontainer.json
  local devcontainer_file="$DEVCONTAINER_PATH/devcontainer.json"
  local install_taskmaster=$(jq -r '.features."./features/core-devtools".installTaskMaster // false' "$devcontainer_file")
  local superclaude_config=$(jq -r '.features."./features/core-devtools".installSuperClaude // "{\"core\":true,\"ui\":true,\"codeOps\":true}"' "$devcontainer_file")

  # Parse SuperClaude configuration JSON
  local install_superclaude_core=$(echo "$superclaude_config" | jq -r '.core // false')
  local install_superclaude_ui=$(echo "$superclaude_config" | jq -r '.ui // false')
  local install_superclaude_codeops=$(echo "$superclaude_config" | jq -r '.codeOps // false')

  # Process template and add servers based on flags
  local temp_mcp='{"mcpServers": {}}'
  local has_servers=false

  if [[ "$install_taskmaster" == "true" ]]; then
    echo "  📋 Including task-master-ai MCP server"
    # Extract TaskMaster section and merge
    temp_mcp=$(echo "$temp_mcp" | jq --argjson taskmaster "$(jq '.mcpServers.__CONDITIONAL_TASKMASTER__' "$template_file")" '.mcpServers += $taskmaster')
    has_servers=true
  fi

  # SuperClaude category-based inclusion
  local superclaude_enabled=false
  local superclaude_servers=""

  if [[ "$install_superclaude_core" == "true" ]]; then
    echo "  📖 Including SuperClaude Core servers (context7, sequential-thinking)"
    temp_mcp=$(echo "$temp_mcp" | jq --argjson core "$(jq '.mcpServers.__SUPERCLAUDE_CORE__' "$template_file")" '.mcpServers += $core')
    superclaude_enabled=true
    has_servers=true
    superclaude_servers="${superclaude_servers}core "
  fi

  if [[ "$install_superclaude_ui" == "true" ]]; then
    echo "  🎨 Including SuperClaude UI servers (magic, playwright)"
    temp_mcp=$(echo "$temp_mcp" | jq --argjson ui "$(jq '.mcpServers.__SUPERCLAUDE_UI__' "$template_file")" '.mcpServers += $ui')
    superclaude_enabled=true
    has_servers=true
    superclaude_servers="${superclaude_servers}ui "
  fi

  if [[ "$install_superclaude_codeops" == "true" ]]; then
    echo "  🔧 Including SuperClaude CodeOps servers (morphllm-fast-apply, serena)"
    temp_mcp=$(echo "$temp_mcp" | jq --argjson codeops "$(jq '.mcpServers.__SUPERCLAUDE_CODEOPS__' "$template_file")" '.mcpServers += $codeops')
    superclaude_enabled=true
    has_servers=true
    superclaude_servers="${superclaude_servers}codeOps "
  fi

  # Only create .mcp.json if we have at least one MCP server configured
  if [[ "$has_servers" == "true" ]]; then
    echo "$temp_mcp" | jq '.' > "$output_file"

    if [[ "$superclaude_enabled" == "true" ]]; then
      echo "  🚀 SuperClaude categories enabled: ${superclaude_servers}"
    fi

    echo "  ✓ Generated .mcp.json at project root"
  else
    echo "  ℹ️  No MCP servers configured - skipping .mcp.json creation"
    echo "     To enable: set installTaskMaster: true or enable SuperClaude categories"
  fi
}

# ---- Copy template files ----
copy_template_files() {
  echo "📄 Copying configuration templates..."

  # Copy documentation to .devcontainer/docs/
  cp "$BOOTSTRAP_DIR/templates/claude-setup-prompts.md" "$DEVCONTAINER_PATH/docs/claude-setup-prompts.md"
  cp "$BOOTSTRAP_DIR/templates/firewall-allowlist.txt" "$DEVCONTAINER_PATH/docs/firewall-allowlist.txt"

  echo "  ✓ Copied docs to .devcontainer/docs/"

  echo "📄 Copying script templates..."
  cp "$BOOTSTRAP_DIR/templates/scripts/setup-certificates.sh" "$DEVCONTAINER_PATH/scripts/setup-certificates.sh"
  cp "$BOOTSTRAP_DIR/templates/scripts/init-firewall.sh" "$DEVCONTAINER_PATH/scripts/init-firewall.sh"
  cp "$BOOTSTRAP_DIR/templates/scripts/setup-superclaude.sh" "$DEVCONTAINER_PATH/scripts/setup-superclaude.sh"
  chmod +x "$DEVCONTAINER_PATH/scripts"/*.sh

  echo "  ✓ Copied runtime scripts to .devcontainer/scripts/"
}

# ---- Generate devcontainer configuration ----
generate_devcontainer_config() {
  echo "🐳 Generating devcontainer configuration..."
  local template_file="$BOOTSTRAP_DIR/templates/devcontainer.json.in"
  local output_file="$DEVCONTAINER_PATH/devcontainer.json"

  # Build SuperClaude JSON config with proper escaping for JSON string
  local superclaude_json="{\\\\\"core\\\\\":$SUPERCLAUDE_CORE,\\\\\"ui\\\\\":$SUPERCLAUDE_UI,\\\\\"codeOps\\\\\":$SUPERCLAUDE_CODEOPS}"

  cat "$template_file" \
    | sed "s/\$PROJECT_NAME/$PROJECT_NAME/g" \
    | sed "s/\$INSTALL_TASKMASTER/$INSTALL_TASKMASTER/g" \
    | sed "s|\$SUPERCLAUDE_CONFIG|$superclaude_json|g" \
    | sed -E '/^\s*\/\//d; s/\/\/.*$//; /^[[:space:]]*$/d' \
    > "$output_file"

  echo "  ✓ Generated devcontainer.json with custom configuration"
}

# ---- Certificate setup and detection ----
setup_certificate_support() {
  echo "🔒 Setting up certificate support..."
  
  local host_cert_paths=(
    "$HOME/.ssl/certs/zscaler.crt"
    "$HOME/Downloads/zscaler-root-ca.crt"
    "$HOME/Downloads/ZScaler Root CA.crt"
    "/usr/local/share/ca-certificates/zscaler.crt"
  )
  
  local cert_found=false
  for cert_path in "${host_cert_paths[@]}"; do
    if [[ -f "$cert_path" ]]; then
      cp "$cert_path" "$DEVCONTAINER_PATH/certs/zscaler.crt"
      echo "  ✓ Found and copied Zscaler cert from: $cert_path"
      cert_found=true
      break
    fi
  done

  if [[ "$cert_found" == "false" ]]; then
    echo "  ⚠ No Zscaler certificate found at common locations:"
    printf "     %s\n" "${host_cert_paths[@]}"
    echo "     Certificate setup script will provide guidance when container starts"
    return 1
  fi
  return 0
}

# ---- Display completion message ----
display_completion_message() {
  echo
  echo "✅ DevContainer setup complete for: $PROJECT_NAME"
  echo
  echo "📦 Self-contained devcontainer tooling:"
  echo "   - All configuration in .devcontainer/ (commit to share with team)"
  echo "   - .mcp.json at root (required by Claude Code, only if MCP servers enabled)"
  echo "   - No interference with your project's .env or other config files"
  echo
  echo "📋 Next steps:"
  echo "1. 🖥️  Open VS Code in $PROJECT_PATH"
  echo "2. 🐳 Click 'Reopen in Container' when prompted"
  echo "3. 🔒 Certificate setup runs automatically on first start"
  echo "   - If behind corporate proxy: place cert at .devcontainer/certs/zscaler.crt"
  echo "4. 🔐 Authenticate Claude Code if required"
  echo "5. ⚙️  MCP servers (if enabled, see .mcp.json at project root):"
  echo "   - TaskMaster: disabled by default (enable: installTaskMaster: true)"
  echo "   - SuperClaude Core: context7, sequential-thinking"
  echo "   - SuperClaude UI: magic, playwright"
  echo "   - SuperClaude CodeOps: morphllm-fast-apply, serena"
  echo "   - Customize in .devcontainer/devcontainer.json feature config"
  echo "6. 🚀 SuperClaude framework (if enabled):"
  echo "   - 19 specialized commands (/sc:help)"
  echo "   - 9 cognitive personas (Architect, Frontend, Backend, etc.)"
  echo "   - Token optimization & git session checkpoints"
  echo "7. 📚 See .devcontainer/docs/claude-setup-prompts.md for detailed setup"
  echo
  echo "🎯 Project location: $PROJECT_PATH"
}

# ---- Main orchestration ----
main() {
  validate_arguments "$@"

  # Load configuration from file or prompt user
  if [[ -n "$CONFIG_FILE" ]]; then
    read_config_file "$CONFIG_FILE"
  else
    prompt_user_configuration
  fi

  setup_project_structure
  copy_local_features
  copy_template_files
  generate_devcontainer_config
  generate_mcp_config  # Generate MCP config after devcontainer config is available
  setup_certificate_support
  display_completion_message
}

# Run main with all arguments
main "$@"