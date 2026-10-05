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

## Phases

- [ ] **1. Kickstart that boots** — unattended, encrypted, correct subvolumes, no desktop
- [ ] **2. Rollback that works** — verified by actually rolling back once
- [ ] **3. Minimal desktop** — Hyprland + Quickshell, enough for a day's work
- [ ] **4. Hardware** — first time on real metal; fill in `setup.d/30-hardware.sh`
- [ ] **5. Dotfiles + steady state** — symlinks, package list, the re-run habit

Phases 1 and 2 have nothing to do with the desktop, and they are the ones that
can waste a weekend. Do them first, boringly.

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
