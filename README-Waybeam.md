# Waybeam Custom OpenIPC Firmware

## Project Intent
This repository provides a highly specialized, custom build of the OpenIPC firmware tailored specifically for the **Sigmastar SSC338Q** chipset (commonly found in FPV hardware like the Emax Wyvern Link VTX). 

The primary goal of this fork is to serve as a fully-featured, pre-configured foundation for **Waybeam** (a custom VENC-based video streamer), completely replacing the standard OpenIPC `majestic` streaming daemon. It bridges the gap between official Emax VTX functionality and experimental features by natively bundling FPV tools, networking upgrades, and custom drivers.

## How it is Structured
This project maintains the standard Buildroot architecture of upstream OpenIPC, ensuring compatibility with official tools and pipelines:
- **Build System:** Leverages the official OpenIPC Buildroot environment.
- **CI/CD:** Uses GitHub Actions (`build-ssc338q.yml`) to automatically compile the firmware in the cloud.
- **Artifact Packaging:** Preserves the official OpenIPC `make repack` macro. The GitHub Action outputs a fully packaged `openipc.ssc338q-nor-ultimate.tgz` archive. This `.tgz` archive is 100% compatible with the **OpenIPC Companion** Windows application's "Select File" flash method.

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
   - **This Fork:** Majestic is completely removed from the Buildroot configuration (`BR2_PACKAGE_MAJESTIC is not set`). This ensures zero space is wasted and prevents pipeline conflicts. The `waybeam_venc` package is compiled and installed as the primary daemon.
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
   - A custom init script (`/etc/init.d/S95waybeam`) is executed during system startup. This script automatically performs a `modprobe 88x2cu` to initialize the Wi-Fi adapter (adhering to OpenIPC's standard module-loading practices) and spawns the `waybeam_venc` service.
