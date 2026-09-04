#!/bin/bash
# Admiral Docker Entrypoint
# Sets up gh CLI authentication and SSH keys from environment variables before starting OpenCode
#
# NOTE: This script runs as the 'opencode' user (non-root)

set -e

# Home directory for opencode user
HOME_DIR="/home/opencode"
HOST_OPENCODE_SHARE_DIR="$HOME_DIR/.host-opencode-share"
PLAYWRIGHT_AUTH_DIR="$HOME_DIR/.local/share/playwright"
PLAYWRIGHT_AUTH_FILE="$PLAYWRIGHT_AUTH_DIR/auth.json"
PLAYWRIGHT_CLI="$(npm root -g)/@playwright/mcp/node_modules/playwright/cli.js"
PLAYWRIGHT_NODE_PATH="$(dirname "$(dirname "$PLAYWRIGHT_CLI")")"

run_playwright_dev_login() {
    if [ -z "${DEV_WORKSPACE:-}" ]; then
        return 0
    fi

    if [ -z "${DEV_LOGIN_USERNAME:-}" ] || [ -z "${DEV_LOGIN_PASSWORD:-}" ]; then
        echo "Skipping Playwright dev login: DEV_LOGIN_USERNAME or DEV_LOGIN_PASSWORD is not set"
        return 0
    fi

    if [ ! -f "$PLAYWRIGHT_CLI" ]; then
        echo "Skipping Playwright dev login: bundled Playwright CLI not found at $PLAYWRIGHT_CLI"
        return 0
    fi

    mkdir -p "$PLAYWRIGHT_AUTH_DIR"

    local login_script="${DEV_LOGIN_SCRIPT:-/opt/admiral-playwright/login-dev-workspace.js}"
    if [ ! -f "$login_script" ]; then
        echo "Skipping Playwright dev login: script not found at $login_script"
        return 0
    fi

    echo "Generating Playwright auth state for dev-${DEV_WORKSPACE}..."
    rm -f "$PLAYWRIGHT_AUTH_FILE"
    NODE_PATH="$PLAYWRIGHT_NODE_PATH" node "$login_script"

    if [ -f "$PLAYWRIGHT_AUTH_FILE" ]; then
        chmod 600 "$PLAYWRIGHT_AUTH_FILE"
    else
        echo "Playwright dev login completed but did not create $PLAYWRIGHT_AUTH_FILE" >&2
        return 1
    fi

    unset DEV_LOGIN_USERNAME
    unset DEV_LOGIN_PASSWORD
}

# =============================================================================
# OpenCode Auth File Setup
# =============================================================================
# Copy auth.json from a read-only host directory mount. This avoids flaky Docker
# Desktop single-file bind mounts into nested container paths.

mkdir -p "$HOME_DIR/.local/share/opencode"
mkdir -p "$PLAYWRIGHT_AUTH_DIR"

if [ -f "$HOST_OPENCODE_SHARE_DIR/auth.json" ]; then
    cp "$HOST_OPENCODE_SHARE_DIR/auth.json" "$HOME_DIR/.local/share/opencode/auth.json"
    chmod 600 "$HOME_DIR/.local/share/opencode/auth.json"
fi

# =============================================================================
# SSH Key Setup
# =============================================================================
# SSH keys can be passed via environment variables to avoid permission issues
# with mounted .ssh directories. The keys are base64-encoded in .env.
#
# To encode your key: cat ~/.ssh/id_ed25519 | base64 -w0
# To encode your public key: cat ~/.ssh/id_ed25519.pub | base64 -w0
#
# NOTE: SSH config (host restrictions, proxy settings) is handled by the
# system-wide config at /etc/ssh/ssh_config.d/99-admiral-network-lockdown.conf
# which is baked into the Docker image and cannot be modified by this user.

mkdir -p "$HOME_DIR/.ssh"
chmod 700 "$HOME_DIR/.ssh"

if [ -n "$SSH_PRIVATE_KEY_BASE64" ]; then
    echo "Setting up SSH private key..."
    echo "$SSH_PRIVATE_KEY_BASE64" | base64 -d > "$HOME_DIR/.ssh/id_ed25519"
    chmod 600 "$HOME_DIR/.ssh/id_ed25519"
fi

if [ -n "$SSH_PUBLIC_KEY_BASE64" ]; then
    echo "Setting up SSH public key..."
    echo "$SSH_PUBLIC_KEY_BASE64" | base64 -d > "$HOME_DIR/.ssh/id_ed25519.pub"
    chmod 644 "$HOME_DIR/.ssh/id_ed25519.pub"
fi

# Add GitHub hosts to known_hosts if not already present
ssh-keyscan -H github.com >> "$HOME_DIR/.ssh/known_hosts" 2>/dev/null || true
ssh-keyscan -H github.cms.gov >> "$HOME_DIR/.ssh/known_hosts" 2>/dev/null || true

# =============================================================================
# GitHub CLI Authentication
# =============================================================================
# gh stores tokens differently on Linux (in ~/.config/gh/hosts.yml)
# We authenticate using tokens from environment variables
#
# IMPORTANT: gh CLI detects GITHUB_*_TOKEN env vars and tries to use them directly
# instead of storing credentials. We must temporarily unset them during login
# so gh stores the token in hosts.yml for git credential helper to use.

if [ -n "$GITHUB_ENTERPRISE_TOKEN" ]; then
    echo "Setting up gh auth for github.cms.gov..."
    _token="$GITHUB_ENTERPRISE_TOKEN"
    unset GITHUB_ENTERPRISE_TOKEN
    echo "$_token" | gh auth login --hostname github.cms.gov --with-token 2>/dev/null || true
    export GITHUB_ENTERPRISE_TOKEN="$_token"
fi

if [ -n "$GITHUB_PUBLIC_TOKEN" ]; then
    echo "Setting up gh auth for github.com..."
    _token="$GITHUB_PUBLIC_TOKEN"
    unset GITHUB_PUBLIC_TOKEN
    echo "$_token" | gh auth login --hostname github.com --with-token 2>/dev/null || true
    export GITHUB_PUBLIC_TOKEN="$_token"
fi

# Configure git to use gh as credential helper (if not already set)
gh auth setup-git --hostname github.cms.gov 2>/dev/null || true
gh auth setup-git --hostname github.com 2>/dev/null || true

# =============================================================================
# NPM / JFrog Artifactory Configuration
# =============================================================================
# Create global .npmrc for JFrog Artifactory access.
# Supports both JFROG_TOKEN (preferred) and legacy iddoc_jfrog_token for backwards compatibility.
JFROG_TOKEN="${JFROG_TOKEN:-$iddoc_jfrog_token}"

if [ -n "$JFROG_TOKEN" ]; then
    echo "Setting up npm registry for JFrog Artifactory..."
    cat > "$HOME_DIR/.npmrc" << EOF
//artifactory.cloud.cms.gov/artifactory/api/npm/iddoc-group/:_authToken=${JFROG_TOKEN}
//artifactory.cloud.cms.gov/artifactory/api/npm/my-libs/:_authToken=${JFROG_TOKEN}
//artifactory.cloud.cms.gov/artifactory/api/npm/iddoc-libs/:_authToken=${JFROG_TOKEN}
registry=https://artifactory.cloud.cms.gov/artifactory/api/npm/iddoc-group/
@iddoc:registry=https://artifactory.cloud.cms.gov/artifactory/api/npm/iddoc-libs/
proxy=http://egress-proxy:3128
https-proxy=http://egress-proxy:3128
EOF
    chmod 600 "$HOME_DIR/.npmrc"
fi

# =============================================================================
# OpenCode .opencode Directory Setup
# =============================================================================
# The .opencode directory (tools, commands) is baked into /opt/admiral-opencode
# but ~/admiral is a volume mount that would shadow it. We symlink it in.

if [ -d "/opt/admiral-opencode" ] && [ ! -e "$HOME_DIR/admiral/.opencode" ]; then
    echo "Setting up .opencode symlink..."
    mkdir -p "$HOME_DIR/admiral"
    ln -sf /opt/admiral-opencode "$HOME_DIR/admiral/.opencode"
elif [ -d "/opt/admiral-opencode" ] && [ -d "$HOME_DIR/admiral/.opencode" ] && [ ! -L "$HOME_DIR/admiral/.opencode" ]; then
    # .opencode exists as a real directory (from volume), replace with symlink
    echo "Replacing .opencode directory with symlink to baked-in version..."
    rm -rf "$HOME_DIR/admiral/.opencode"
    ln -sf /opt/admiral-opencode "$HOME_DIR/admiral/.opencode"
fi

# =============================================================================
# External AI DX Adapter Setup
# =============================================================================
# OPENCODE_CONFIG_DIR must be writable because OpenCode may install dependencies
# into that directory. Keep a writable adapter locally and symlink its contents
# to the mounted external AI DX source.

EXTERNAL_SOURCE_ROOT_DIR="$HOME_DIR/.config/opencode/external-source-root"
EXTERNAL_SOURCE_DIR="$HOME_DIR/.config/opencode/external-source"
EXTERNAL_ADAPTER_DIR="$HOME_DIR/.config/opencode/external-adapter"
CONTAINER_ADMIRAL_DIR="$HOME_DIR/admiral"

resolve_runtime_external_source_dir() {
    local configured_path="${AI_DX_SOURCE_PATH:-}"
    local host_admiral_dir="${HOST_ADMIRAL_DIR:-}"
    local mapped_path=""

    if [ -n "$configured_path" ] && [ -n "$host_admiral_dir" ]; then
        case "$configured_path" in
            "$host_admiral_dir")
                mapped_path="$CONTAINER_ADMIRAL_DIR"
                ;;
            "$host_admiral_dir"/*)
                mapped_path="$CONTAINER_ADMIRAL_DIR/${configured_path#"$host_admiral_dir"/}"
                ;;
        esac
    fi

    if [ -n "$mapped_path" ]; then
        if [ -d "$mapped_path/.ai" ]; then
            printf '%s\n' "$mapped_path/.ai"
            return 0
        fi

        if [ -d "$mapped_path" ] && [ "$(basename "$mapped_path")" = ".ai" ]; then
            printf '%s\n' "$mapped_path"
            return 0
        fi
    fi

    if [ -d "$EXTERNAL_SOURCE_ROOT_DIR/.ai" ]; then
        printf '%s\n' "$EXTERNAL_SOURCE_ROOT_DIR/.ai"
        return 0
    fi

    if [ -d "$EXTERNAL_SOURCE_ROOT_DIR" ]; then
        printf '%s\n' "$EXTERNAL_SOURCE_ROOT_DIR"
        return 0
    fi

    return 1
}

rm -rf "$EXTERNAL_SOURCE_DIR"
if RESOLVED_EXTERNAL_SOURCE_DIR="$(resolve_runtime_external_source_dir)"; then
    ln -sf "$RESOLVED_EXTERNAL_SOURCE_DIR" "$EXTERNAL_SOURCE_DIR"
fi

mkdir -p "$EXTERNAL_ADAPTER_DIR"
rm -rf "$EXTERNAL_ADAPTER_DIR/agents" "$EXTERNAL_ADAPTER_DIR/skills" "$EXTERNAL_ADAPTER_DIR/commands" "$EXTERNAL_ADAPTER_DIR/tools" "$EXTERNAL_ADAPTER_DIR/plugins" "$EXTERNAL_ADAPTER_DIR/themes"

if [ -d "$EXTERNAL_SOURCE_DIR/opencode/agents" ]; then
    ln -sf "$EXTERNAL_SOURCE_DIR/opencode/agents" "$EXTERNAL_ADAPTER_DIR/agents"
fi

if [ -d "$EXTERNAL_SOURCE_DIR/skills" ]; then
    ln -sf "$EXTERNAL_SOURCE_DIR/skills" "$EXTERNAL_ADAPTER_DIR/skills"
fi

if [ -d "$EXTERNAL_SOURCE_DIR/opencode/commands" ]; then
    ln -sf "$EXTERNAL_SOURCE_DIR/opencode/commands" "$EXTERNAL_ADAPTER_DIR/commands"
fi

if [ -d "$EXTERNAL_SOURCE_DIR/opencode/tools" ]; then
    ln -sf "$EXTERNAL_SOURCE_DIR/opencode/tools" "$EXTERNAL_ADAPTER_DIR/tools"
fi

if [ -d "$EXTERNAL_SOURCE_DIR/opencode/plugins" ]; then
    ln -sf "$EXTERNAL_SOURCE_DIR/opencode/plugins" "$EXTERNAL_ADAPTER_DIR/plugins"
fi

if [ -d "$EXTERNAL_SOURCE_DIR/opencode/themes" ]; then
    ln -sf "$EXTERNAL_SOURCE_DIR/opencode/themes" "$EXTERNAL_ADAPTER_DIR/themes"
fi

# =============================================================================
# Playwright Dev Environment Auth Setup
# =============================================================================
run_playwright_dev_login

# =============================================================================
# Start OpenCode
# =============================================================================
exec "$@"
