# ------------------------------------------------------------------------------
# ENVIRONMENT VARIABLES & EXPORTS
# ------------------------------------------------------------------------------
export NVM_DIR="$HOME/.nvm"

# Disable the standard fzf plugin's completion to let fzf-tab take over
export FZF_OMZ_COMPLETION=0


# ------------------------------------------------------------------------------
# USER CONFIG & ALIASES
# Runs after Oh My Zsh and plugins are loaded.
# ------------------------------------------------------------------------------

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# fnm (Fast Node Manager) — replaces brew nvm; reads .nvmrc and auto-switches on cd
if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --use-on-cd)"
fi

# Aliases
alias vi="nvim"
alias vim="nvim"
alias ls="eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions"
alias pa="php artisan"

# Zoxide is initialized via programs.zoxide in home/common.nix


# ------------------------------------------------------------------------------
# FZF CUSTOMIZATION
# ------------------------------------------------------------------------------

# Use fd for finding files
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

# fzf theme
fg="#CBE0F0"
bg="#011628"
bg_highlight="#143652"
purple="#B388FF"
blue="#06BCE4"
cyan="#2CF9ED"
export FZF_DEFAULT_OPTS="--color=fg:${fg},bg:${bg},hl:${purple},fg+:${fg},bg+:${bg_highlight},hl+:${purple},info:${blue},prompt:${cyan},pointer:${cyan},marker:${cyan},spinner:${cyan},header:${cyan}"

# fzf preview
show_file_or_dir_preview="if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi"
export FZF_CTRL_T_OPTS="--preview '$show_file_or_dir_preview'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"


# ------------------------------------------------------------------------------
# LOCAL TOOLS / PATH
# ------------------------------------------------------------------------------

# Local user env (cargo, uv, etc. install to ~/.local/bin/env)
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# Antigravity (preserves the duplicate prepend in the original .zshrc)
export PATH="/Users/abjelosevic/.antigravity/antigravity/bin:$PATH"
export PATH="/Users/abjelosevic/.antigravity/antigravity/bin:$PATH"

# iTerm2 shell integration (no-op in other terminals)
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"


# ------------------------------------------------------------------------------
# KEY BINDINGS
# ------------------------------------------------------------------------------
bindkey -v
bindkey -M vicmd 'v' edit-command-line              # press `v` in normal mode → opens $EDITOR
autoload -Uz edit-command-line; zle -N edit-command-line
export KEYTIMEOUT=1                                 # snappier Esc
