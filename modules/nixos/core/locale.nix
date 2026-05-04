# modules/nixos/core/locale.nix
#
# Timezone and locale settings. Defaults are en_US.UTF-8 for all
# locale categories, and US/Eastern for time. Hosts in other regions
# would override these or import a different locale module.

{ ... }:

{
  time.timeZone = "America/New_York";

  i18n.defaultLocale = "en_US.UTF-8";

  # Per-category locale settings. NixOS lets you set each LC_*
  # category independently, which is occasionally useful (e.g.,
  # an English UI with European date formatting). Here all set
  # to the same value, which is the common case.
  i18n.extraLocaleSettings = {
    LC_ADDRESS        = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT    = "en_US.UTF-8";
    LC_MONETARY       = "en_US.UTF-8";
    LC_NAME           = "en_US.UTF-8";
    LC_NUMERIC        = "en_US.UTF-8";
    LC_PAPER          = "en_US.UTF-8";
    LC_TELEPHONE      = "en_US.UTF-8";
    LC_TIME           = "en_US.UTF-8";
  };
}
