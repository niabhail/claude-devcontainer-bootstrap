#!/usr/bin/env bash

# Global variables
PROJECT=""
WORKDIR=""
PROJECT_NAME=""
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BOOTSTRAP_DIR="$SCRIPT_DIR"
PROJECT_PATH=""
DEVCONTAINER_PATH=""

# ---- Argument validation and setup ----
validate_arguments() {
  if [ -z "$1" ]; then
    echo "Usage: $0 <project_name> [workdir]"
    echo "  project_name: Name of the project to create"
    echo "  workdir: Optional working directory (absolute or relative path)"
    echo "           If not provided, creates in current directory"
    echo "Examples:"
    echo "  $0 myproject                  # Creates ./myproject"
    echo "  $0 myproject /home/user/work  # Creates /home/user/work/myproject"
    echo "  $0 myproject ../projects      # Creates ../projects/myproject"
    exit 1
  fi

  PROJECT="$1"
  WORKDIR="${2:-.}"
  PROJECT_NAME="$(basename "$PROJECT")"
  PROJECT_PATH="$WORKDIR/$PROJECT"
  DEVCONTAINER_PATH="$PROJECT_PATH/.devcontainer"

  # Handle relative paths
  if [[ ! "$WORKDIR" = /* ]]; then
    WORKDIR="$SCRIPT_DIR/$WORKDIR"
    PROJECT_PATH="$WORKDIR/$PROJECT"
    DEVCONTAINER_PATH="$PROJECT_PATH/.devcontainer"
  fi
}

# ---- Project structure setup ----
setup_project_structure() {
  echo "🚀 Scaffolding new project: $PROJECT in $WORKDIR"
  mkdir -p "$PROJECT_PATH"
  mkdir -p "$PROJECT_PATH/docs"
  mkdir -p "$DEVCONTAINER_PATH/certs"
  mkdir -p "$DEVCONTAINER_PATH/scripts"
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

# ---- Copy template files ----
copy_template_files() {
  echo "📄 Copying configuration templates..."
  cp "$BOOTSTRAP_DIR/templates/.env.example" "$PROJECT_PATH/.env"
  cp "$BOOTSTRAP_DIR/templates/mcp-servers.json" "$PROJECT_PATH/.mcp.json"
  cp "$BOOTSTRAP_DIR/templates/claude-setup-prompts.md" "$PROJECT_PATH/docs/"
  cp "$BOOTSTRAP_DIR/templates/firewall-allowlist.txt" "$PROJECT_PATH/docs/firewall-allowlist.txt"
  
  echo "📄 Copying script templates..."
  cp "$BOOTSTRAP_DIR/templates/scripts/setup-certificates.sh" "$DEVCONTAINER_PATH/scripts/setup-certificates.sh"
  cp "$BOOTSTRAP_DIR/templates/scripts/init-firewall.sh" "$DEVCONTAINER_PATH/scripts/init-firewall.sh"
  chmod +x "$DEVCONTAINER_PATH/scripts"/*.sh
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
  echo "✅ Initial setup complete for: $PROJECT"
  echo
  echo "📋 Next steps:"
  echo "1. 🔒 Certificate setup will run automatically when container starts"
  echo "   - If behind corporate proxy, ensure cert is at .devcontainer/certs/zscaler.crt"
  echo "2. 🖥️  Open VS Code in this project directory and select 'Reopen in Container' when prompted"
  echo "3. 🔐 Authenticate Claude Code if required"
  echo "4. ⚙️  MCP servers (task-master-ai, Context7) are pre-configured in .mcp.json"
  echo "   - Customize by editing the file if needed"
  echo "   - Restart Claude Code session after any MCP changes"
  echo "5. 📚 After devcontainer starts, follow prompts in docs/claude-setup-prompts.md"
  echo
  echo "🎯 Project created at: $PROJECT_PATH"
}

# ---- Main orchestration ----
main() {
  validate_arguments "$@"
  setup_project_structure
  copy_local_features
  copy_template_files
  generate_devcontainer_config
  setup_certificate_support
  display_completion_message
}

# Run main with all arguments
main "$@"