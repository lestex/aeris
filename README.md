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
./bin/make-iso ~/Downloads/Fedora-Everything-netinst-x86_64-42-1.1.iso
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
sudo dnf install -y cowsay          # anything; the hook snapshots it
sudo snapper -c root list           # confirm a pre/post pair appeared

# Reboot, pick the snapshot from the GRUB submenu. It mounts read-only —
# that is correct, and it is the point: you get to confirm this really is
# the good state before committing.

sudo snapper -c root rollback <number>
sudo systemctl reboot
```

`snapper rollback` works at the subvolume level: it saves the broken state as
a read-only snapshot, derives a writable subvolume from your target, and makes
that the default. No overlay needed.

If there is no Snapshots submenu in GRUB, `grub-btrfsd` is not running —
re-run `sudo ./setup 20`.

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

## Two things to verify before trusting metal

```
dnf info quickshell                                  # in Fedora proper, or COPR?
dnf copr list --available-by-user=kylegospo | grep grub-btrfs
```

Those are the only two dependencies outside Fedora's own release testing.
