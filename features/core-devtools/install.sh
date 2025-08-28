#!/usr/bin/env bash
set -e

# --- Install certificate management tools FIRST ---
echo "[core-devtools] Installing certificate management tools..."
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y ca-certificates openssl curl

# --- Install firewall tools for enterprise security ---
echo "[core-devtools] Installing firewall tools..."
apt-get install -y iptables ipset dnsutils jq aggregate

echo "[core-devtools] Installing selected developer tools..."

USER_HOME=$(getent passwd $USERNAME | cut -d: -f6)

# --- Install selected npm CLIs ---
if [ "${_OPTION_INSTALLTASKMASTER}" = "true" ]; then
  sudo -u $USERNAME npm install -g task-master-ai
fi
if [ "${_OPTION_INSTALLDEVCONTAINERSCLI}" = "true" ]; then
  sudo -u $USERNAME npm install -g @devcontainers/cli
fi

# --- Git-delta block (Debian example; customize for your stack) ---
if [ "${_OPTION_INSTALLGITDELTA}" = "true" ]; then
  ARCH=$(dpkg --print-architecture)
  export DEBIAN_FRONTEND=noninteractive
  GIT_DELTA_VERSION="0.18.2"
  wget -q "https://github.com/dandavison/delta/releases/download/${GIT_DELTA_VERSION}/git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb"
  apt-get update && apt-get install -y ./"git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb"
  rm -f "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb"
fi

# --- Extra npm packages (as string) ---
EXTRA_PKGS="${_OPTION_EXTRANPMPACKAGES}"
for pkg in $EXTRA_PKGS; do
  sudo -u $USERNAME npm install -g "$pkg"
done

# --- Add ll alias to shells if enabled ---
if [ "${_OPTION_ADDLLALIAS}" = "true" ]; then
  for shell_rc in "$USER_HOME/.bashrc" "$USER_HOME/.zshrc"; do
    if [ -f "$shell_rc" ] || [ "$shell_rc" = "$USER_HOME/.bashrc" ]; then
      echo "alias ll='ls -la'" >> "$shell_rc"
    fi
  done
fi

echo "[core-devtools] Done."