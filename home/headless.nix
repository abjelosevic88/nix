{ pkgs, ... }:
{
  # For machines only ever reached over ssh. The counterpart to
  # home/linux-desktop.nix: no terminal emulator is installed here, but the
  # *terminfo* for the emulators you connect FROM still has to exist on this
  # side. ssh forwards $TERM, so a session opened from kitty arrives as
  # TERM=xterm-kitty; without the matching entry, ncurses falls back to dumb
  # behaviour and tmux, clear, less and nvim all misbehave. These are terminfo
  # databases only — a few hundred KB, not the emulators.
  home.packages = with pkgs; [
    kitty.terminfo
    ghostty.terminfo
  ];
}
