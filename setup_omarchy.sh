
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

sudo pacman -S stow yazi tmux
yay -S zsh zen-browser-bin zsh-theme-powerlevel10k-git sesh-bin
chsh -s $(which zsh)

git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm 

#  launch tmux Press prefix + I (capital i, as in Install) to fetch the plugin. (https://github.com/tmux-plugins/tpm)

# optional packages
sudo pacman -S helix nvm qdirstat-bin
yay -S gparted timeshift xorg-xhost ghostty aws-cli-bin aws-sam-cli-bin cursor-bin google-chrome intune-portal-bin microsoft-edge-stable-bin microsoft-identity-broker-bin qdirstat-bin teams-for-linux vesktop



# only if need to fix some issue
xhost +local:


# CHANGE default editor to helix in omarchy menu > setup > config > defaults

# run seahorse
# yay -S seahorse 

# Install seahorse, create a "password keyring". You MUST set a password (because of a known bug mentioned above) and then set it as default.
# https://github.com/recolic/microsoft-intune-archlinux?tab=readme-ov-file

## PUT THE FOLLOWING IN /etc/os-release
# NAME="Ubuntu"
# VERSION="20.04.6 LTS (Focal Fossa)"
# ID=ubuntu
# ID_LIKE=debian
# PRETTY_NAME="Ubuntu 20.04.6 LTS"
# VERSION_ID="20.04"
# HOME_URL="https://www.ubuntu.com/"
# SUPPORT_URL="https://help.ubuntu.com/"
# BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
# PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
# VERSION_CODENAME=focal
# UBUNTU_CODENAME=focal

https://github.com/recolic/microsoft-intune-archlinux?tab=readme-ov-file
[Temporary Fix] Run fix-libssl.sh and follow instructions.sudo

#  run microsoft intune
env LD_PRELOAD=/usr/lib/libcrypto-332.so:/usr/lib/libssl-332.so /opt/microsoft/intune/bin/intune-portal

# GETTING FIREFOX (ZEN BROWSER) TO WORK FOR SSO
# https://github.com/siemens/linux-entra-sso

. /usr/share/nvm/init-nvm.sh
nvm install 22.12.0 --default    
npm install -g @angular/cli@19


# install dotfiles
git clone https://github.com/cprzytocki/dotfiles.git
cd dotfiles
stow omarchy


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
# Do the same for the other profile, VisoryProd

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


# Swap file https://wiki.archlinux.org/title/Swap
