{ ... }:
{
  # Work machines deliberately get none of the personal role's extras
  # (no paseo, no personal ssh identities, no personal-only networking).
  # Work-only modules (e.g. a future home/ssh/work.nix) slot in here.
  imports = [ ];
}
