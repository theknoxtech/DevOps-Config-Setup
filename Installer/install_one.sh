#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Function to print messages in green
log() {
    echo -e "\e[32m$1\e[0m"
}

# === Configuration ===
# Set to "yes" to make the Homebrew-installed Zsh your default shell.
# Leave as "no" if you only want to install it.
MAKE_DEFAULT_SHELL="${1:-no}" # Default to "no" if no argument is provided

log "--- Zsh & Oh My Zsh Setup for macOS ---"
log "Make Zsh default shell: $MAKE_DEFAULT_SHELL"

# === Homebrew Installation ===
# Check if Homebrew is installed, install if not.
if ! command -v brew &> /dev/null; then
    log "Installing Homebrew..."
    # This command will download and run the official Homebrew installer script.
    # It might prompt for your password during installation.
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH (important for Apple Silicon Macs)
    # The Homebrew installer usually gives instructions for this, but we add it here for robustness.
    # Determine architecture and set path accordingly
    if [[ "$(uname -m)" == "arm64" ]]; then
      # Apple Silicon Path
      HOMEBREW_PREFIX="/opt/homebrew"
    else
      # Intel Path
      HOMEBREW_PREFIX="/usr/local"
    fi

    log "Adding Homebrew to your PATH..."
    # Add to .zprofile for login shells, ensure it's created if it doesn't exist
    touch ~/.zprofile
    if ! grep -q "eval \"\$(${HOMEBREW_PREFIX}/bin/brew shellenv)\"" ~/.zprofile; then
        echo "eval \"\$(${HOMEBREW_PREFIX}/bin/brew shellenv)\"" >> ~/.zprofile
    fi
    # Apply for the current script session
    eval "$(${HOMEBREW_PREFIX}/bin/brew shellenv)"

else
    log "Homebrew is already installed. Skipping installation."
fi

# Ensure Homebrew installation is usable in this script session
# Determine architecture and set path accordingly
if [[ "$(uname -m)" == "arm64" ]]; then
  # Apple Silicon Path
  HOMEBREW_PREFIX="/opt/homebrew"
else
  # Intel Path
  HOMEBREW_PREFIX="/usr/local"
fi
# Apply for the current script session if brew isn't already in the path
if ! command -v brew &> /dev/null; then
    eval "$(${HOMEBREW_PREFIX}/bin/brew shellenv)"
fi


# === Install Zsh, Git, Curl via Homebrew ===
log "Updating Homebrew..."
brew update
log "Installing/Updating Zsh, Git, and Curl using Homebrew..."
# Use brew to install zsh (latest), git, and curl.
# macOS usually has versions of these, but brew ensures up-to-date ones.
brew install zsh git curl


# === Oh My Zsh Installation ===
# Check if Oh My Zsh directory exists
if [ -d "$HOME/.oh-my-zsh" ]; then
    log "Oh My Zsh is already installed at $HOME/.oh-my-zsh. Skipping installation."
else
    log "Installing Oh My Zsh..."
    # Use curl to download and run the Oh My Zsh installer script non-interactively.
    # NOTE: This installer might backup your existing .zshrc file.
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi


# === Set Zsh as Default Shell (Optional) ===
if [[ "$MAKE_DEFAULT_SHELL" == "yes" ]]; then
    log "Attempting to set Homebrew Zsh as the default shell..."

    # Get the path to the Zsh installed by Homebrew
    BREW_ZSH_PATH=$(brew --prefix)/bin/zsh

    # Check if the Homebrew Zsh path exists
    if [[ -f "$BREW_ZSH_PATH" ]]; then
        log "Homebrew Zsh found at: $BREW_ZSH_PATH"

        # Check if the Homebrew Zsh path is already in /etc/shells
        if ! grep -Fxq "$BREW_ZSH_PATH" /etc/shells; then
            log "Adding Homebrew Zsh to /etc/shells (requires sudo)..."
            # Append the path to /etc/shells. This requires administrator privileges.
            echo "$BREW_ZSH_PATH" | sudo tee -a /etc/shells > /dev/null
            log "Homebrew Zsh added to /etc/shells."
        else
            log "Homebrew Zsh is already listed in /etc/shells."
        fi

        # Change the default shell for the current user
        log "Changing default shell to Homebrew Zsh (requires password)..."
        # The chsh command changes the user's login shell. It will prompt for the user's password.
        chsh -s "$BREW_ZSH_PATH"
        log "Default shell changed. You may need to log out and log back in for it to take full effect."
    else
        log "Error: Could not find Homebrew Zsh at $BREW_ZSH_PATH. Skipping default shell change."
    fi
else
    log "Skipping setting Zsh as the default shell as requested."
fi


# === Install Zsh Plugins ===
# Define the Oh My Zsh custom plugins directory
ZSH_CUSTOM_PLUGINS="$HOME/.oh-my-zsh/custom/plugins"

# Install Zsh autosuggestions
if [ ! -d "$ZSH_CUSTOM_PLUGINS/zsh-autosuggestions" ]; then
    log "Installing Zsh autosuggestions plugin..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM_PLUGINS/zsh-autosuggestions"
else
    log "Zsh autosuggestions already installed. Skipping."
fi

# Install Zsh syntax highlighting
if [ ! -d "$ZSH_CUSTOM_PLUGINS/zsh-syntax-highlighting" ]; then
    log "Installing Zsh syntax highlighting plugin..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM_PLUGINS/zsh-syntax-highlighting"
else
    log "Zsh syntax highlighting already installed. Skipping."
fi


# === Configure Plugins in .zshrc ===
log "Configuring Zsh plugins in .zshrc..."
ZSHRC_FILE="$HOME/.zshrc"

# Check if the .zshrc file exists (Oh My Zsh should have created it)
if [[ -f "$ZSHRC_FILE" ]]; then
    # Check if the plugins line already includes the desired plugins
    if grep -q "^plugins=(.*zsh-autosuggestions.*zsh-syntax-highlighting.*)" "$ZSHRC_FILE"; then
        log "Plugins 'zsh-autosuggestions' and 'zsh-syntax-highlighting' seem to be already configured in $ZSHRC_FILE."
    elif grep -q "^plugins=(.*)" "$ZSHRC_FILE"; then
        log "Adding 'zsh-autosuggestions' and 'zsh-syntax-highlighting' to plugins list in $ZSHRC_FILE..."
        # Use sed -i '' for macOS compatibility to add the plugins
        # This looks for 'plugins=(...)' and adds the new plugins inside the parentheses
        # It handles cases with existing plugins like (git) or others.
        sed -i '' 's/^plugins=\((.*)\)/plugins=(\1 zsh-autosuggestions zsh-syntax-highlighting)/' "$ZSHRC_FILE"
        # Fallback if the simple replacement didn't work (e.g., only git was present without others)
         if ! grep -q "zsh-autosuggestions" "$ZSHRC_FILE"; then
             sed -i '' 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' "$ZSHRC_FILE"
         fi
         log "Updated plugins line in $ZSHRC_FILE."
    else
        log "Warning: Could not find a 'plugins=(...)' line in $ZSHRC_FILE. Manual configuration might be needed."
    fi
else
    log "Warning: $ZSHRC_FILE not found. Cannot configure plugins automatically."
fi

# === Final Steps ===
log "Setup script finished!"
log "To apply changes, close and reopen your terminal or run: source ~/.zshrc"
if [[ "$MAKE_DEFAULT_SHELL" == "yes" ]]; then
    log "If you set Zsh as default, you might need to log out and log back in completely."
fi