# Fig pre block. Keep at the top of this file.
# [[ -f "$HOME/.fig/shell/zshrc.pre.zsh" ]] && builtin source "$HOME/.fig/shell/zshrc.pre.zsh"

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


export JAVA_HOME=/Library/Java/JavaVirtualMachines/adoptopenjdk-8.jdk/Contents/Home
# export GRADLE_HOME=$(ls -d /usr/local/Cellar/gradle/*/libexec | tail -n 1)
export VAGRANT_CWD=~/workspace/devlocal
. $(brew --prefix asdf)/libexec/asdf.sh
export NPM_TOKEN=$(uf config --get npm.token)
export DEVLOCAL_SYNC=skip
export AWS_PROFILE=stg1
export DEVLOCAL_SYNC=skip
export RDS=mygazines2
export MYSQL_USER=devsread
export MGMT_HOST=$(aws ec2 describe-instances \
    --filters "Name=tag:Role,Values=rds-mgmt" "Name=instance-state-name,Values=running"\
    --query '["Reservations"][0][0].Instances[0].InstanceId' \
  --output text);

# Alias'
alias rds='sh ~/workspace/scripts/databases/rds-connect.sh'
alias vu='vagrant up'
alias vssh='vagrant ssh'
alias vd='vagrant destroy -f'
alias sso='aws sso login'
alias pb='cd /users/chrisprzytocki/workspace/page-builder-ui && tmux new-session \; split-window -v \; send-keys "cd builder && make start" Enter \; selectp -t 0 \; send-keys "cd api && make start" Enter \; split-window -h \; send-keys "cd frontend && make start" Enter \; attach'
# ---- Eza (better ls) -----
alias ls="eza --icons=always"
# ---- Zoxide (better cd) ----
eval "$(zoxide init zsh)"
alias cd="z"
# alias fd="cd ~ && code $(fzf)"

alias dotfiles='/usr/bin/git --git-dir=$HOME/dotfiles/ --work-tree=$HOME'

source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# history setup
HISTFILE=$HOME/.zhistory
SAVEHIST=1000
HISTSIZE=999
setopt share_history
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_verify

# completion using arrow keys (based on history)
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# select keys back and forth
bindkey "^[[1;3C" forward-word
bindkey "^[[1;3D" backward-word
#  Command backspace
bindkey '^[[3;5~' backward-kill-line

autoload -U compinit; compinit
eval "$(fzf --zsh)"
source ~/.zsh_fzf-tab/fzf-tab.plugin.zsh

# zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
# zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
# zstyle ':completion:*' menu no
# zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'

source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Fig post block. Keep at the bottom of this file.
# [[ -f "$HOME/.fig/shell/zshrc.post.zsh" ]] && builtin source "$HOME/.fig/shell/zshrc.post.zsh"
