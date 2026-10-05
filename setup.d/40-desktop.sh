#!/bin/bash
# Shared Wayland stack plus one compositor. Started from a TTY — no display
# manager, deliberately: one less moving part while the base settles.
#
#   AERIS_COMPOSITOR=hyprland  (default) from a COPR, both arches
#   AERIS_COMPOSITOR=sway      from Fedora proper, if you want no COPR at all
set -euo pipefail

compositor=${AERIS_COMPOSITOR:-hyprland}
list="$AERIS_ROOT/packages/compositor-$compositor.txt"
[[ -f $list ]] || { echo "no package list for compositor '$compositor'" >&2; exit 1; }

echo "  compositor: $compositor"

# ghostty rides along only when its COPR was named; see setup.d/10-repos.sh.
extra=()
if [[ -n ${AERIS_GHOSTTY_COPR:-} ]]; then
  extra+=(ghostty)
  echo "  ghostty: from $AERIS_GHOSTTY_COPR"
fi

mapfile -t pkgs < <(
  {
    grep -hvE '^[[:space:]]*(#|$)' \
      "$AERIS_ROOT/packages/base.txt" \
      "$AERIS_ROOT/packages/desktop.txt" \
      "$list"
    (( ${#extra[@]} )) && printf '%s\n' "${extra[@]}"
  } | sed -e 's/#.*//' -e 's/[[:space:]]//g' | awk 'NF' | sort -u
)
(( ${#pkgs[@]} )) || { echo "no packages listed" >&2; exit 1; }

# Resolve names against the enabled repos first. A typo, or a package that
# simply is not built for this architecture, is then reported as a list up
# front instead of surfacing partway through a long download.
mapfile -t missing < <(
  comm -23 \
    <(printf '%s\n' "${pkgs[@]}") \
    <(dnf -q repoquery --qf '%{name}\n' "${pkgs[@]}" 2>/dev/null | awk 'NF' | sort -u)
)
if (( ${#missing[@]} )); then
  echo "not available for $(uname -m) in the enabled repos:" >&2
  printf '  %s\n' "${missing[@]}" >&2
  echo "fix packages/*.txt, or enable a repo that carries them (setup.d/10-repos.sh)" >&2
  exit 1
fi

# Install only what is absent, so re-running this step is fast and quiet
# rather than asking dnf to re-resolve the whole list every time.
mapfile -t want < <(
  comm -23 \
    <(printf '%s\n' "${pkgs[@]}") \
    <(rpm -qa --qf '%{NAME}\n' | awk 'NF' | sort -u)
)

if (( ${#want[@]} )); then
  echo "  installing ${#want[@]} of ${#pkgs[@]} packages"
  dnf -y install --setopt=install_weak_deps=False "${want[@]}"
else
  echo "  all ${#pkgs[@]} packages already present"
fi

systemctl --global enable pipewire.socket wireplumber.service
