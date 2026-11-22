# Bananarchy Linux on LYF Jio F90M (`bananarchy-lyf-f90m`)

[![Mainline Linux](https://img.shields.io/badge/Kernel-6.12.1--msm8916-brightgreen.svg)](https://github.com/msm8916-mainline/linux)
[![Architecture](https://img.shields.io/badge/Architecture-ARMv7--A%20(armv7hf)-blue.svg)](https://postmarketos.org)
[![Display](https://img.shields.io/badge/Display-ST7789%20SPI%20(240x320)-orange.svg)]()
[![UI](https://img.shields.io/badge/UI-Xlibre%20%2B%20sxmo--dwm%20%2B%20NeoUI-purple.svg)]()
[![Status](https://img.shields.io/badge/Hardware%20Status-Boots%20Cleanly-success.svg)]()

Port of **[Bananarchy Linux](https://bananarchy.org)** (a keypad-first, ultra-lightweight Linux distribution based on Alpine `edge` / postmarketOS `v26.06`, pure X11 `Xlibre`, `sxmo-dwm`, and `NeoUI`) to the **LYF Jio F90M** 4G smart feature phone, running mainline Linux **`6.12.1-msm8916`**.

---

## 1. Project Overview & Hardware Specifications

The **LYF Jio F90M** is a Qualcomm Snapdragon-powered smart feature phone originally running KaiOS. This project brings a full mainline Linux user experience with low RAM usage (< 95 MB idle RAM on a 512 MB device) and native T9 keypad navigation.

### Hardware Specifications

| Component | Technical Specification |
| :--- | :--- |
| **SoC** | Qualcomm Snapdragon 205 (**MSM8905**, dual-core ARM Cortex-A7 @ 1.1 GHz) |
| **Silicon Identifiers** | HWID: `0x000940e100000000`, SoC ID: `0x000940e1`, Platform ID: `0x14b` |
| **PMIC** | Qualcomm **PM8909** (PMIC ID: `0x1000d`) |
| **GPU** | Qualcomm Adreno 304 (`FD304`) with Glamor + DRI3 + GLX acceleration |
| **Memory** | 512 MB LPDDR3 RAM |
| **Storage** | 4 GB eMMC 5.0 (Samsung / SK Hynix `H4G2a`), 30 partitions |
| **Display** | 2.4" 240x320 QVGA TFT display, Sitronix ST7789 controller over BLSP1 SPI5 (`panel-mipi-dbi-spi`) |
| **Keypad** | 18-key matrix keypad (T9 numeric + softkeys + D-pad) + 3 discrete PMIC/GPIO keys |
| **Wireless** | Qualcomm WCN36xx (WiFi 802.11b/g/n, Bluetooth 4.1) |
| **Audio** | Qualcomm QDSP6 Hexagon DSP v5, PM8909 audio codec |
| **Power / Battery** | Removable Li-ion battery (~1500–2000 mAh), Micro-USB charging |
| **Flashing / Recovery**| Qualcomm EDL Sahara/Firehose (`VID_05C6&PID_9008`) & Little Kernel Fastboot (`VID_18D1&PID_D00D`) |
| **Target Kernel** | Mainline Linux `6.12.1-msm8916` armv7 (Zero downstream Android 3.10 fallback) |

---

## 2. Hardware Status & Known Issues

### What Works
- [x] **Secondary Bootloader (`lk2nd-msm8909` v23.1):** Chainloaded from the stock `aboot` partition. Quiesces display DMA and clocks, establishes PSCI, and presents a standard Fastboot interface (`fastboot boot` / `fastboot flash`).
- [x] **Mainline Kernel (`6.12.1-msm8916`):** Boots cleanly with SMP initialization on Cortex-A7 dual-core (`cpu@2` and `cpu@3` are disabled in DTS to prevent silicon bus fault deadlocks).
- [x] **Display & Console:** Sitronix ST7789 initialized over BLSP1 SPI5 (`spi0.0`) at 50 MHz via `panel-mipi-dbi-spi`. DRM driver binds `/dev/fb0` with full `fbcon` console output and graphical splash.
- [x] **Full 18-Key Matrix Keypad:** All 18 matrix buttons fully functional after resolving the BLSP SPI6 pinctrl conflict on Columns 0 & 1 (GPIO 8 and 9).
- [x] **Discrete Keys:** D-Pad Up (GPIO 90 via `gpio-keys`), D-Pad Down (PM8909 RESIN), and Power / End Call (PM8909 PWRKEY).
- [x] **USB Gadget Debugging:** ChipIdea UDC (`dr_mode = peripheral`) initializes `libcomposite`, `u_ether`, `usb_f_rndis`, `u_serial`, and `usb_f_acm` modules. SSH and Telnet network shell available out of the box at `172.16.42.1`.
- [x] **Graphical Environment:** Xlibre display server, custom `dwm`, `sxmo-dmenu`, `NeoUI`, and `fcitx5-t9` input method for T9 predictive text.
- [x] **eMMC Storage:** All 30 partitions enumerated via `sdhci@7824900`. Root filesystem boots reliably from `mmcblk0p30` (`userdata`).
- [x] **Peripherals:** PM8909 haptic vibrator (`pm8xxx-vib`) and torch LED (`gpio-leds`).

### Known Issues
- [ ] **White Screen on Display Blank / Suspend:** When the display blanks or enters sleep, the screen turns solid white rather than turning off. Because the ST7789 panel is a normally-white TFT LCD, putting the controller to sleep while the LED backlight remains powered makes the liquid crystals default to transparent. This will be addressed in an upcoming DTB revision with synchronized backlight power-down sequencing.

---

## 3. Keypad Matrix Reference Table

The LYF Jio F90M uses a **4-row by 5-column** active-low matrix scanned by `gpio-matrix-keypad`, alongside three discrete lines handled by `gpio-keys` and PM8909 PON.

### Matrix Pinout
- **Rows (Inputs with Pull-Up):** Row 0: `GPIO 97`, Row 1: `GPIO 96`, Row 2: `GPIO 95`, Row 3: `GPIO 94`
- **Columns (Outputs driven Low):** Col 0: `GPIO 8`, Col 1: `GPIO 9`, Col 2: `GPIO 7`, Col 3: `GPIO 99`, Col 4: `GPIO 6`

Scan code formula: $\text{MSC\_SCAN} = (\text{row} \ll 3) \mid \text{col}$

### Complete Verified Keymap Table

| Matrix Coordinate | Scan Code (Hex / Dec) | Stock KaiOS Code | Linux Keycode (Hex / Dec) | Linux Event Constant | Physical Button on F90M |
| :---: | :---: | :---: | :---: | :--- | :--- |
| **Row 0, Col 0** | `0x00` (0) | `0x000000e7` | `0x000000e7` (231) | `KEY_SEND` | **Call (Green)** |
| **Row 0, Col 1** | `0x01` (1) | `0x00010069` | `0x00010069` (105) | `KEY_LEFT` | **D-Pad Left** |
| **Row 0, Col 2** | `0x02` (2) | `0x0002006a` | `0x0002006a` (106) | `KEY_RIGHT` | **D-Pad Right** |
| **Row 0, Col 3** | `0x03` (3) | `0x000301fe` | `0x000302b8` (696) | `KEY_KBD_LCD_MENU1` | **Left Softkey (LSK / Jio)** |
| **Row 0, Col 4** | `0x04` (4) | `0x0004001c` | `0x0004001c` (28) | `KEY_ENTER` | **Center / OK** |
| **Row 1, Col 0** | `0x08` (8) | `0x01000004` | `0x01000004` (4) | `KEY_3` | **Key 3** |
| **Row 1, Col 1** | `0x09` (9) | `0x01010007` | `0x01010007` (7) | `KEY_6` | **Key 6** |
| **Row 1, Col 2** | `0x0a` (10) | `0x010200e3` | `0x0102020a` (522) | `KEY_NUMERIC_STAR` | **Key \*** |
| **Row 1, Col 3** | `0x0b` (11) | `0x010300e4` | `0x0103020b` (523) | `KEY_NUMERIC_POUND`| **Key #** |
| **Row 1, Col 4** | `0x0c` (12) | `0x0104000a` | `0x0104000a` (10) | `KEY_9` | **Key 9** |
| **Row 2, Col 0** | `0x10` (16) | `0x02000003` | `0x02000003` (3) | `KEY_2` | **Key 2** |
| **Row 2, Col 1** | `0x11` (17) | `0x02010006` | `0x02010006` (6) | `KEY_5` | **Key 5** |
| **Row 2, Col 2** | `0x12` (18) | `0x020201ff` | `0x020202b9` (697) | `KEY_KBD_LCD_MENU2` | **Right Softkey (RSK / Back)** |
| **Row 2, Col 3** | `0x13` (19) | `0x0203000b` | `0x0203000b` (11) | `KEY_0` | **Key 0** |
| **Row 2, Col 4** | `0x14` (20) | `0x02040009` | `0x02040009` (9) | `KEY_8` | **Key 8** |
| **Row 3, Col 0** | `0x18` (24) | `0x03000002` | `0x03000002` (2) | `KEY_1` | **Key 1** |
| **Row 3, Col 1** | `0x19` (25) | `0x03010005` | `0x03010005` (5) | `KEY_4` | **Key 4** |
| **Row 3, Col 2** | `0x1a` (26) | `0x03020008` | `0x03020008` (8) | `KEY_7` | **Key 7** |

### Discrete Keys (Non-Matrix)

| Key Name | Driver / Subsystem | Pin / Line | Linux Event Constant | Action / Role |
| :--- | :--- | :--- | :--- | :--- |
| **D-Pad Up** | `gpio-keys` | `GPIO 90` | `KEY_UP` (`0x67` / 103) | Navigation Up / SOS Button |
| **D-Pad Down** | PM8909 PON | `pm8941_resin` | `KEY_DOWN` (`0x6c` / 108) | Navigation Down |
| **Power / End Call** | PM8909 PON | `pm8941_pwrkey` | `KEY_POWER` (`0x74` / 116) | Power / Lock / End Call |

---

## 4. Installation & Flashing Instructions

> [!CAUTION]
> **CRITICAL SAFETY RULES:**
> 1. **NEVER flash primary bootloader partitions** (`sbl1`, `aboot`, `tz`, `rpm`, `modem`). Doing so can permanently hard-brick the device if signing keys or partition tables differ.
> 2. Only write to **`boot`** (kernel/lk2nd) and **`userdata`** (Bananarchy OS rootfs).

### Prerequisites
1. Install `fastboot` on your host PC (`android-tools` on Linux or Android SDK Platform-Tools on Windows).
2. Download the release files from the **[GitHub Releases](https://github.com/bananarchy/bananarchy-lyf-f90m/releases)** page:
   - `lk2nd-f90m.img` (Secondary bootloader)
   - `boot-f90m.img` (Mainline kernel + DTB + initramfs)
   - `bananarchy-lyf-f90m.sparse.img` (Bananarchy OS rootfs image)
3. *(Recommended)* Install Qualcomm EDL tool (`edl.py` or `qdl`) and obtain the MSM8909 Firehose loader (`prog_emmc_firehose_8909_ddr.mbn`) for emergency recovery and full factory backup.

---

### Step 1: Backup Factory Partitions (Recommended)

Before flashing anything, take a bit-accurate dump of your stock partitions over EDL mode (`05c6:9008`):

```bash
# Backup factory boot and userdata partitions
python edl.py --loader=prog_emmc_firehose_8909_ddr.mbn r boot boot-stock-backup.img
python edl.py --loader=prog_emmc_firehose_8909_ddr.mbn r userdata userdata-stock-backup.img
```

---

### Step 2: Boot into Fastboot Mode

1. Power off the phone completely (pull and reinsert the battery).
2. Connect the phone to your PC via USB while holding the **Up D-Pad** button (or **Call + Power**).
3. Verify that the device enumerates as `VID_18D1&PID_D00D`:
   ```bash
   fastboot devices
   ```

---

### Step 3: Option A — Live Non-Destructive Boot Test (RAM Boot)

To test Bananarchy Linux directly without modifying your device's internal storage:

```bash
fastboot boot boot-f90m.img
```

The device will boot directly into mainline Linux in RAM, bring up the ST7789 display console, and provide a network shell over USB at `172.16.42.1`.

---

### Step 4: Option B — Permanent Installation

To flash Bananarchy Linux permanently to the phone:

1. Flash `lk2nd` secondary bootloader to `boot`:
   ```bash
   fastboot flash boot lk2nd-f90m.img
   ```
2. Flash the partitioned OS disk image to `userdata`:
   ```bash
   fastboot flash userdata bananarchy-lyf-f90m.sparse.img
   ```
3. Reboot into Bananarchy Linux:
   ```bash
   fastboot reboot
   ```

On boot, stock `aboot` starts `lk2nd`, which initializes clocks, quiesces MDSS DMA, passes the mainline DTB, and mounts the rootfs on `userdata` (`mmcblk0p30`).

---

### Step 5: Post-Boot Access & Default Credentials

- **USB Networking:** Static IP `172.16.42.1`
- **Host Interface Setup:**
  - Linux: `sudo ifconfig usb0 172.16.42.2 netmask 255.255.255.0`
  - Windows: Set RNDIS Ethernet adapter IPv4 address to `172.16.42.2` / `255.255.255.0`
- **SSH / Telnet Login:**
  ```bash
  ssh user@172.16.42.1
  # or
  telnet 172.16.42.1
  ```
- **Default User:** `user` (password: `147147`)
- **Root Password:** `root`
- **Default Lockscreen Passcode (NeoUI / xpasscode):** `147147`

---

### Step 6: Emergency EDL Recovery / Restore Stock

If the device ever fails to reach Fastboot, enter EDL mode by holding the boot key combo or shorting the EDL test point while plugging in USB, then restore the stock boot partition:

```bash
python edl.py --loader=prog_emmc_firehose_8909_ddr.mbn w boot boot-stock-backup.img
```

---

## 5. Credits & Acknowledgments

This port is built upon the incredible work of the mobile Linux and mainline Snapdragon communities:

- **[Bananarchy Linux](https://bananarchy.org):** The keypad-first Linux distribution, base rootfs recipes, `nokia-argon` reference target, `NeoUI`, `fcitx5-t9` input engine, and image build tooling.
- **[postmarketOS](https://postmarketos.org) & [msm8916-mainline](https://github.com/msm8916-mainline):** Mainline Linux `6.12.1-msm8916` kernel tree, `panel-mipi-dbi-spi` DRM driver, and the initramfs framework.
- **[lk2nd Project](https://github.com/msm8916-mainline/lk2nd):** The secondary bootloader that makes booting mainline Linux possible on locked Little Kernel devices by cleanly handling clocks, DMA quiescence, and DTB passing.
- **[Sxmo](https://sxmo.org) (`sxmo-dwm` / `sxmo-dmenu`) & [Xlibre](https://gitlab.freedesktop.org/xorg/xserver):** Lightweight keypad-driven window manager, application launcher, and X11 server stack.
- **[bkerler/edl](https://github.com/bkerler/edl):** Qualcomm Sahara/Firehose EDL flasher and raw partition backup utility.
