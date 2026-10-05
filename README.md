# AerisOS

A minimal, rollback-first Fedora workstation for one person. Not a distro for
anyone else — a repo that turns a blank x86_64 machine into *this* machine.

Three layers:

| Layer | File | What it does |
| --- | --- | --- |
| ISO | `bin/make-iso` | Injects the kickstart into a stock Fedora ISO (`mkksiso`) |
| Install | `ks/install.ks` | Partitions, btrfs subvolumes, LUKS2, a ~12-package base |
| Wiring | `setup` + `setup.d/` | Everything after first boot, idempotently |

## Design rules

1. **Every step in `setup.d/` is safe to run twice.** That is why there is no
   migration system, no version file, and no state tracking. Re-running
   `./setup` *is* how you apply a change.
2. **No custom package repository.** `dnf` plus two COPRs.
3. **No command framework.** Six scripts. You know what they do.
4. **`ID=fedora` stays.** Only display strings get renamed.

## First install

You need a Linux host for `mkksiso` — or skip it entirely for install #1:

### From macOS, no Linux host needed

Anaconda auto-runs a kickstart from any volume labelled `OEMDRV`.

1. Write the stock **Fedora Everything netinstall** ISO to a USB stick.
2. Format a second small stick as FAT32 with the name `OEMDRV`
   (Disk Utility: Erase → MS-DOS (FAT), name `OEMDRV`).
3. Copy the kickstart onto it as `ks.cfg`:
   ```
   cp ks/install.ks /Volumes/OEMDRV/ks.cfg
   ```
4. Boot the target with both sticks attached. It installs unattended.

Edit `ks/install.ks` first: the disk name, timezone, username, the LUKS
passphrase, and the password hash (`openssl passwd -6`).

### From a Linux host

```
./bin/make-iso ~/Downloads/Fedora-Everything-netinst-x86_64-43-1.1.iso
```

## After first boot

```
git clone https://github.com/lestex/aerisos ~/aerisos
cd ~/aerisos
sudo ./setup              # all steps
sudo ./setup 20           # just snapshots
```

## Verify the rollback — before you need it

Do this on the fresh install, while nothing is at stake. An untested rollback
path is not a rollback path.

```
sudo dnf install -y sl              # anything; the dnf hook snapshots it
sudo snapper -c root list           # confirm a pre/post pair appeared
sudo aeris-rollback --list
sudo aeris-rollback <pre-number>
sudo systemctl reboot

rpm -q sl                           # should be gone
ls /usr/bin/sl                      # and gone here too — they must agree
```

Those last two lines are the real check on the subvolume layout: the RPM
database lives in `/var/lib/rpm`, inside the snapshotted root, so the package
database and the filesystem have to roll back together.

### Why not `snapper rollback`

Snapper implements rollback only for the openSUSE layout, where `/` is itself
a snapshot subvolume chosen by the btrfs *default subvolume*. Here `/` is a
plain subvolume named `root`, and both `/etc/fstab` and the kernel cmdline pin
`subvol=root`, so the default subvolume is never consulted — `snapper
rollback` reports *"cannot detect ambit since default subvolume is unknown"*
and refuses.

`aeris-rollback` instead mounts the btrfs top level, moves `root` aside, and
snapshots the chosen snapshot into its place, so the pinned `subvol=root`
resolves to the restored content. The old root is kept as
`root.rollback-<timestamp>`; delete it once the rolled-back system has proved
itself.

### The tool survives its own use

`aeris-rollback` is installed to `/usr/local/bin`, which is on the root
subvolume — so rolling back to a snapshot taken before it was installed would
delete it. It therefore copies itself into the restored root before you
reboot. If you ever do end up without it, the repo lives in `$HOME` on a
separate subvolume that rollbacks do not touch:

```
sudo ~/aerisos/bin/aeris-rollback --prune
```

### One limitation

`/boot` is a separate partition and is **not** rolled back, while
`/lib/modules` is on the root subvolume. So rolling back past a kernel update
leaves a kernel on disk whose modules are gone. `aeris-rollback` prints which
kernel versions have modules in the restored root — pick one of those at the
boot menu, then `dnf reinstall kernel-core` to resync.

## Update habit

```
sudo dnf upgrade            # the actions hook snapshots it automatically
```

Every one to two weeks. After a kernel or mesa bump, use the machine for a day
before letting cleanup prune the previous snapshot.

Keep the package list honest:

```
dnf repoquery --userinstalled --qf '%{name}' | sort > packages/installed.txt
```

## Launcher and menus

`fuzzel` is the launcher — in Fedora proper, so no COPR, and it themes through
the same template system as everything else.

| Binding | |
| --- | --- |
| `Alt/Super + Space` | app launcher |
| `Alt/Super + M` | `aeris-menu` — themes, capture, power |

`aeris-menu` is a page of shell over `fuzzel --dmenu`, which reads entries on
stdin and prints the chosen one. Adding a menu is a list of labels and a `case`.

**Not walker**, which Omarchy used to use and dropped: walker 2.x moved its
providers into a separate `elephant` daemon, and on Fedora `elephant` fails to
build in the COPR that ships walker — so walker would launch and find nothing.
Omarchy itself replaced walker with a 1,480-line Quickshell menu; this does the
same job in a page of shell because it only has to serve one person.

## Theming

Palettes are Omarchy's, taken as data under its MIT licence (see
`themes/LICENSE-omarchy`). The renderer is ours and much smaller: Omarchy's is
~600 lines because it carries gradients, colour mixing, legacy `colorN` aliases
and derived shades. Strip those and the idea is one sed script.

```
aeris-theme list
aeris-theme set tokyo-night
aeris-theme current
```

`themed/*.tpl` are rendered into `~/.local/state/aerisos/current/`, and each
config *includes* its generated file rather than being rewritten:

| Config | How it picks the theme up | Reload |
| --- | --- | --- |
| `hypr/hyprland.conf` | `source =` the generated file, last so it wins | `hyprctl reload` |
| `foot/foot.ini` | `include=` first line; section must be `[colors-dark]` | none — new window |
| `alacritty/alacritty.toml` | `[general] import = [...]` | automatic |
| `kitty/kitty.conf` | `include ${HOME}/...` — kitty expands env vars, not `~` | `SIGUSR1` |
| `ghostty/config` | `config-file =` | none — new window |
| btop | rendered theme copied to `~/.config/btop/themes/aeris.theme` |
| Quickshell | `FileView` reads `colors.json` with `watchChanges`, so the bar repaints live |

Template syntax, a trimmed version of Omarchy's:

```
{{ accent }}        #7aa2f7
{{ accent_strip }}  7aa2f7      for configs that reject the leading #
{{ accent_rgb }}    122,162,247
```

A template referencing a key some palette lacks is caught at render time —
`aeris-theme` refuses to apply rather than writing a literal `{{ ... }}` into a
config, where it would fail far from its cause. Use only the keys listed in
`themes/README.md`; all 22 palettes define them.

For btop, set `color_theme = "aeris"` in its config once.

**ghostty is not in Fedora**, and is opt-in. `foot`, `alacritty` and `kitty`
all come from Fedora proper; ghostty needs a COPR you name:

```
AERIS_GHOSTTY_COPR=scottames/ghostty sudo -E ./setup 10 40
```

`scottames/ghostty` is the one to start from — 1.3.1-4, a successful release
build, aarch64 and x86_64 on f44. Check before switching to another: several
ghostty COPRs carry a *failed* latest build, which says something about how
fussy the package is rather than about any one maintainer.

`dotfiles/ghostty/` holds exactly one config file, deliberately. Ghostty reads
both `config` and `config.ghostty` where it knows the newer name, so shipping
the settings twice makes it load the same `config-file` twice and report
*"cycle detected"*. If a future build stops reading `config`, rename rather
than adding a second copy.

**The default terminal is kitty**, bound to `Alt/Super+Return`. Of the four,
only kitty and alacritty pick up a theme without opening a new window, and
kitty's path (`SIGUSR1`) is the one `aeris-theme` can drive. Change `$terminal`
in `dotfiles/hypr/hyprland.conf` if you would rather have foot back.

**foot does not reload.** It has no reload signal: `SIGUSR1`/`SIGUSR2` switch
between the `[colors-dark]` and `[colors-light]` sections of the already-loaded
config rather than re-reading the file. Open a new window after switching
themes. Hyprland, btop and the bar all update live.

## Phases

- [ ] **1. Kickstart that boots** — unattended, encrypted, correct subvolumes, no desktop
- [ ] **2. Rollback that works** — verified by actually rolling back once
- [ ] **3. Minimal desktop** — Hyprland + Quickshell, enough for a day's work
- [ ] **4. Hardware** — first time on real metal; fill in `setup.d/30-hardware.sh`
- [ ] **5. Dotfiles + steady state** — symlinks, package list, the re-run habit

Phases 1 and 2 have nothing to do with the desktop, and they are the ones that
can waste a weekend. Do them first, boringly.

## The cost of --exclude-weakdeps

`--exclude-weakdeps` is the minimalism lever, and it removes things that are
structurally necessary but only *recommended*. Each of these cost a debugging
round, and all three fail quietly rather than loudly:

| Package | Weak dependency of | Symptom when missing |
| --- | --- | --- |
| `systemd-pam` | `systemd` | no `XDG_RUNTIME_DIR`, no logind session, no compositor |
| `mesa-dri-drivers` | the graphics stack | compositor starts with no renderer |

When something graphical or session-related misbehaves on a system built this
way, suspect a dropped weak dependency before suspecting your own config.
`dnf repoquery --recommends <pkg>` shows what was skipped.

## The compositor comes from a COPR

Hyprland is **not in Fedora's official repos** for any release. It comes from
a COPR, and the choice of which matters more than it should:

| COPR | Releases | Arches | |
| --- | --- | --- | --- |
| `lionheartp/Hyprland` | 44, 45, rawhide | aarch64, x86_64 | default — what ML4W ships |
| `mineiro/hyprland` | 43, 44, 45, rawhide | aarch64, x86_64 | widest; no quickshell |
| `sdegler/hyprland` | 43, 44, 45, rawhide | aarch64, x86_64 | |
| `solopasha/hyprland` | rawhide only | x86_64 | widely cited, least maintained |

The default is the one [ML4W](https://github.com/mylinuxforwork/dotfiles)
ships for Fedora — a large, actively maintained dotfiles project, so its user
base exercises that COPR continuously. For a personal repo that is the best
availability signal there is.

```
sudo ./setup 10 40                                        # hyprland, default COPR
AERIS_HYPRLAND_COPR=mineiro/hyprland sudo -E ./setup 10 40
AERIS_COMPOSITOR=sway sudo -E ./setup 40                  # no COPR at all
```

Check coverage before depending on any of them:

```
curl -s "https://copr.fedorainfracloud.org/api_3/project?ownername=OWNER&projectname=PROJ" \
  | python3 -c 'import json,sys; print(sorted(json.load(sys.stdin)["chroot_repos"]))'
```

Sway stays available as a fallback: it is in Fedora proper for every arch and
ships a working config, which makes it useful for isolating whether a problem
is the graphics path or Hyprland itself.

## Dev VM vs target machine

`bin/vm` runs an **aarch64** guest (native `hvf` on Apple Silicon, so it is
fast). The target machine is **x86_64**. Most steps are arch-independent, but
these are not:

| Thing | aarch64 VM | x86_64 target |
| --- | --- | --- |
| `quickshell` COPR | builds | builds |
| `grub-btrfs` COPR | **no build** — step skips itself | builds |
| Snapshot entries in GRUB | **cannot be tested here** | the real test |
| `microcode_ctl` | n/a, skipped | installed by `30-hardware.sh` |
| Serial console | `console=ttyAMA0`, injected by `bin/vm` | not set |

So the VM validates the kickstart, snapper, the dnf snapshot hook, branding,
the desktop stack and dotfiles. The one thing it cannot validate is the
bootable-snapshot menu — verify that on the real machine before you trust it.

Neither COPR carries Fedora 42 any more; use 43 or later.

## Two things to verify before trusting metal

```
dnf info quickshell                                  # in Fedora proper, or COPR?
dnf copr list --available-by-user=kylegospo | grep grub-btrfs
```

Those are the only two dependencies outside Fedora's own release testing.
