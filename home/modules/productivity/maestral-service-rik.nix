# home/modules/productivity/maestral-service-rik.nix
#
# This user's Maestral settings.
#
_: {
  productivity.maestral.excludedPaths = [
    # UniFi Protect's camera archive: up to 600 GB of footage (Protect's own
    # cap). Browse it on demand instead; never sync it. On 2026-10-19 the
    # official client pulled ~520 GB of it onto nostrum and filled the disk.
    "/Apps/UniFi Protect Archive"
  ];
}
