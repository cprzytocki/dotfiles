# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Plugin Manager
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

# Plugins
zinit ice depth=1; zinit light romkatv/powerlevel10k
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Load completions
autoload -U compinit && compinit

zinit cdreplay -q

# history setup
HISTSIZE=5000
HISTFILE=$HOME/.zhistory
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# completion using arrow keys (based on history)
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# Completion styling
export FZF_DEFAULT_OPTS=" \
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
--color=selected-bg:#45475a \
--multi"

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:*' fzf-flags $(echo $FZF_DEFAULT_OPTS)

# ---- Eza (better ls) -----
alias ls="eza -a --icons=always"
# ---- Zoxide (better cd) ----
if [ -z "$DISABLE_ZOXIDE" ]; then
    eval "$(zoxide init zsh)"
    alias cd="z"
fi
# ~/.claude/settings.json:
#   "env": {
#     "DISABLE_ZOXIDE": "1"
#   }
# 
alias lg="lazygit"
alias cat="bat"

# # Set up fzf key bindings and fuzzy completion
eval "$(fzf --zsh)"

# Rebase onto alias 
alias rebase-onto="~/.config/scripts/rebase-onto.sh"

export EDITOR=hx

# ANKORED
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
export ASPNETCORE_ENVIRONMENT=Development
export DOTNET_ENVIRONMENT=Development
alias fmt='{ git diff --name-only --diff-filter=d HEAD -- "*.cs"; git ls-files --others --exclude-standard -- "*.cs"; } | sort -u | xargs dotnet csharpier format'
alias ankored-api="~/.config/scripts/ankored-api.sh"
alias ankored-migrate="~/.config/scripts/ankored-migrate.sh"

# Jira
export JIRA_API_TOKEN=$(security find-generic-password -a "jira-cli" -s "jira-cli-api-token" -w 2>/dev/null)
export JIRA_BASE_URL=https://ankored.atlassian.net
export JIRA_PROJECT_KEY=ENG

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh 


