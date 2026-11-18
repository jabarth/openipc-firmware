# Waybeam Custom OpenIPC Firmware

## Project Intent
This repository provides a highly specialized, custom build of the OpenIPC firmware tailored specifically for the **Sigmastar SSC338Q** chipset (commonly found in FPV hardware like the Emax Wyvern Link VTX). 

The primary goal of this fork is to serve as a fully-featured, pre-configured foundation for **Waybeam** (a custom VENC-based video streamer), completely replacing the standard OpenIPC `majestic` streaming daemon. It bridges the gap between official Emax VTX functionality and experimental features by natively bundling FPV tools, networking upgrades, and custom drivers.

## How it is Structured
This project maintains the standard Buildroot architecture of upstream OpenIPC, ensuring compatibility with official tools and pipelines:
- **Build System:** Leverages the official OpenIPC Buildroot environment.
- **Free-standing overlay, not a frozen snapshot:** The fork deliberately holds *no* firmware tree. Every build (`build-ssc338q.yml`) re-checks out the current HEAD of upstream `OpenIPC/firmware` `master` (`workflow_dispatch` lets you pin a specific ref too), then re-applies the small, durable Waybeam delta from `.github/waybeam-overlay/`. Upstream improvements — toolchain, board infra, kernel, package refreshes, CI fixes — flow in automatically; the customizations for the Wi-Fi driver and the rest of the tailored FPV stack live as a tracked overlay that survives every upstream move.
- **CI/CD:** Uses GitHub Actions (`build-ssc338q.yml`) to compile the firmware in the cloud on top of the live upstream `master`.
- **Artifact Packaging:** Preserves the official OpenIPC `make repack` macro. The GitHub Action outputs a fully packaged `openipc.ssc338q-nor-ultimate.tgz` archive. This `.tgz` archive is 100% compatible with the **OpenIPC Companion** Windows application's "Select File" flash method.

## How the Waybeam Delta Tracks Upstream

The customizations live in `.github/waybeam-overlay/` and split into two classes:

1. **Pure additions** — files with no upstream counterpart, copied verbatim over the upstream tree each build:
   - `general/package/rtl88x2cu/` — the libc0607 FPV fork of the Realtek 8812CU/8822CU Wi-Fi driver.
   - `.github/workflows/build-ssc338q.yml`, `.gitlab-ci.yml`, `README-Waybeam.md`.

   (`waybeam` itself is no longer ours: upstream `OpenIPC/firmware` adopted the SigmaStar encoder package on 2026-08-29 as `general/package/waybeam/` — selected in the defconfig as `BR2_PACKAGE_WAYBEAM`, maintained upstream, and it supersedes the old pinned `waybeam_venc` overlay package.)

2. **Surgical patches** — tiny `git apply --3way` hunks against upstream-maintained files, so upstream's evolution of those files is preserved except for our precise intent:
   - `package_Config.in.patch` — registers `rtl88x2cu` and drops `txw8301-openipc`.
   - `Makefile.patch` — the 10MB rootfs repack (`8192` → `10240`).
   - `ssc338q_ultimate_defconfig.patch` — enables the FPV stack (`waybeam` (upstream package), `rtl88x2cu`, `wifibroadcast-ng`, `adaptive-link`, `msposd`, `i2c-telemetry`, `mavlink-router`, `nano`, `htop`) and removes `majestic` + `zerotier-one`.
   - `README.md.patch` — the flashing-prerequisite warning banner.

**Shared chassis files we deliberately take from upstream untouched:** `general/overlay/usr/sbin/sysupgrade`, `.github/workflows/build.yml`, `shell-tests.yml`, `uboot.yml`. Our older fork had stale versions of these; overlaying them wholesale would replay old bugs against a moving upstream, so they track `master` instead.

When upstream refactors a patched region, the `--3way` application reconciles cleanly or — for a genuine semantic conflict — fails the build with the patch name in the log. That red CI is the signal to refresh one or two patch hunks (a few-line review), not a wholesale file replacement. See `.github/waybeam-overlay/README.md` for the refresh procedure and layout.

## Flash Layout Modification (10MB Rootfs)
### ⚠️ CRITICAL PRE-REQUISITE FOR FLASHING
Standard 16MB NOR flash chips use an 8MB `rootfs` partition limit. Because this firmware packs extensive networking and FPV packages, we expanded the rootfs boundary to **10MB** by stealing 2MB from the unused `rootfs_data` partition. 

**Before flashing this firmware, you must update the U-Boot environment on your camera to recognize the new 10MB boundary.**

SSH into your camera and execute the following:
```bash
CURRENT_MTD=$(fw_printenv mtdparts | cut -d= -f2-)
NEW_MTD=$(echo $CURRENT_MTD | sed 's/8192k(rootfs)/10240k(rootfs)/')
fw_setenv mtdparts "$NEW_MTD"
reboot
```
Once rebooted, you may safely flash the `.tgz` file using the Companion app.

## How it Differs from Official OpenIPC

1. **Waybeam Replaces Majestic:** 
   - **Official:** Relies on `majestic` as the primary streaming service.
   - **This Fork:** Majestic is completely removed from the Buildroot configuration (`BR2_PACKAGE_MAJESTIC is not set`). This ensures zero space is wasted and prevents pipeline conflicts. The upstream `waybeam` package (`BR2_PACKAGE_WAYBEAM`, added to OpenIPC 2026-08-29) is selected as the primary daemon, with its respawn/watchdog-aware init script and unlocked imx335/imx415 sensor modules.
2. **Native Wi-Fi Integration:**
   - The `rtl88x2cu` kernel module is compiled directly into the rootfs, supporting RTL8812CU/8822CU Wi-Fi adapters natively.
3. **WFB-NG & Adaptive Link:**
   - Includes `wifibroadcast-ng` and `adaptive-link` packages. Waybeam pipes its video output directly into the WFB-NG daemon for immediate, low-latency FPV transmission.
4. **Telemetry & OSD Engine:**
   - Includes `MSPOSD`, which allows the hardware to natively draw Betaflight/INAV OSD elements onto the video stream.
   - Includes `MAVLINK_ROUTER` and `I2C_TELEMETRY` to seamlessly multiplex flight controller telemetry over the WFB-NG link.
5. **Developer Comforts:**
   - Includes `htop` and `nano` to make in-field SSH debugging and configuration significantly easier.
6. **Custom Boot Sequence:**
   - The upstream package ships `/etc/init.d/S95waybeam` (the fork previously carried its own minimal init script; upstream's handles waybeam's `waybeam-resp`/`waybeam-wd` helper processes). The `rtl88x2cu` module is auto-loaded by the kernel/OSDRV module-loading machinery.
