#!/usr/bin/env bash

# Global variables
PROJECT=""
PROJECT_NAME=""
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BOOTSTRAP_DIR="$SCRIPT_DIR"
PROJECT_PATH=""
DEVCONTAINER_PATH=""

# ---- Argument validation and setup ----
validate_arguments() {
  local target="${1:-.}"

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
  local output_file="$DEVCONTAINER_PATH/mcp-servers.json"
  
  # Read feature flags from generated devcontainer.json
  local devcontainer_file="$DEVCONTAINER_PATH/devcontainer.json"
  local install_taskmaster=$(jq -r '.features."./features/core-devtools".installTaskMaster // false' "$devcontainer_file")
  local superclaude_config=$(jq -r '.features."./features/core-devtools".installSuperClaude // "{\"core\":true,\"ui\":true,\"codeOps\":true}"' "$devcontainer_file")
  
  # Parse SuperClaude configuration JSON
  local install_superclaude_core=$(echo "$superclaude_config" | jq -r '.core // false')
  local install_superclaude_ui=$(echo "$superclaude_config" | jq -r '.ui // false')
  local install_superclaude_codeops=$(echo "$superclaude_config" | jq -r '.codeOps // false')
  
  # Start with empty MCP servers object
  echo '{"mcpServers": {}}' > "$output_file"
  
  # Process template and add servers based on flags
  local temp_mcp='{"mcpServers": {}}'
  
  if [[ "$install_taskmaster" == "true" ]]; then
    echo "  📋 Including task-master-ai MCP server"
    # Extract TaskMaster section and merge
    temp_mcp=$(echo "$temp_mcp" | jq --argjson taskmaster "$(jq '.mcpServers.__CONDITIONAL_TASKMASTER__' "$template_file")" '.mcpServers += $taskmaster')
  fi
  
  # SuperClaude category-based inclusion
  local superclaude_enabled=false
  local superclaude_servers=""
  
  if [[ "$install_superclaude_core" == "true" ]]; then
    echo "  📖 Including SuperClaude Core servers (context7, sequential-thinking)"
    temp_mcp=$(echo "$temp_mcp" | jq --argjson core "$(jq '.mcpServers.__SUPERCLAUDE_CORE__' "$template_file")" '.mcpServers += $core')
    superclaude_enabled=true
    superclaude_servers="${superclaude_servers}core "
  fi
  
  if [[ "$install_superclaude_ui" == "true" ]]; then
    echo "  🎨 Including SuperClaude UI servers (magic, playwright)"
    temp_mcp=$(echo "$temp_mcp" | jq --argjson ui "$(jq '.mcpServers.__SUPERCLAUDE_UI__' "$template_file")" '.mcpServers += $ui')
    superclaude_enabled=true
    superclaude_servers="${superclaude_servers}ui "
  fi
  
  if [[ "$install_superclaude_codeops" == "true" ]]; then
    echo "  🔧 Including SuperClaude CodeOps servers (morphllm-fast-apply, serena)"
    temp_mcp=$(echo "$temp_mcp" | jq --argjson codeops "$(jq '.mcpServers.__SUPERCLAUDE_CODEOPS__' "$template_file")" '.mcpServers += $codeops')
    superclaude_enabled=true
    superclaude_servers="${superclaude_servers}codeOps "
  fi
  
  # Write final configuration
  echo "$temp_mcp" | jq '.' > "$output_file"
  
  if [[ "$superclaude_enabled" == "true" ]]; then
    echo "  🚀 SuperClaude categories enabled: ${superclaude_servers}"
  fi

  echo "  ✓ Generated .devcontainer/mcp-servers.json with appropriate MCP servers"

  # Create symlink at project root for Claude Code compatibility
  local symlink_path="$PROJECT_PATH/.mcp.json"
  local target_path=".devcontainer/mcp-servers.json"

  if [[ -L "$symlink_path" ]]; then
    rm "$symlink_path"
  fi

  (cd "$PROJECT_PATH" && ln -s "$target_path" .mcp.json)
  echo "  ✓ Created .mcp.json symlink → .devcontainer/mcp-servers.json"
}

# ---- Copy template files ----
copy_template_files() {
  echo "📄 Copying configuration templates..."

  # All files go into .devcontainer/ for compact structure
  cp "$BOOTSTRAP_DIR/templates/.env.example" "$DEVCONTAINER_PATH/.env.example"
  cp "$BOOTSTRAP_DIR/templates/claude-setup-prompts.md" "$DEVCONTAINER_PATH/docs/claude-setup-prompts.md"
  cp "$BOOTSTRAP_DIR/templates/firewall-allowlist.txt" "$DEVCONTAINER_PATH/docs/firewall-allowlist.txt"

  echo "  ✓ Copied docs and config to .devcontainer/"

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
  
  cat "$template_file" \
    | sed "s/\$PROJECT_NAME/$PROJECT_NAME/g" \
    | sed -E '/^\s*\/\//d; s/\/\/.*$//; /^[[:space:]]*$/d' \
    > "$output_file"
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
  echo "📦 All configuration is self-contained in .devcontainer/"
  echo "   - Commit .devcontainer/ to share with team (recommended)"
  echo "   - Or add to .gitignore for personal use"
  echo "   - .mcp.json symlink created at root for Claude Code compatibility"
  echo
  echo "📋 Next steps:"
  echo "1. 🖥️  Open VS Code in $PROJECT_PATH"
  echo "2. 🐳 Click 'Reopen in Container' when prompted"
  echo "3. 🔒 Certificate setup runs automatically on first start"
  echo "   - If behind corporate proxy: place cert at .devcontainer/certs/zscaler.crt"
  echo "4. 🔐 Authenticate Claude Code if required"
  echo "5. ⚙️  MCP servers configured in .devcontainer/mcp-servers.json"
  echo "   - TaskMaster: disabled (enable via installTaskMaster: true in devcontainer.json)"
  echo "   - SuperClaude Core: context7, sequential-thinking"
  echo "   - SuperClaude UI: magic, playwright"
  echo "   - SuperClaude CodeOps: morphllm-fast-apply, serena"
  echo "   - Customize categories in .devcontainer/devcontainer.json"
  echo "   - Restart Claude Code after MCP changes"
  echo "6. 🚀 SuperClaude framework auto-configured:"
  echo "   - 19 specialized commands (/sc:help for full list)"
  echo "   - 9 cognitive personas (Architect, Frontend, Backend, etc.)"
  echo "   - Token optimization & git session checkpoints"
  echo "   - Try: /sc:status or /sc:explain"
  echo "7. 📚 See .devcontainer/docs/claude-setup-prompts.md for detailed setup"
  echo
  echo "🎯 Project location: $PROJECT_PATH"
}

# ---- Main orchestration ----
main() {
  validate_arguments "$@"
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