{ config, pkgs, ... }:
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

  # ...and ncurses has to be told where to look. targets.genericLinux does set
  # TERMINFO_DIRS, but only under systemd.user.sessionVariables, which writes
  # ~/.config/environment.d/10-home-manager.conf — read by the systemd *user
  # manager* for user units, not by an ssh login shell. Without this the two
  # packages above sit in the profile unreachable. Same value genericLinux uses,
  # exported through home.sessionVariables so it reaches hm-session-vars.sh and
  # therefore the shell. The trailing FHS entries keep the distro's own terminfo
  # (Debian splits it across /etc, /lib and /usr/share) visible.
  home.sessionVariables.TERMINFO_DIRS =
    "${config.home.profileDirectory}/share/terminfo:$TERMINFO_DIRS\${TERMINFO_DIRS:+:}/etc/terminfo:/lib/terminfo:/usr/share/terminfo";
}
