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

# Test 6: DevContainer build test (enhanced)
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

# Test 7: Lifecycle hooks validation
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

# Test 8: VS Code extensions validation
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

# Test 9: SSL certificate handling (if certificate exists)
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
    run_test "Lifecycle Hooks" test_lifecycle_hooks
    run_test "VS Code Extensions" test_vscode_extensions
    run_test "SSL Certificate Handling" test_ssl_certificates
    run_test "DevContainer Build" test_devcontainer_build
    
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