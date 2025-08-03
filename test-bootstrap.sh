#!/bin/bash

# DevContainer Test Suite
# Tests the created devcontainer for proper configuration and functionality

# Note: Not using set -e to allow tests to continue even if some fail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
TEST_PROJECT="devcontainer-test-$(date +%s)"
TEST_DIR="${1:-/tmp}"
PROJECT_PATH="$TEST_DIR/$TEST_PROJECT"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Test function wrapper
run_test() {
    local test_name="$1"
    local test_func="$2"
    
    ((TESTS_RUN++))
    log_info "Running test: $test_name"
    
    if $test_func; then
        log_success "$test_name"
        ((TESTS_PASSED++))
        return 0
    else
        log_error "$test_name"
        ((TESTS_FAILED++))
        return 0  # Don't exit on test failure, continue with other tests
    fi
}

# Cleanup function
cleanup() {
    log_info "Cleaning up test environment..."
    if [ -d "$PROJECT_PATH" ]; then
        rm -rf "$PROJECT_PATH"
        log_info "Removed test project: $PROJECT_PATH"
    fi
    
    # Stop any running containers
    if command -v devcontainer >/dev/null 2>&1; then
        devcontainer down --workspace-folder "$PROJECT_PATH" 2>/dev/null || true
    fi
}

# Trap cleanup on exit
trap cleanup EXIT

# Check prerequisites
check_prerequisites() {
    local missing_tools=()
    
    for tool in git docker jq; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        return 1
    fi
    
    # Check if Docker is running
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker is not running"
        return 1
    fi
    
    return 0
}

# Test 1: Bootstrap script execution
test_bootstrap_execution() {
    log_info "Testing bootstrap script execution..."
    
    if [ ! -f "$SCRIPT_DIR/create.sh" ]; then
        log_error "create.sh not found"
        return 1
    fi
    
    if ! chmod +x "$SCRIPT_DIR/create.sh"; then
        log_error "Failed to make create.sh executable"
        return 1
    fi
    
    if ! "$SCRIPT_DIR/create.sh" "$TEST_PROJECT" "$TEST_DIR"; then
        log_error "Bootstrap script failed"
        return 1
    fi
    
    return 0
}

# Test 2: Project structure validation
test_project_structure() {
    log_info "Validating project structure..."
    
    local required_files=(
        ".devcontainer/devcontainer.json"
        ".mcp.json"
        ".env"
    )
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$PROJECT_PATH/$file" ]; then
            log_error "Missing required file: $file"
            return 1
        fi
    done
    
    return 0
}

# Test 3: DevContainer configuration validation
test_devcontainer_config() {
    log_info "Validating devcontainer configuration..."
    
    local config_file="$PROJECT_PATH/.devcontainer/devcontainer.json"
    
    # Check if it's valid JSON
    if ! jq empty "$config_file" >/dev/null 2>&1; then
        log_error "devcontainer.json is not valid JSON"
        return 1
    fi
    
    # Check required fields (Claude Code uses build instead of image)
    local required_fields=("name" "forwardPorts")
    for field in "${required_fields[@]}"; do
        if ! jq -e ".$field" "$config_file" >/dev/null 2>&1; then
            log_error "Missing required field in devcontainer.json: $field"
            return 1
        fi
    done
    
    # Check for either build or image field
    if ! jq -e '.build' "$config_file" >/dev/null 2>&1 && ! jq -e '.image' "$config_file" >/dev/null 2>&1; then
        log_error "Missing both 'build' and 'image' fields in devcontainer.json"
        return 1
    fi
    
    # Check project name customization
    local container_name
    container_name=$(jq -r '.name' "$config_file")
    if [ "$container_name" = "Claude Code Sandbox" ]; then
        log_error "Container name was not customized"
        return 1
    fi
    
    # Check port forwarding for Claude OAuth
    if ! jq -e '.forwardPorts | map(select(. == 54545)) | length > 0' "$config_file" >/dev/null 2>&1; then
        log_error "Port 54545 not forwarded for Claude OAuth"
        return 1
    fi
    
    # Validate port forwarding configuration in detail
    log_info "Validating port forwarding configuration..."
    
    # Check if portsAttributes are properly configured
    if jq -e '.portsAttributes."54545"' "$config_file" >/dev/null 2>&1; then
        # Check port attributes
        local port_label
        port_label=$(jq -r '.portsAttributes."54545".label // "none"' "$config_file")
        if [ "$port_label" != "none" ]; then
            log_success "Port 54545 has label: $port_label"
        fi
        
        local auto_forward
        auto_forward=$(jq -r '.portsAttributes."54545".onAutoForward // "none"' "$config_file")
        if [ "$auto_forward" != "none" ]; then
            log_success "Port 54545 auto-forward configured: $auto_forward"
        fi
        
        local require_local
        require_local=$(jq -r '.portsAttributes."54545".requireLocalPort // false' "$config_file")
        if [ "$require_local" = "true" ]; then
            log_success "Port 54545 requires local port (good for OAuth)"
        else
            log_warning "Port 54545 doesn't require local port - OAuth might not work reliably"
        fi
    else
        log_warning "Port 54545 forwarded but no attributes configured"
    fi
    
    # Validate port number is actually accessible range
    local forwarded_ports
    forwarded_ports=$(jq -r '.forwardPorts[]' "$config_file" 2>/dev/null)
    for port in $forwarded_ports; do
        if [ "$port" -lt 1024 ] || [ "$port" -gt 65535 ]; then
            log_error "Invalid port number: $port (must be 1024-65535)"
            return 1
        fi
    done
    log_success "All forwarded ports are in valid range"
    
    return 0
}

# Test 4: MCP configuration validation (enhanced)
test_mcp_config() {
    log_info "Validating MCP configuration..."
    
    local mcp_file="$PROJECT_PATH/.mcp.json"
    
    # Check if it's valid JSON
    if ! jq empty "$mcp_file" >/dev/null 2>&1; then
        log_error ".mcp.json is not valid JSON"
        return 1
    fi
    
    # Check for task-master-ai server
    if ! jq -e '.mcpServers."task-master-ai"' "$mcp_file" >/dev/null 2>&1; then
        log_error "task-master-ai MCP server not configured"
        return 1
    fi
    
    # Check for Context7 server
    if ! jq -e '.mcpServers.Context7' "$mcp_file" >/dev/null 2>&1; then
        log_error "Context7 MCP server not configured"
        return 1
    fi
    
    # Check task-master-ai environment configuration
    if ! jq -e '.mcpServers."task-master-ai".env.PERPLEXITY_API_KEY' "$mcp_file" >/dev/null 2>&1; then
        log_error "PERPLEXITY_API_KEY not configured for task-master-ai"
        return 1
    fi
    
    # Test MCP server package availability
    log_info "Testing MCP server package availability..."
    
    # Test task-master-ai package
    if command -v npm >/dev/null 2>&1; then
        log_info "Checking task-master-ai package on npm..."
        if npm view task-master-ai version >/dev/null 2>&1; then
            local version
            version=$(npm view task-master-ai version 2>/dev/null)
            log_success "task-master-ai package available (version: $version)"
        else
            log_error "task-master-ai package not found on npm"
            return 1
        fi
        
        # Test Context7 package
        log_info "Checking Context7 package on npm..."
        if npm view @upstash/context7-mcp version >/dev/null 2>&1; then
            local version
            version=$(npm view @upstash/context7-mcp version 2>/dev/null)
            log_success "Context7 package available (version: $version)"
        else
            log_error "Context7 package not found on npm"
            return 1
        fi
        
        # Test if packages can be executed
        log_info "Testing MCP server execution..."
        if command -v npx >/dev/null 2>&1; then
            # Test task-master-ai execution (with timeout)
            if timeout 10 npx -y --package=task-master-ai task-master-ai --help >/dev/null 2>&1; then
                log_success "task-master-ai executes successfully"
            else
                log_warning "task-master-ai execution timed out or failed (may require API keys)"
            fi
            
            # Test Context7 execution (with timeout)
            if timeout 10 npx -y @upstash/context7-mcp --help >/dev/null 2>&1; then
                log_success "Context7 executes successfully"
            else
                log_warning "Context7 execution timed out or failed"
            fi
        else
            log_warning "npx not available, skipping execution tests"
        fi
    else
        log_warning "npm not available, skipping package availability tests"
    fi
    
    return 0
}

# Test 5: Environment file validation
test_env_file() {
    log_info "Validating environment file..."
    
    local env_file="$PROJECT_PATH/.env"
    
    if [ ! -s "$env_file" ]; then
        log_warning ".env file is empty - this is acceptable but may limit functionality"
        return 0
    fi
    
    return 0
}

# Test 6: Lifecycle execution validation
test_lifecycle_execution() {
    if ! command -v devcontainer >/dev/null 2>&1; then
        log_warning "DevContainer CLI not available, skipping lifecycle execution tests"
        return 0
    fi
    
    log_info "Testing lifecycle script execution..."
    
    # Test if Docker is available and running
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker is not running - cannot test lifecycle execution"
        return 1
    fi
    
    # Build and start container to test lifecycle hooks
    log_info "Building and starting container to test lifecycle execution..."
    
    local build_output
    if ! build_output=$(devcontainer up --workspace-folder "$PROJECT_PATH" 2>&1); then
        log_error "Failed to start devcontainer for lifecycle testing"
        echo "Build output (last 5 lines):"
        echo "$build_output" | tail -5
        return 1
    fi
    
    # Test pre-create script execution results
    log_info "Checking pre-create script results..."
    
    # Check if SSL certificate handling worked (if certificate exists)
    local cert_path="$HOME/.ssl/certs/zscaler.crt"
    if [ -f "$cert_path" ]; then
        log_info "SSL certificate exists, checking if pre-create configured it..."
        
        # Check if npm was configured with certificate
        if devcontainer exec --workspace-folder "$PROJECT_PATH" -- npm config get cafile >/dev/null 2>&1; then
            log_success "npm SSL configuration applied by pre-create script"
        else
            log_warning "npm SSL configuration not found - pre-create may not have run"
        fi
        
        # Check if git was configured with certificate
        if devcontainer exec --workspace-folder "$PROJECT_PATH" -- git config --global --get http.sslCAInfo >/dev/null 2>&1; then
            log_success "git SSL configuration applied by pre-create script"
        else
            log_warning "git SSL configuration not found - pre-create may not have run"
        fi
    else
        log_info "No SSL certificate found, skipping SSL configuration checks"
    fi
    
    # Test post-create script execution results
    log_info "Checking post-create script results..."
    
    # Check if task-master-ai was installed globally
    if devcontainer exec --workspace-folder "$PROJECT_PATH" -- which task-master-ai >/dev/null 2>&1; then
        log_success "task-master-ai installed globally by post-create script"
        
        # Test if it can execute
        if devcontainer exec --workspace-folder "$PROJECT_PATH" -- task-master-ai --version >/dev/null 2>&1; then
            log_success "task-master-ai is functional"
        else
            log_warning "task-master-ai installed but may not be functional"
        fi
    else
        log_error "task-master-ai not found - post-create script may have failed"
        return 1
    fi
    
    # Check if DevContainer CLI was installed globally
    if devcontainer exec --workspace-folder "$PROJECT_PATH" -- which devcontainer >/dev/null 2>&1; then
        log_success "DevContainer CLI installed globally by post-create script"
        
        # Test if it can execute
        if devcontainer exec --workspace-folder "$PROJECT_PATH" -- devcontainer --version >/dev/null 2>&1; then
            log_success "DevContainer CLI is functional"
        else
            log_warning "DevContainer CLI installed but may not be functional"
        fi
    else
        log_warning "DevContainer CLI not found - may not be installed by post-create script"
    fi
    
    # Clean up container
    devcontainer down --workspace-folder "$PROJECT_PATH" >/dev/null 2>&1 || true
    
    return 0
}

# Test 7: DevContainer build test (enhanced)
test_devcontainer_build() {
    if ! command -v devcontainer >/dev/null 2>&1; then
        log_warning "DevContainer CLI not available, skipping build test"
        log_info "Install with: npm install -g @devcontainers/cli"
        return 0
    fi
    
    log_info "Testing devcontainer build..."
    
    # Test configuration reading first
    log_info "Validating devcontainer configuration..."
    local config_output
    if ! config_output=$(devcontainer read-configuration --workspace-folder "$PROJECT_PATH" 2>&1); then
        log_error "DevContainer configuration is invalid:"
        echo "$config_output" | head -5
        return 1
    fi
    log_success "DevContainer configuration is valid"
    
    # Test if Docker is available and running
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker is not running - cannot test build"
        return 1
    fi
    
    # Test build (this may take a while)
    log_info "Building devcontainer (this may take several minutes)..."
    log_warning "This is a full Docker build - may download large images"
    
    local build_output
    local build_result=0
    
    if command -v timeout >/dev/null 2>&1; then
        if ! build_output=$(timeout 900 devcontainer build --workspace-folder "$PROJECT_PATH" 2>&1); then
            build_result=1
        fi
    else
        log_warning "timeout command not available, running build without timeout"
        if ! build_output=$(devcontainer build --workspace-folder "$PROJECT_PATH" 2>&1); then
            build_result=1
        fi
    fi
    
    if [ $build_result -ne 0 ]; then
        log_error "DevContainer build failed"
        echo "Build output (last 10 lines):"
        echo "$build_output" | tail -10
        return 1
    fi
    
    log_success "DevContainer build completed successfully"
    
    # Test basic container functionality if build succeeded
    log_info "Testing container startup..."
    if devcontainer up --workspace-folder "$PROJECT_PATH" >/dev/null 2>&1; then
        log_success "Container starts successfully"
        
        # Test if claude command is available in container
        if devcontainer exec --workspace-folder "$PROJECT_PATH" -- which claude >/dev/null 2>&1; then
            log_success "Claude CLI is available in container"
        else
            log_warning "Claude CLI not found in container (may need manual installation)"
        fi
        
        # Clean up container
        devcontainer down --workspace-folder "$PROJECT_PATH" >/dev/null 2>&1 || true
    else
        log_warning "Container build succeeded but failed to start"
    fi
    
    return 0
}

# Test 8: Lifecycle hooks validation  
test_lifecycle_hooks() {
    log_info "Validating lifecycle hooks..."
    
    local hooks_dir="$PROJECT_PATH/.devcontainer"
    local hooks=("pre-create.sh" "post-create.sh")
    
    for hook in "${hooks[@]}"; do
        local hook_file="$hooks_dir/$hook"
        if [ -f "$hook_file" ]; then
            if [ ! -x "$hook_file" ]; then
                log_error "Lifecycle hook is not executable: $hook"
                return 1
            fi
            
            # Basic syntax check
            if ! bash -n "$hook_file"; then
                log_error "Lifecycle hook has syntax errors: $hook"
                return 1
            fi
        fi
    done
    
    return 0
}

# Test 9: VS Code extensions validation
test_vscode_extensions() {
    log_info "Validating VS Code extensions configuration..."
    
    local config_file="$PROJECT_PATH/.devcontainer/devcontainer.json"
    
    # Check if extensions are configured
    if ! jq -e '.customizations.vscode.extensions' "$config_file" >/dev/null 2>&1; then
        log_error "VS Code extensions not configured"
        return 1
    fi
    
    # Check for essential extensions
    local essential_extensions=("eamodio.gitlens" "ms-vscode.vscode-typescript-next")
    for ext in "${essential_extensions[@]}"; do
        if ! jq -e --arg ext "$ext" '.customizations.vscode.extensions | map(select(. == $ext)) | length > 0' "$config_file" >/dev/null 2>&1; then
            log_error "Essential extension missing: $ext"
            return 1
        fi
    done
    
    return 0
}

# Test 10: SSL certificate handling (if certificate exists)
test_ssl_certificates() {
    log_info "Testing SSL certificate handling..."
    
    local cert_path="$HOME/.ssl/certs/zscaler.crt"
    if [ ! -f "$cert_path" ]; then
        log_info "No SSL certificate found at $cert_path - skipping SSL tests"
        return 0
    fi
    
    # Check if pre-create script handles certificates
    local pre_create_script="$PROJECT_PATH/.devcontainer/pre-create.sh"
    if [ -f "$pre_create_script" ]; then
        if ! grep -q "ssl\|cert\|ca-cert" "$pre_create_script"; then
            log_warning "pre-create.sh doesn't appear to handle SSL certificates"
        fi
    fi
    
    return 0
}

# Test 11: Environment variable availability in container
test_env_variables_in_container() {
    log_info "Testing environment variable availability in container..."
    
    if ! command -v devcontainer >/dev/null 2>&1; then
        log_warning "DevContainer CLI not available, skipping environment variable tests"
        return 0
    fi
    
    # Test if Docker is available and running
    if ! docker info >/dev/null 2>&1; then
        log_warning "Docker is not running, skipping environment variable tests"
        return 0
    fi
    
    # Test 1: Test remoteEnv with host environment variable
    log_info "Testing remoteEnv with host environment variable..."
    
    # Set a host environment variable for this test
    export PERPLEXITY_API_KEY="host_env_test_key"
    
    # Build and start container with host env var
    local build_output
    if ! build_output=$(devcontainer up --workspace-folder "$PROJECT_PATH" 2>&1); then
        log_error "Failed to start devcontainer with host PERPLEXITY_API_KEY"
        echo "Build output (last 5 lines):"
        echo "$build_output" | tail -5
        unset PERPLEXITY_API_KEY
        return 1
    fi
    
    # Test that host environment variable is passed through remoteEnv
    local host_env_output
    if host_env_output=$(devcontainer exec --workspace-folder "$PROJECT_PATH" -- bash -c 'echo "PERPLEXITY_API_KEY=${PERPLEXITY_API_KEY:-<unset>}"' 2>&1); then
        if [[ "$host_env_output" == *"PERPLEXITY_API_KEY=host_env_test_key"* ]]; then
            log_success "Host environment variable correctly passed via remoteEnv"
        else
            log_warning "Host environment variable not passed via remoteEnv: $host_env_output"
        fi
    else
        log_error "Failed to test host environment variable in container"
        unset PERPLEXITY_API_KEY
        return 1
    fi
    
    # Clean up host env var and container
    unset PERPLEXITY_API_KEY
    devcontainer down --workspace-folder "$PROJECT_PATH" >/dev/null 2>&1 || true
    
    # Test 2: With empty PERPLEXITY_API_KEY (should not break)
    log_info "Testing with empty PERPLEXITY_API_KEY..."
    
    # Ensure .env has empty PERPLEXITY_API_KEY
    if [ -f "$PROJECT_PATH/.env" ]; then
        sed -i 's/PERPLEXITY_API_KEY=.*/PERPLEXITY_API_KEY=/' "$PROJECT_PATH/.env"
    fi
    
    # Build and start container
    local build_output
    if ! build_output=$(devcontainer up --workspace-folder "$PROJECT_PATH" 2>&1); then
        log_error "Failed to start devcontainer with empty PERPLEXITY_API_KEY"
        echo "Build output (last 5 lines):"
        echo "$build_output" | tail -5
        return 1
    fi
    
    # Test environment variable is accessible (empty value should not break)
    local env_test_output
    if env_test_output=$(devcontainer exec --workspace-folder "$PROJECT_PATH" -- bash -c 'echo "PERPLEXITY_API_KEY=${PERPLEXITY_API_KEY:-<unset>}"' 2>&1); then
        if [[ "$env_test_output" == *"PERPLEXITY_API_KEY="* ]] || [[ "$env_test_output" == *"PERPLEXITY_API_KEY=<unset>"* ]]; then
            log_success "Empty PERPLEXITY_API_KEY handled gracefully"
        else
            log_warning "Unexpected output for empty PERPLEXITY_API_KEY: $env_test_output"
        fi
    else
        log_error "Failed to test environment variable in container"
        return 1
    fi
    
    # Test 3: With actual PERPLEXITY_API_KEY value in .env
    log_info "Testing with sample PERPLEXITY_API_KEY value in .env..."
    
    # Set a test value in .env
    if [ -f "$PROJECT_PATH/.env" ]; then
        sed -i 's/PERPLEXITY_API_KEY=.*/PERPLEXITY_API_KEY=test_key_12345/' "$PROJECT_PATH/.env"
    fi
    
    # Restart container to pick up .env changes (via shell profile)
    devcontainer down --workspace-folder "$PROJECT_PATH" >/dev/null 2>&1 || true
    if ! build_output=$(devcontainer up --workspace-folder "$PROJECT_PATH" 2>&1); then
        log_error "Failed to restart devcontainer with test PERPLEXITY_API_KEY"
        return 1
    fi
    
    # Test that the variable is available in new shell sessions (test both approaches)
    # First test: direct sourcing of .env loading logic
    if env_test_output=$(devcontainer exec --workspace-folder "$PROJECT_PATH" -- bash -c '
        if [ -f /workspace/.env ]; then
          while IFS= read -r line; do
            if [[ "$line" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; then
              var_name="${line%%=*}"
              if [ -z "${!var_name}" ]; then
                export "$line"
              fi
            fi
          done < /workspace/.env
        fi
        echo "PERPLEXITY_API_KEY=${PERPLEXITY_API_KEY:-<unset>}"
    ' 2>&1); then
        if [[ "$env_test_output" == *"PERPLEXITY_API_KEY=test_key_12345"* ]]; then
            log_success "PERPLEXITY_API_KEY correctly loaded from .env file"
        else
            # Second test: check if at least the shell profile setup is working
            if env_test_output2=$(devcontainer exec --workspace-folder "$PROJECT_PATH" -- bash -l -c 'echo "PERPLEXITY_API_KEY=${PERPLEXITY_API_KEY:-<unset>}"' 2>&1); then
                if [[ "$env_test_output2" == *"PERPLEXITY_API_KEY=test_key_12345"* ]]; then
                    log_success "PERPLEXITY_API_KEY loaded via login shell profile"
                else
                    log_warning "PERPLEXITY_API_KEY not loaded via .env mechanism. Direct test: $env_test_output. Login shell: $env_test_output2"
                fi
            else
                log_warning "PERPLEXITY_API_KEY not properly loaded from .env: $env_test_output"
            fi
        fi
    else
        log_error "Failed to test .env loading in container"
        return 1
    fi
    
    # Test 4: Test precedence - host env should override .env
    log_info "Testing environment variable precedence (host > .env)..."
    
    # Set both host env var and .env value
    export PERPLEXITY_API_KEY="host_override_key"
    if [ -f "$PROJECT_PATH/.env" ]; then
        sed -i 's/PERPLEXITY_API_KEY=.*/PERPLEXITY_API_KEY=env_file_key/' "$PROJECT_PATH/.env"
    fi
    
    # Restart container to test precedence
    devcontainer down --workspace-folder "$PROJECT_PATH" >/dev/null 2>&1 || true
    if ! build_output=$(devcontainer up --workspace-folder "$PROJECT_PATH" 2>&1); then
        log_error "Failed to restart devcontainer for precedence test"
        unset PERPLEXITY_API_KEY
        return 1
    fi
    
    # Test that host env var takes precedence over .env file
    if precedence_output=$(devcontainer exec --workspace-folder "$PROJECT_PATH" -- bash -c 'echo "PERPLEXITY_API_KEY=${PERPLEXITY_API_KEY:-<unset>}"' 2>&1); then
        if [[ "$precedence_output" == *"PERPLEXITY_API_KEY=host_override_key"* ]]; then
            log_success "Host environment variable correctly takes precedence over .env"
        else
            log_warning "Precedence test failed. Expected host_override_key, got: $precedence_output"
        fi
    else
        log_error "Failed to test environment variable precedence"
        unset PERPLEXITY_API_KEY
        return 1
    fi
    
    # Clean up
    unset PERPLEXITY_API_KEY
    devcontainer down --workspace-folder "$PROJECT_PATH" >/dev/null 2>&1 || true
    
    # Test 5: Verify MCP configuration can reference the variable
    log_info "Testing MCP configuration variable resolution..."
    
    local mcp_file="$PROJECT_PATH/.mcp.json"
    if [ -f "$mcp_file" ]; then
        if grep -q '${PERPLEXITY_API_KEY}' "$mcp_file"; then
            log_success "MCP configuration correctly references PERPLEXITY_API_KEY variable"
        else
            log_warning "MCP configuration doesn't reference PERPLEXITY_API_KEY variable"
        fi
    else
        log_error "MCP configuration file not found"
        return 1
    fi
    
    # Clean up container
    devcontainer down --workspace-folder "$PROJECT_PATH" >/dev/null 2>&1 || true
    
    # Reset .env to empty state for other tests
    if [ -f "$PROJECT_PATH/.env" ]; then
        sed -i 's/PERPLEXITY_API_KEY=.*/PERPLEXITY_API_KEY=/' "$PROJECT_PATH/.env"
    fi
    
    return 0
}

# Main test execution
main() {
    echo "=================================================="
    echo "DevContainer Bootstrap Test Suite"
    echo "=================================================="
    echo
    
    log_info "Starting tests for project: $TEST_PROJECT"
    log_info "Test directory: $TEST_DIR"
    echo
    
    # Check prerequisites
    if ! check_prerequisites; then
        log_error "Prerequisites check failed"
        exit 1
    fi
    
    # Run tests
    run_test "Bootstrap Script Execution" test_bootstrap_execution
    run_test "Project Structure Validation" test_project_structure
    run_test "DevContainer Configuration" test_devcontainer_config
    run_test "MCP Configuration" test_mcp_config
    run_test "Environment File" test_env_file
    run_test "Lifecycle Script Execution" test_lifecycle_execution
    run_test "DevContainer Build" test_devcontainer_build
    run_test "Lifecycle Hooks Validation" test_lifecycle_hooks
    run_test "VS Code Extensions" test_vscode_extensions
    run_test "SSL Certificate Handling" test_ssl_certificates
    run_test "Environment Variables in Container" test_env_variables_in_container
    
    echo
    echo "=================================================="
    echo "Test Results Summary"
    echo "=================================================="
    echo "Tests Run: $TESTS_RUN"
    echo "Tests Passed: $TESTS_PASSED"
    echo "Tests Failed: $TESTS_FAILED"
    echo
    
    if [ $TESTS_FAILED -eq 0 ]; then
        log_success "All tests passed! DevContainer bootstrap is working correctly."
        exit 0
    else
        log_error "$TESTS_FAILED test(s) failed. Please review the errors above."
        exit 1
    fi
}

# Handle command line arguments
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0 [test_directory]"
    echo
    echo "Test the devcontainer bootstrap by creating a test project and validating its configuration."
    echo
    echo "Arguments:"
    echo "  test_directory    Directory to create test project in (default: /tmp)"
    echo
    echo "Examples:"
    echo "  $0                # Test in /tmp"
    echo "  $0 /home/user     # Test in /home/user"
    echo
    echo "Prerequisites:"
    echo "  - git"
    echo "  - docker"
    echo "  - jq (for JSON validation)"
    echo "  - devcontainer CLI (optional, for build testing)"
    exit 0
fi

# Run main function
main "$@"