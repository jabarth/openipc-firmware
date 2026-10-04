# Waybeam Customization Overlay

This directory is the **Waybeam delta**: the durable customizations layered on
top of upstream `OpenIPC/firmware` so this fork always tracks `master` without
bit-rotting into a frozen upstream snapshot.

## Layout

```
waybeam-overlay/
  apply.sh          # copies files/ over the tree, re-applies patches/*.patch
  files/            # pure-addition files we ADD (no upstream counterpart)
    general/package/rtl88x2cu/     # libc0607 FPV Wi-Fi driver
    .github/workflows/build-ssc338q.yml   # custom single-platform CI
    .gitlab-ci.yml                  # GitLab mirror build
    README-Waybeam.md               # project intent + flashing prereq
  patches/          # surgical git-format patches vs upstream-maintained files
    package_Config.in.patch                                   # +register rtl88x2cu, -txw8301
    Makefile.patch                                            # 10MB rootfs: repack 8192 -> 10240
    ssc338q_ultimate_defconfig.patch  # +FPV stack, -majestic, -zerotier
    README.md.patch                                           # flashing prerequisite warning
```

## How the fork tracks upstream

`build-ssc338q.yml` does NOT build this repo's working tree. Instead, each run:

1. Checks out `OpenIPC/firmware` `master` HEAD into a clean worktree.
2. Commits that pristine upstream snapshot (only so `git apply --3way` has an
   index to reconcile against — no branch is published).
3. Runs `apply.sh` to drop in the Waybeam files + re-apply the patches.
4. Builds `BOARD=ssc338q_ultimate`.

So upstream moves and your fork follows. When upstream refactors a patched
region, `git apply --3way` produces a marked conflict → **red CI**, exactly
the visibility you want. There is no silent drift: either the patch applies,
reconciles, or the build stops and tells you which patch to refresh.

## Files deliberately NOT overlaid (accept upstream's version)

These are shared chassis files upstream actively improves; our older fork had
stale versions of them. Tracking upstream's keeps the fork honest:

- `general/package/Config.in`        - we PATCH it (registration lines), never overlay it wholesale
- `Makefile`                         - we PATCH it (10MB rootfs), never overlay wholesale
- `general/overlay/usr/sbin/sysupgrade` - take upstream
- `.github/workflows/build.yml`      - take upstream's nightly matrix verbatim
- `.github/workflows/shell-tests.yml` - take upstream (don't drop sysupgrade-verify)
- `.github/workflows/uboot.yml`      - take upstream (don't revert the gh-CLI upload)

If you need to *gain* a customization on one of these, add a new
`patches/*.patch` here rather than editing the file directly. The only fork
files that should be touched directly in `master` are the ones under
`files/` and these overlay scripts.

## Refreshing the patches

When CI goes red with `patch FAILED to apply`:

```sh
# from a clone of THIS fork, with upstream fetched
git fetch upstream master
git checkout -b refresh-patches upstream/master
.github/waybeam-overlay/apply.sh .           # see which hunk conflicts
# resolve, then regenerate the offending patch:
git diff upstream/master > .github/waybeam-overlay/patches/<name>.patch
```

The patches are intentionally tiny and surgical — refreshing one should be a
few-line review, never a wholesale file replacement.

## Upstream pin

`build-ssc338q.yml` records the upstream ref each build consumed, in the
release notes (`upstream=<sha>`), giving full traceability from a flashed
image back to the exact upstream commit + overlay version it was built from.
