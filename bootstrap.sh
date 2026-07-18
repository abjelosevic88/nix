#!/usr/bin/env bash
# One-time per-machine setup: pick a profile (written to a marker file outside
# the repo, read by the `rebuild` shell function) and seed ~/.gitconfig.local
# with the identity template. Safe to re-run.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
marker="${XDG_CONFIG_HOME:-$HOME/.config}/nix-machine"

profiles=()
for f in "$repo"/hosts/*.nix; do
  profiles+=("$(basename "$f" .nix)")
done

# Interactive picker: ↑/↓ or j/k to move, Enter to select, 1-9 to jump-select,
# q to abort. Menu is drawn on stderr; the chosen value goes to stdout.
choose() {
  local opts=("$@") n=$# idx=0 key rest i first=1

  # No terminal (piped/CI): plain numbered prompt.
  if [[ ! -t 0 || ! -t 2 ]]; then
    for i in "${!opts[@]}"; do
      printf '  %d) %s\n' "$((i + 1))" "${opts[$i]}" >&2
    done
    read -rp "Machine profile [1-$n]: " key
    if [[ ! "$key" =~ ^[0-9]+$ ]] || (( key < 1 || key > n )); then
      echo "invalid choice: $key" >&2
      return 1
    fi
    printf '%s\n' "${opts[$((key - 1))]}"
    return 0
  fi

  printf '\e[?25l' >&2                    # hide cursor
  trap 'printf "\e[?25h" >&2' RETURN      # restore it however we leave

  while true; do
    (( first )) || printf '\e[%dA' "$n" >&2
    first=0
    for i in "${!opts[@]}"; do
      if (( i == idx )); then
        printf '\e[2K  \e[7m %s \e[0m\n' "${opts[$i]}" >&2
      else
        printf '\e[2K   %s\n' "${opts[$i]}" >&2
      fi
    done

    IFS= read -rsn1 key
    if [[ "$key" == $'\e' ]]; then        # collect arrow-key escape sequence
      rest=""
      # macOS /bin/bash is 3.2, which only allows integer read timeouts
      if (( BASH_VERSINFO[0] >= 4 )); then
        read -rsn2 -t 0.05 rest || true
      else
        read -rsn2 -t 1 rest || true
      fi
      key+="$rest"
    fi

    case "$key" in
      $'\e[A' | k) (( idx = (idx - 1 + n) % n )) ;;
      $'\e[B' | j) (( idx = (idx + 1) % n )) ;;
      [1-9])
        (( key <= n )) || continue
        printf '%s\n' "${opts[$((key - 1))]}"
        return 0
        ;;
      "")                                  # Enter
        printf '%s\n' "${opts[$idx]}"
        return 0
        ;;
      q | $'\e')
        return 1
        ;;
    esac
  done
}

echo "Select machine profile (arrows + Enter):"
profile="$(choose "${profiles[@]}")" || { echo "aborted" >&2; exit 1; }

mkdir -p "$(dirname "$marker")"
printf '%s\n' "$profile" > "$marker"

gitconfig_note="already existed — left unchanged"
if [[ ! -f "$HOME/.gitconfig.local" ]]; then
  cp "$repo/templates/gitconfig.local.example" "$HOME/.gitconfig.local"
  gitconfig_note="created from template — still has placeholder values"
fi

sshconfig_note="already existed — left unchanged"
if [[ ! -f "$HOME/.ssh/config.local" ]]; then
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  cp "$repo/templates/ssh-config.local.example" "$HOME/.ssh/config.local"
  chmod 600 "$HOME/.ssh/config.local"
  sshconfig_note="created (optional — machine-local ssh hosts/keys go here)"
fi

# ~-shorten paths for display (avoid ${var/pat/\~}: bash 5.2+ keeps the backslash)
display_repo=$repo
display_marker=$marker
if [[ $repo == "$HOME"/* ]]; then display_repo="~${repo#"$HOME"}"; fi
if [[ $marker == "$HOME"/* ]]; then display_marker="~${marker#"$HOME"}"; fi

echo
echo "Done:"
echo "  [x] profile '$profile' saved to $display_marker"
echo "  [x] ~/.gitconfig.local $gitconfig_note"
echo "  [x] ~/.ssh/config.local $sshconfig_note"
echo
echo "Next steps:"
echo
echo "  1. Set your git identity for THIS machine (name + email — never committed):"
echo "       \$EDITOR ~/.gitconfig.local"
echo
echo "  2. Apply the config for the first time (one-time long form):"
echo "       nix run home-manager/release-25.11 -- switch --flake $display_repo#$profile --impure"
echo
echo "  3. Restart your shell. From now on, updating is just:"
echo "       rebuild"
