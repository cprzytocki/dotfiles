defaults write com.apple.dock autohide-delay -float 0; defaults write com.apple.dock autohide-time-modifier -float 0.15; killall Dock

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# then run following after brew or copy from output in previous script
echo >> /Users/cprzytocki/.zprofile
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/cprzytocki/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

brew update
brew upgrade

brew install stow
brew install node
brew install git
brew install zoxide
brew install eza
brew install fzf
brew install helix
brew install lazygit
brew install yazi
brew install bat
brew install tmux
brew install sesh
brew install scroll-reverser
brew install typescript-language-server

# dotnet & C# LSP for helix
brew install dotnet
dotnet tool install --global csharp-ls --version 0.20.0
echo 'export PATH="$PATH:$HOME/.dotnet/tools"' >> ~/.zprofile

brew install --cask font-meslo-lg-nerd-font
brew install --cask zen
brew install --cask cursor
brew install --cask google-chrome
brew install --cask karabiner-elements
brew install --cask raycast
brew install --cask ghostty
brew install --cask fork
brew install --cask shottr
brew install --cask claude-code

brew install --cask meetingbar
brew install --cask alt-tab
brew install --cask obsidian

brew install --cask 1password
brew install --cask slack
brew install --cask zoom


git config --global user.name "Chris Przytocki"
git config --global user.email "cprzytocki@gmail.com"

# install dotfiles
git clone https://github.com/cprzytocki/dotfiles.git
cd dotfiles
stow . 

# tmux plugin manager
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm 
tmux source ~/.tmux.conf
prefix + I

# install aws cli, need rosetta on mac
sudo softwareupdate --install-rosetta
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /

# jira api token
# 1. Generate API token at https://id.atlassian.com/manage-profile/security/api-tokens
# 2. Store token in macOS Keychain:
#    security add-generic-password -a "jira-cli" -s "jira-cli-api-token" -w "<YOUR_API_TOKEN>" -U
# 3. Add to ~/.zshrc:
#    export JIRA_API_TOKEN=$(security find-generic-password -a "jira-cli" -s "jira-cli-api-token" -w 2>/dev/null)
# 4. Run: jira init --installation cloud --server https://ankored.atlassian.net --login cprzytocki@ankored.com --project ENG


