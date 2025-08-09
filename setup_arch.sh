
# aws-sam-cli-bin 1.142.1-1
# cursor-bin 1.3.9-1
# google-chrome 138.0.7204.183-1
# helix-git 25.01.1.r454.g4f985832b-1
# intune-portal-bin 1.2411.14-5
# microsoft-edge-stable-bin 134.0.3124.68-1
# microsoft-identity-broker-bin 2.0.1-1
# qdirstat-bin 1.9-1
# sherlock-launcher-bin 0.1.14-2
# teams-for-linux 2.1.0-1
# vesktop 1.5.8-2
# wezterm-git 20241007.103714.ed430415-1
# zen-browser-bin 1.14.9b-1
# zsh-theme-powerlevel10k-git r4296.0996a941-1

sudo pacman -S stow nodejs-lts-jod git zoxide eza fzf helix lazygit yazi
yay -S aws-sam-cli-bin cursor-bin google-chrome helix-git intune-portal-bin microsoft-edge-stable-bin microsoft-identity-broker-bin qdirstat-bin sherlock-launcher-bin teams-for-linux vesktop wezterm-git zen-browser-bin zsh-theme-powerlevel10k-git 

npm install -g @angular/cli@19

git config --global user.name "Chris Przytocki"
git config --global user.email "cprzytocki@gmail.com"

# install dotfiles
git clone https://github.com/cprzytocki/dotfiles.git
cd dotfiles
stow . 

# install aws cli, need rosetta on mac
sudo softwareupdate --install-rosetta
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /


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

