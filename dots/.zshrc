export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
# Startup speed: skip compaudit + update checks, cache completions
ZSH_DISABLE_COMPFIX=true
DISABLE_AUTO_UPDATE=true
DISABLE_MAGIC_FUNCTIONS=true
ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zcompdump"
source $ZSH/oh-my-zsh.sh

# --- History ---
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_ALL_DUPS SHARE_HISTORY

# --- Modern replacements (only if installed) ---
if command -v eza >/dev/null; then
    alias ls='eza --icons --group-directories-first'
    alias ll='eza -lh --icons --git --group-directories-first'
    alias la='eza -lah --icons --git --group-directories-first'
    alias lt='eza --tree --level=2 --icons'
fi
command -v bat >/dev/null && alias cat='bat --paging=never --style=plain'
command -v rg  >/dev/null && alias grep='rg'

# --- fzf: Ctrl+R history, Ctrl+T files, Alt+C cd ---
[ -f /usr/share/fzf/key-bindings.zsh ] && source /usr/share/fzf/key-bindings.zsh
[ -f /usr/share/fzf/completion.zsh ]   && source /usr/share/fzf/completion.zsh
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border \
--color=bg+:#292e42,bg:#1a1b26,fg:#c0caf5,hl:#7aa2f7,hl+:#7dcfff,\
info:#e0af68,prompt:#bb9af7,pointer:#f7768e,marker:#9ece6a,spinner:#bb9af7,header:#565f89"

# --- zoxide: smarter cd (use `z dir`) ---
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

# --- Prompt: starship if installed, else oh-my-zsh theme ---
command -v starship >/dev/null && eval "$(starship init zsh)"

# --- Drop-down terminal (SUPER + `): Esc at the prompt closes it ---
# Only in that terminal (scripts/dropterm.sh sets DROPTERM=1). Apps like vim
# still get Esc, since zsh only sees keys while sitting at the prompt.
if [[ -n $DROPTERM ]]; then
    dropterm-exit() { exit }
    zle -N dropterm-exit
    bindkey '\e' dropterm-exit
    KEYTIMEOUT=10   # 0.1s to tell a lone Esc from Alt/arrow sequences
fi
