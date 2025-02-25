#!/bin/bash

# Exit on error
set -e

# Function to print messages
log() {
    echo -e "\e[32m$1\e[0m"
}

# Check for argument and set default if none provided
MAKE_DEFAULT_SHELL="${1:-no}"

# Display the selected option
log "Make Zsh default shell: $MAKE_DEFAULT_SHELL"

# Install Homebrew if not already installed
if ! command -v brew &> /dev/null; then
    log "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    log "Homebrew is already installed. Skipping installation."
fi

# Install Zsh
log "Installing Zsh..."
sudo apt update
sudo apt install -y zsh curl git

# Install Oh My Zsh if not already installed
if [ -d "$HOME/.oh-my-zsh" ]; then
    log "Oh My Zsh is already installed at $HOME/.oh-my-zsh. Skipping installation."
else
    log "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Set Zsh as the default shell if requested
if [[ "$MAKE_DEFAULT_SHELL" == "yes" ]]; then
    log "Setting Zsh as the default shell..."
    chsh -s $(which zsh)
else
    log "Zsh installation complete. Skipping setting it as the default shell."
fi

# Install Zsh autosuggestions
if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
    log "Installing Zsh autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
else
    log "Zsh autosuggestions already installed. Skipping."
fi

# Install Zsh syntax highlighting
if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
    log "Installing Zsh syntax highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
else
    log "Zsh syntax highlighting already installed. Skipping."
fi

# Update .zshrc to enable plugins
log "Configuring Zsh plugins in .zshrc..."
if ! grep -q "zsh-autosuggestions" ~/.zshrc; then
    sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc
    log "Updated plugins in .zshrc."
else
    log "Plugins already configured in .zshrc."
fi

# Apply changes
log "Applying changes..."
zsh -c "source ~/.zshrc"

log "Oh My Zsh installation completed with autosuggestions and syntax highlighting enabled!"