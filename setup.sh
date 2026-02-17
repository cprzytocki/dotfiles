
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

# install from https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html
# then
sudo installer -pkg Downloads/aws-sam-cli-macos-arm64.pkg -target /

# npm login , get password from PAT classic token, its saved in mac passwords app
npm login --scope=@visoryplatform --auth-type=legacy --registry=https://npm.pkg.github.com

aws configure sso
# SSO session name: eg. my-sso
# SSO start URL [None]: [None]: https://findex.awsapps.com/start
# SSO region [None]: ap-southeast-2
# SSO registration scopes [sso:account:access]: <hit enter>

# NOTE: will open a browser window with a code to authorise the request, then select account

# CLI default client Region [None]: <hit enter>
# CLI default output format [None]: <hit enter>
# CLI profile name [visory-power-user-*****]: VisoryDev

# NOTE: profile name should be VisoryDev

# repos
cd ~ && mkdir workspace && cd workspace
git clone https://github.com/VisoryPlatform/portal.git; 
git clone https://github.com/VisoryPlatform/findex-notifications-service.git; 
git clone https://github.com/VisoryPlatform/calendar-booking-backend.git; 
git clone https://github.com/VisoryPlatform/payments-service.git; 
git clone https://github.com/VisoryPlatform/insights-backend.git; 
git clone https://github.com/VisoryPlatform/findex-auth-backend.git; 
git clone https://github.com/VisoryPlatform/threads-vault-backend; 
git clone https://github.com/VisoryPlatform/metric-connectors.git; 
git clone https://github.com/VisoryPlatform/video-chat-sdk.git 

