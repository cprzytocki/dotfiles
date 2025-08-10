
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

mise use -g node@lts
sudo pacman -S stow helix yazi
yay -S seahorse ghostty aws-cli-bin aws-sam-cli-bin cursor-bin google-chrome intune-portal-bin microsoft-edge-stable-bin microsoft-identity-broker-bin qdirstat-bin teams-for-linux vesktop zen-browser-bin zsh-theme-powerlevel10k-git 

# run seahorse
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

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
# @@@@WARNING: THIS WILL BRICK THE THE SYSTEM, REVERT OPENSSL BACK TO PREVIOUS VERSION AFTER THIS IS DONE@@@@@@@
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
# I had to downgrade openssl to 3.3.2 to get over an error displayed on the GUI. I don't know how we can re-conciliate Arch Linux & Intune requiring different versions of openssl.
# Details
# I had the following error printed on a windows after signing in, before checking policies:
# error:05880106:x509 certificate routines:X509_REQ_set_version:passed invalid argument:crypto/x509/x509rset.c:21
# which looked like it came from openssl: https://github.com/openssl/openssl/blob/ea5817854cf67b89c874101f209f06ae016fd333/crypto/x509/x509rset.c#L18
# Using the Arch Linux archive of openssl: https://archive.archlinux.org/packages/o/openssl/ , I downgraded to 3.3.2 to get over it. 3.4.0 was made available on Arch Linux on October 23rd 2024.

sudo pacman -U https://archive.archlinux.org/packages/o/openssl/openssl-3.3.2-1-x86_64.pkg.tar.zst
# REMINDER: REVERT OPENSSL BACK TO PREVIOUS VERSION AFTER THIS IS DONE

# run microsoft intune

# GETTING FIREFOX (ZEN BROWSER) TO WORK FOR SSO
# https://github.com/siemens/linux-entra-sso

npm install -g @angular/cli@19


# install dotfiles
git clone https://github.com/cprzytocki/dotfiles.git
cd dotfiles
stow . 


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

