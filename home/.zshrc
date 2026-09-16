# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
bindkey -e
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/stafd/.zshrc'

# bindkey '^I' autosuggest-accept
bindkey '^[[1;5C' forward-word      # Ctrl+Right Arrow
bindkey '^[[1;5D' backward-word     # Ctrl+Left Arrow

autoload -Uz compinit
compinit
# End of lines added by compinstall

setopt hist_ignore_all_dups

alias fucking='sudo'
alias kanker-update="paru -Syu --noconfirm && flatpak update -y" 

export VINTAGE_STORY=~/.local/share/flatpak/app/at.vintagestory.VintageStory/x86_64/stable/active/files/extra/vintagestory/
export DOTNET_ROOT=$HOME/.dotnet

# actual usefull aliases
alias source-activate="source .venv/bin/activate"
alias suspend="systemctl suspend"

PROMPT='%F{cyan}%n@%m%f %F{blue}%~%f %# '

. "$HOME/.local/share/../bin/env"
