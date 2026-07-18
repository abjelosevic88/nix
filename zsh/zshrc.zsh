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
  eval "$(fnm env --use-on-cd --log-level quiet)"
fi

# Aliases
alias vi="nvim"
alias vim="nvim"
alias ls="eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions"
alias pa="php artisan"
alias ga="git add"
alias gri="git rebase -i"
alias lh="eza --long --all --header --git --icons=always"

killport() {
  local signal="TERM"

  if [[ "$1" == "-9" || "$1" == "--force" ]]; then
    signal="KILL"
    shift
  fi

  local port="$1"

  if [[ -z "$port" || "$port" == "-h" || "$port" == "--help" ]]; then
    echo "Usage: killport [-9|--force] <port>"
    return 2
  fi

  if [[ ! "$port" =~ '^[0-9]+$' ]] || (( port < 1 || port > 65535 )); then
    echo "killport: expected a TCP port number between 1 and 65535" >&2
    return 2
  fi

  if ! command -v lsof >/dev/null 2>&1; then
    echo "killport: lsof is not installed" >&2
    return 127
  fi

  local -a pids
  pids=("${(@f)$(lsof -nP -tiTCP:"$port" -sTCP:LISTEN 2>/dev/null | sort -u)}")

  if (( ${#pids[@]} == 0 )); then
    echo "killport: no process is listening on port $port"
    return 1
  fi

  echo "killport: sending SIG${signal} to PID(s): ${pids[*]}"
  kill "-${signal}" "${pids[@]}"
}
alias kp="killport"

# home-manager rebuild — the machine's profile name is read from a marker file
# OUTSIDE the repo (pure-eval nix can't see gitignored files, and the marker is
# machine-local by nature). Written once by bootstrap.sh. --impure lets the
# flake read $USER/$HOME for identity, so no usernames live in the repo.
rebuild() {
  local marker="${XDG_CONFIG_HOME:-$HOME/.config}/nix-machine"
  if [[ ! -r "$marker" ]]; then
    echo "rebuild: no machine profile set at $marker" >&2
    echo "  run ~/nix/bootstrap.sh, or:  echo personal-linux > $marker" >&2
    echo "  profiles: $(command ls "$HOME/nix/hosts" | sed 's/\.nix$//' | paste -sd' ' -)" >&2
    return 1
  fi
  local profile
  profile="$(<"$marker")"
  if [[ ! -f "$HOME/nix/hosts/$profile.nix" ]]; then
    echo "rebuild: profile '$profile' has no hosts/$profile.nix — fix $marker" >&2
    return 1
  fi
  home-manager switch --flake "$HOME/nix#$profile" --impure "$@"
}

# Zoxide is initialized via programs.zoxide in home/common.nix
if (( $+functions[__zoxide_z] )); then
  z() { __zoxide_z "$@"; }
  zi() { __zoxide_zi "$@"; }

  if (( $+functions[compdef] && $+functions[__zoxide_z_complete] )); then
    compdef __zoxide_z_complete z
  fi
fi


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

# Antigravity (only where installed)
[ -d "$HOME/.antigravity/antigravity/bin" ] && export PATH="$HOME/.antigravity/antigravity/bin:$PATH"

if [[ "$TERM_PROGRAM" == "iTerm.app" && -e "$HOME/.iterm2_shell_integration.zsh" ]]; then
  source "$HOME/.iterm2_shell_integration.zsh"
fi


# ------------------------------------------------------------------------------
# KEY BINDINGS
# ------------------------------------------------------------------------------
bindkey -v
autoload -Uz edit-command-line; zle -N edit-command-line
bindkey -M vicmd 'v' edit-command-line              # press `v` in normal mode → opens $EDITOR
bindkey -M viins '^E' edit-command-line             # press Ctrl+E in insert mode, or Cmd+E in kitty → opens $EDITOR
bindkey -M vicmd '^E' edit-command-line             # press Ctrl+E/Cmd+E from vi normal mode too
export KEYTIMEOUT=30                                # 300ms — snappy Esc + room for chord bindings (^G^B etc.)
