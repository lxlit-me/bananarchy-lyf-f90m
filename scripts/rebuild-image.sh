#!/bin/sh
# Bananarchy Linux (MSM8909 / Sxmo) Image Builder
# Supports: nokia-argon (8110 4G), nokia-beatles (2720 Flip),
#           nokia-tough (800 Tough), nokia-sparkler (8000 4G), nokia-leo (6300 4G)
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -n "${ROOTFS_DIR:-}" ]; then
  ROOTFS_HOST="$(realpath "$ROOTFS_DIR")"
elif [ -d "$SCRIPT_DIR/rootfs-sxmo" ]; then
  ROOTFS_HOST="$(realpath "$SCRIPT_DIR/rootfs-sxmo")"
else
  ROOTFS_HOST="$(realpath "$SCRIPT_DIR/rootfs")"
fi

mkdir -p "${IMAGES_DIR:-$SCRIPT_DIR/images}"
IMAGES_HOST="$(realpath "${IMAGES_DIR:-$SCRIPT_DIR/images}")"
BANANARCHY_DIR="$SCRIPT_DIR"

TARGET_DEVICE="nokia-argon"
RUN_MKINITFS=""

for arg in "$@"; do
  case "$arg" in
    --mkinitfs)
      RUN_MKINITFS="--mkinitfs"
      ;;
    sxmo|all|nokia-argon|argon)
      TARGET_DEVICE="nokia-argon"
      ;;
    lyf-f90m|f90m)
      TARGET_DEVICE="lyf-f90m"
      ;;
    nokia-beatles|beatles)
      TARGET_DEVICE="nokia-beatles"
      ;;
    nokia-tough|nokia-coconut|tough|coconut)
      TARGET_DEVICE="nokia-tough"
      ;;
    nokia-sparkler|sparkler)
      TARGET_DEVICE="nokia-sparkler"
      ;;
    nokia-leo|leo)
      TARGET_DEVICE="nokia-leo"
      ;;
    *)
      echo "Usage: $0 [lyf-f90m|nokia-argon|nokia-beatles|nokia-tough|nokia-sparkler|nokia-leo] [--mkinitfs]" >&2
      exit 1
      ;;
  esac
done

mkdir -p "$IMAGES_HOST"

ensure_prebuilt_artifacts() {
  if [ ! -f "$BANANARCHY_DIR/prebuilt/sxmo-x11/usr/lib/libneoui.so" ] || \
     [ ! -f "$BANANARCHY_DIR/prebuilt/sxmo-x11/usr/bin/dwm" ] || \
     [ ! -f "$BANANARCHY_DIR/prebuilt/sxmo-x11/usr/bin/st" ] || \
     [ ! -f "$BANANARCHY_DIR/prebuilt/sxmo-x11/usr/lib/dwm/plugins/dmenu.so" ] || \
     [ ! -f "$BANANARCHY_DIR/prebuilt/sxmo-x11/usr/lib/dwm/plugins/privacy.so" ]; then
    echo "[auto-deps] Missing prebuilt sxmo-x11/NeoUI artifacts; running scripts/build-sxmo-x11.sh..."
    "$BANANARCHY_DIR/scripts/build-sxmo-x11.sh"
  fi

  if [ ! -f "$BANANARCHY_DIR/prebuilt/games/usr/bin/snake" ] || \
     [ ! -f "$BANANARCHY_DIR/prebuilt/games/usr/bin/tetris" ] || \
     [ ! -f "$BANANARCHY_DIR/prebuilt/games/usr/bin/scoundrel" ] || \
     [ ! -f "$BANANARCHY_DIR/prebuilt/games/usr/bin/gambatte" ] || \
     [ ! -f "$BANANARCHY_DIR/prebuilt/games/usr/bin/remedy" ]; then
    echo "[auto-deps] Missing prebuilt games/emulators; running scripts/build-games.sh..."
    "$BANANARCHY_DIR/scripts/build-games.sh"
  fi

  if [ ! -f "$BANANARCHY_DIR/prebuilt/gsocket/usr/bin/gs-netcat" ] || \
     [ ! -f "$BANANARCHY_DIR/prebuilt/gsocket/usr/lib/gsocket_dso.so.0" ]; then
    echo "[auto-deps] Missing prebuilt gsocket binaries; running scripts/build-gsocket.sh..."
    "$BANANARCHY_DIR/scripts/build-gsocket.sh"
  fi

  if [ ! -f "$BANANARCHY_DIR/prebuilt/fcitx5-t9/usr/lib/fcitx5/libt9.so" ]; then
    echo "[auto-deps] Missing prebuilt fcitx5-t9 engine; running scripts/build-fcitx5-t9.sh..."
    "$BANANARCHY_DIR/scripts/build-fcitx5-t9.sh"
  fi

  if [ ! -f "$BANANARCHY_DIR/prebuilt/xlibre/usr/bin/Xorg" ] || \
     [ ! -f "$BANANARCHY_DIR/prebuilt/xlibre/usr/lib/xorg/modules/xlibre-25/drivers/modesetting_drv.so" ]; then
    echo "[auto-deps] Missing prebuilt Xlibre server/drivers; running scripts/build-xlibre.sh..."
    "$BANANARCHY_DIR/scripts/build-xlibre.sh"
  fi

  if [ ! -f "$BANANARCHY_DIR/prebuilt/kernel-6.12.1-msm8916/dtbs/qcom-msm8905-nokia-argon.dtb" ] || \
     [ ! -f "$BANANARCHY_DIR/prebuilt/kernel-6.12.1-msm8916/drm/msm.ko.zst" ] || \
     [ ! -f "$BANANARCHY_DIR/prebuilt/kernel-6.12.1-msm8916/netfilter/xt_owner.ko.zst" ] || \
     [ ! -f "$BANANARCHY_DIR/prebuilt/kernel-6.12.1-msm8916/netfilter/nft_redir.ko.zst" ] || \
     [ ! -f "$BANANARCHY_DIR/prebuilt/kernel-6.12.1-msm8916/leds/leds-msm8905-torch.ko.zst" ] || \
     [ ! -f "$BANANARCHY_DIR/prebuilt/kernel-6.12.1-msm8916/camera/msm8905-cam.ko.zst" ]; then
    echo "[auto-deps] Missing prebuilt kernel modules or DTBs; running scripts/build-kernel-audio.sh..."
    "$BANANARCHY_DIR/scripts/build-kernel-audio.sh"
  fi

  if [ ! -f "$BANANARCHY_DIR/prebuilt/bantam/bantam" ]; then
    echo "[auto-deps] Missing prebuilt bantam binary; running scripts/build-bantam.sh..."
    "$BANANARCHY_DIR/scripts/build-bantam.sh"
  fi
}

ensure_prebuilt_artifacts

docker run --rm -v "$ROOTFS_HOST:/rootfs" alpine:3.24 chown -R "$(id -u):$(id -g)" /rootfs

if [ -x "$BANANARCHY_DIR/scripts/apply-bananarchy-overlay.sh" ]; then
  "$BANANARCHY_DIR/scripts/apply-bananarchy-overlay.sh" "$ROOTFS_HOST" "$TARGET_DEVICE"
fi

BANANARCHY_VERSION="$("$BANANARCHY_DIR/scripts/version.sh" --print)"
"$BANANARCHY_DIR/scripts/version.sh" "$ROOTFS_HOST" >/dev/null

exec docker run --rm --network=host \
  -e HOST_UID="$(id -u)" \
  -e HOST_GID="$(id -g)" \
  -e TARGET_DEVICE="$TARGET_DEVICE" \
  -e RUN_MKINITFS="$RUN_MKINITFS" \
  -e BANANARCHY_VERSION="$BANANARCHY_VERSION" \
  -v "$ROOTFS_HOST:/rootfs" \
  -v "$IMAGES_HOST:/images" \
  -v "$BANANARCHY_DIR:/bananarchy:ro" \
  alpine:3.24 sh -eu -c '
  cat > /etc/apk/repositories <<EOF
https://mirror.nura.eco/postmarketos/v26.06
https://dl-cdn.alpinelinux.org/alpine/edge/main
https://dl-cdn.alpinelinux.org/alpine/edge/community
https://dl-cdn.alpinelinux.org/alpine/edge/testing
EOF
  cp /bananarchy/keys/* /etc/apk/keys/

  apk add --no-cache \
    busybox-static \
    kmod \
    pax-utils \
    python3 \
    postmarketos-mkinitfs \
    boot-deploy \
    mkbootimg \
    devicepkg-utils \
    e2fsprogs \
    e2fsprogs-extra \
    util-linux \
    sfdisk \
    coreutils \
    android-tools \
    zstd >/dev/null

  ROOTFS="/rootfs"
  BOOT_UUID="a1b2c3d4-8110-4000-8000-000000000001"
  ROOT_UUID="a1b2c3d4-8110-4000-8000-000000000002"

  echo "============================================================"
  echo "Building Bananarchy Linux $BANANARCHY_VERSION (Sxmo 240x320) for: $TARGET_DEVICE"
  echo "Source rootfs: $ROOTFS"
  echo "============================================================"

  echo "[0/5] Checking target rootfs dependencies..."
  cp /etc/apk/repositories "$ROOTFS/etc/apk/repositories" 2>/dev/null || true
  mkdir -p "$ROOTFS/etc/apk/keys"
  cp /bananarchy/keys/* "$ROOTFS/etc/apk/keys/" 2>/dev/null || true

  REQUIRED_PKGS="
    adwaita-icon-theme
    alpine-base
    alsa-utils
    bash
    bc
    brightnessctl
    clickclack
    coreutils
    doas
    ed
    evtest
    fcitx5
    fcitx5-gtk3
    font-droid
    font-droid-nonlatin
    font-fira-code
    font-noto
    font-noto-emoji
    font-twemoji
    frotz
    g++
    gcc
    git
    gst-libav
    gst-plugins-bad
    gst-plugins-good
    harfbuzz
    htop
    i2c-tools
    imv
    ip6tables
    iproute2
    iptables
    janet
    janet-dev
    jpm
    lang
    less
    libwpe
    libwpebackend-fdo
    libxcvt
    libxft
    libxinerama
    libxtst
    linux-postmarketos-qcom-msm8916
    lua5.4
    lua5.4-dev
    lua5.5
    lua5.5-dev
    make
    mandoc
    mesa-demos
    mesa-utils
    modemmanager
    musl-dev
    nano
    openssh
    openssh-server-pam
    openvpn
    perl
    perl-io-socket-ssl
    postmarketos-artwork-wallpapers
    postmarketos-base
    postmarketos-base-nofde
    postmarketos-base-ui
    postmarketos-base-ui-audio-backend-pipewire
    postmarketos-base-ui-wifi-wpa_supplicant
    postmarketos-ui-sxmo-de-dwm
    postmarketos-ui-sxmo-de-dwm-openrc
    qmi-utils
    rlwrap
    scrot
    setxkbmap
    sfeed
    soc-qcom-msm8909
    soc-qcom-msm8909-modem
    soc-qcom-msm8909-modem-openrc
    soc-qcom-msm8916
    soc-qcom-msm8916-rproc
    soc-qcom-msm8916-rproc-openrc
    soc-qcom-msm8916-ucm
    sqlite
    sqlite-tcl
    sudo-rs
    tcl
    tcl-lib
    tcl-tls
    tor
    ttyescape
    v4l-utils
    w3m
    webkit2gtk-4.1
    wireguard-tools
    wireguard-tools-wg
    wireguard-tools-wg-quick
    xf86-input-libinput
    xf86-video-fbdev
    yabasic
    yabasic-doc
    zram-init
    zram-init-openrc
  "

  MISSING_PKGS=""
  INSTALLED_DB="$ROOTFS/lib/apk/db/installed"
  INSTALLED_SET=""
  if [ -f "$INSTALLED_DB" ]; then
    INSTALLED_SET="$(awk "
      /^P:/ { print substr(\$0, 3) }
      /^p:/ {
        line = substr(\$0, 3)
        n = split(line, arr, \" \")
        for (i = 1; i <= n; i++) {
          sub(/=.*/, \"\", arr[i])
          print arr[i]
        }
      }
    " "$INSTALLED_DB" | sort -u)"
  fi
  for pkg in $REQUIRED_PKGS; do
    if ! printf "%s\n" "$INSTALLED_SET" | grep -Fxq "$pkg"; then
      MISSING_PKGS="$MISSING_PKGS $pkg"
    fi
  done

  # Verify critical runtime binaries exist even if listed in apk db
  [ -e "$ROOTFS/bin/bash" ] || [ -L "$ROOTFS/bin/bash" ] || MISSING_PKGS="$MISSING_PKGS bash"
  [ -e "$ROOTFS/usr/bin/tor" ] || [ -L "$ROOTFS/usr/bin/tor" ] || MISSING_PKGS="$MISSING_PKGS tor"
  [ -e "$ROOTFS/usr/sbin/openvpn" ] || [ -L "$ROOTFS/usr/sbin/openvpn" ] || MISSING_PKGS="$MISSING_PKGS openvpn"
  [ -e "$ROOTFS/usr/bin/wg" ] || [ -L "$ROOTFS/usr/bin/wg" ] || MISSING_PKGS="$MISSING_PKGS wireguard-tools-wg"
  [ -e "$ROOTFS/usr/bin/wg-quick" ] || [ -L "$ROOTFS/usr/bin/wg-quick" ] || MISSING_PKGS="$MISSING_PKGS wireguard-tools-wg-quick"
  [ -e "$ROOTFS/usr/sbin/iptables" ] || [ -L "$ROOTFS/usr/sbin/iptables" ] || MISSING_PKGS="$MISSING_PKGS iptables"
  [ -e "$ROOTFS/usr/sbin/ip6tables" ] || [ -L "$ROOTFS/usr/sbin/ip6tables" ] || MISSING_PKGS="$MISSING_PKGS ip6tables"
  [ -e "$ROOTFS/sbin/ip" ] || [ -L "$ROOTFS/sbin/ip" ] || MISSING_PKGS="$MISSING_PKGS iproute2"
  [ -e "$ROOTFS/usr/bin/yabasic" ] || [ -L "$ROOTFS/usr/bin/yabasic" ] || MISSING_PKGS="$MISSING_PKGS yabasic"
  [ -e "$ROOTFS/usr/bin/lua5.5" ] || [ -L "$ROOTFS/usr/bin/lua5.5" ] || MISSING_PKGS="$MISSING_PKGS lua5.5"
  [ -e "$ROOTFS/usr/bin/scrot" ] || [ -L "$ROOTFS/usr/bin/scrot" ] || MISSING_PKGS="$MISSING_PKGS scrot"

  # Scan ELF binaries and plugins for missing shared libraries (so:<lib>)
  EXISTING_LIBS="$(find "$ROOTFS/lib" "$ROOTFS/usr/lib" \( -type f -o -type l \) -name "*.so*" 2>/dev/null | sed "s|.*/||" | sort -u || true)"
  NEEDED_LIBS="$(scanelf -q -n -R \
    "$ROOTFS/usr/bin" \
    "$ROOTFS/usr/lib/dwm/plugins" \
    "$ROOTFS/usr/lib/fcitx5" \
    "$ROOTFS/usr/lib/xorg" 2>/dev/null | \
    awk "{print \$1}" | tr "," "\n" | sort -u || true)"
  for so in $NEEDED_LIBS; do
    [ -z "$so" ] && continue
    if ! printf "%s\n" "$EXISTING_LIBS" | grep -Fxq "$so"; then
      MISSING_PKGS="$MISSING_PKGS so:$so"
    fi
  done

  if [ -n "$MISSING_PKGS" ]; then
    echo "  -> Installing missing dependencies into $ROOTFS:$MISSING_PKGS"
    # shellcheck disable=SC2086
    apk --root "$ROOTFS" --arch armv7 add --no-scripts $MISSING_PKGS
    ln -sf lua5.5 "$ROOTFS/usr/bin/lua"
    ln -sf luac5.5 "$ROOTFS/usr/bin/luac"
    /bananarchy/scripts/apply-bananarchy-overlay.sh "$ROOTFS" "$TARGET_DEVICE"
  else
    echo "  -> All target rootfs packages and shared libraries are present."
  fi
  ln -sf lua5.5 "$ROOTFS/usr/bin/lua"
  ln -sf luac5.5 "$ROOTFS/usr/bin/luac"

  echo "[1/5] Normalizing rootfs permissions and UIDs/GIDs..."
  chown -R 0:0 "$ROOTFS"
  chmod 755 "$ROOTFS" 2>/dev/null || true
  chmod 700 "$ROOTFS/root" 2>/dev/null || true
  chmod 1777 "$ROOTFS/tmp" "$ROOTFS/var/tmp" 2>/dev/null || true
  chmod 555 "$ROOTFS/var/empty" 2>/dev/null || true
  chmod 750 "$ROOTFS/etc/doas.d" "$ROOTFS/etc/polkit-1/rules.d" 2>/dev/null || true
  if [ -e "$ROOTFS/etc/shadow" ]; then
    chown 0:42 "$ROOTFS/etc/shadow"
    chmod 640 "$ROOTFS/etc/shadow"
  fi
  if [ -e "$ROOTFS/etc/shadow-" ]; then
    chown 0:42 "$ROOTFS/etc/shadow-"
    chmod 640 "$ROOTFS/etc/shadow-"
  fi
  rm -f "$ROOTFS/etc/doas.d/wheel.conf"
  if [ -e "$ROOTFS/etc/doas.d/50-sxmo.conf" ]; then
    chmod 600 "$ROOTFS/etc/doas.d/50-sxmo.conf"
  fi
  if [ -e "$ROOTFS/etc/sudoers.d/wheel" ]; then
    chmod 440 "$ROOTFS/etc/sudoers.d/wheel"
  fi
  MB_GID="$(awk -F: "/^messagebus:/ {print \$3}" "$ROOTFS/etc/group" 2>/dev/null || true)"
  MB_GID="${MB_GID:-103}"
  if [ -e "$ROOTFS/usr/libexec/dbus-daemon-launch-helper" ]; then
    chown "0:$MB_GID" "$ROOTFS/usr/libexec/dbus-daemon-launch-helper"
    chmod 4750 "$ROOTFS/usr/libexec/dbus-daemon-launch-helper"
  fi
  PK_UID="$(awk -F: "/^polkitd:/ {print \$3}" "$ROOTFS/etc/passwd" 2>/dev/null || true)"
  PK_GID="$(awk -F: "/^polkitd:/ {print \$3}" "$ROOTFS/etc/group" 2>/dev/null || true)"
  if [ -n "$PK_UID" ] && [ -n "$PK_GID" ] && [ -d "$ROOTFS/etc/polkit-1/rules.d" ]; then
    chown "$PK_UID:$PK_GID" "$ROOTFS/etc/polkit-1/rules.d"
    chmod 750 "$ROOTFS/etc/polkit-1/rules.d"
  fi
  if [ -e "$ROOTFS/usr/sbin/unix_chkpwd" ]; then
    chown 0:42 "$ROOTFS/usr/sbin/unix_chkpwd"
    chmod 2755 "$ROOTFS/usr/sbin/unix_chkpwd"
  fi
  if [ -e "$ROOTFS/usr/bin/wall" ]; then
    chown 0:5 "$ROOTFS/usr/bin/wall"
    chmod 2755 "$ROOTFS/usr/bin/wall"
  fi
  if [ -e "$ROOTFS/usr/bin/Xorg" ] && [ ! -L "$ROOTFS/usr/bin/Xorg" ]; then
    chown 0:0 "$ROOTFS/usr/bin/Xorg"
    chmod 0755 "$ROOTFS/usr/bin/Xorg"
  fi
  for suid_bin in \
    "$ROOTFS/bin/su" \
    "$ROOTFS/bin/mount" \
    "$ROOTFS/bin/umount" \
    "$ROOTFS/usr/bin/doas" \
    "$ROOTFS/usr/bin/sudo" \
    "$ROOTFS/usr/bin/pkexec" \
    "$ROOTFS/usr/lib/polkit-1/polkit-agent-helper-1" \
    "$ROOTFS/usr/bin/fusermount3" \
    "$ROOTFS/usr/bin/passwd" \
    "$ROOTFS/usr/bin/gpasswd" \
    "$ROOTFS/usr/bin/chsh" \
    "$ROOTFS/usr/bin/chfn" \
    "$ROOTFS/usr/bin/chage" \
    "$ROOTFS/usr/bin/expiry" \
    "$ROOTFS/usr/bin/bananarchy-engmenu-exec"; do
    if [ -e "$suid_bin" ] && [ ! -L "$suid_bin" ]; then
      chmod 4755 "$suid_bin"
    fi
  done
  if [ -d "$ROOTFS/home/user" ]; then
    chown -R 10000:10000 "$ROOTFS/home/user"
  fi
  if [ -d "$ROOTFS/var/lib/tor" ]; then
    TOR_UID="$(awk -F: "/^tor:/ {print \$3}" "$ROOTFS/etc/passwd" 2>/dev/null || true)"
    TOR_GID="$(awk -F: "/^tor:/ {print \$4}" "$ROOTFS/etc/passwd" 2>/dev/null || true)"
    chown -R "${TOR_UID:-109}:${TOR_GID:-114}" "$ROOTFS/var/lib/tor"
    chmod 0700 "$ROOTFS/var/lib/tor"
  fi

  depmod -b "$ROOTFS" 6.12.1-msm8916

  # Automatically regenerate boot.img/initramfs if switching target devices
  LAST_DEV_FILE="$ROOTFS/boot/.bananarchy_target_device"
  LAST_DEV="$(cat "$LAST_DEV_FILE" 2>/dev/null || true)"
  if [ "$RUN_MKINITFS" = "--mkinitfs" ] || [ ! -f "$ROOTFS/boot/initramfs" ] || [ "$LAST_DEV" != "$TARGET_DEVICE" ]; then
    echo "[2/5] Running depmod and mkinitfs inside $ROOTFS (target: $TARGET_DEVICE)..."
    rm -rf "$ROOTFS/tmp/hostbin"
    mkdir -p "$ROOTFS/tmp/hostbin"
    cp /bin/busybox.static "$ROOTFS/tmp/hostbin/busybox.static"
    for app in $(/bin/busybox.static --list); do
      ln -sf /tmp/hostbin/busybox.static "$ROOTFS/tmp/hostbin/$app"
    done
    for bin in \
      /sbin/depmod \
      /usr/sbin/mkinitfs \
      /usr/bin/boot-deploy \
      /usr/bin/generate-kernel-cmdline \
      /usr/bin/mkbootimg \
      /usr/bin/mkbootimg-osm0sis \
      /usr/bin/zstd; do
      if [ -e "$bin" ]; then
        rm -f "$ROOTFS/tmp/hostbin/$(basename "$bin")"
        cp -L "$bin" "$ROOTFS/tmp/hostbin/"
      fi
    done
    rm -f "$ROOTFS/tmp/hostbin/df"
    cat > "$ROOTFS/tmp/hostbin/df" <<EOF
#!/tmp/hostbin/sh
printf "Filesystem 1024-blocks Used Available Capacity Mounted on\n/dev/root 52428800 5242880 47185920 10%% /\n"
EOF
    chmod +x "$ROOTFS/tmp/hostbin/df"
    mkdir -p "$ROOTFS/proc/1/root"
    cp /lib/ld-musl-x86_64.so.1 "$ROOTFS/lib/"
    cp -a /usr/lib/libgcc_s.so* "$ROOTFS/tmp/hostbin/" 2>/dev/null || true
    cp -a /lib/libz.so* /usr/lib/libzstd.so* /usr/lib/liblzma.so* /lib/libcrypto.so* "$ROOTFS/tmp/hostbin/" 2>/dev/null || true
    ln -sf /tmp/hostbin/busybox.static "$ROOTFS/bin/sh"

    chroot "$ROOTFS" /tmp/hostbin/busybox.static sh -e -c "
      export PATH=/tmp/hostbin:/usr/sbin:/usr/bin:/sbin:/bin
      export LD_LIBRARY_PATH=/tmp/hostbin:/lib:/usr/lib
      /tmp/hostbin/mkinitfs
    "

    ln -sf /bin/busybox "$ROOTFS/bin/sh"
    rm -rf "$ROOTFS/tmp/hostbin" "$ROOTFS/lib/ld-musl-x86_64.so.1" "$ROOTFS/proc/1"
    echo "$TARGET_DEVICE" > "$LAST_DEV_FILE"
  else
    echo "[2/5] Using existing $ROOTFS/boot/initramfs (pass --mkinitfs to regenerate)..."
  fi

  echo "[3/5] Creating ext2 boot (256 MiB) and ext4 root filesystems..."
  BOOT_IMG="/tmp/boot.ext2"
  ROOT_IMG="/tmp/root.ext4"
  rm -f "$BOOT_IMG" "$ROOT_IMG"

  BOOT_MB=256
  truncate -s "${BOOT_MB}M" "$BOOT_IMG"
  mke2fs -t ext2 -F -q -L "pmOS_boot" -U "$BOOT_UUID" -d "$ROOTFS/boot" "$BOOT_IMG"

  USED_KB="$(du -sk "$ROOTFS" | awk "{print \$1}")"
  ROOT_MB=$(( (USED_KB / 1024) * 125 / 100 + 160 ))

  SAVED_BOOT="/tmp/saved-boot"
  rm -rf "$SAVED_BOOT"
  mv "$ROOTFS/boot" "$SAVED_BOOT"
  mkdir -p "$ROOTFS/boot"
  chown 0:0 "$ROOTFS/boot"
  chmod 755 "$ROOTFS/boot"

  truncate -s "${ROOT_MB}M" "$ROOT_IMG"
  mke2fs -t ext4 -O ^metadata_csum -F -q -L "pmOS_root" -i 8192 -U "$ROOT_UUID" -d "$ROOTFS" "$ROOT_IMG"

  rm -rf "$ROOTFS/boot"
  mv "$SAVED_BOOT" "$ROOTFS/boot"

  echo "[4/5] Assembling partitioned MBR raw image..."
  RAW_IMG="/images/bananarchy-$TARGET_DEVICE.img"
  TOTAL_MB=$(( 1 + BOOT_MB + ROOT_MB ))
  rm -f "$RAW_IMG" \
        "/images/bananarchy-$TARGET_DEVICE.sparse.img" \
        "/images/nokia-argon-sxmo.sparse.img" \
        "/images/nokia-argon-sxmo.img" \
        "/images/boot-bananarchy-$TARGET_DEVICE.img" \
        "/images/boot-nokia-argon-sxmo.img"
  truncate -s "${TOTAL_MB}M" "$RAW_IMG"

  BOOT_SECTORS=$(( BOOT_MB * 2048 ))
  ROOT_START_SECTOR=$(( 2048 + BOOT_SECTORS ))

  sfdisk --quiet "$RAW_IMG" <<SFEOF
label: dos
unit: sectors

start=2048, size=$BOOT_SECTORS, type=83, bootable
start=$ROOT_START_SECTOR, type=83
SFEOF

  dd if="$BOOT_IMG" of="$RAW_IMG" bs=1M seek=1 conv=notrunc,sparse status=none
  dd if="$ROOT_IMG" of="$RAW_IMG" bs=1M seek=$(( 1 + BOOT_MB )) conv=notrunc,sparse status=none
  rm -f "$BOOT_IMG" "$ROOT_IMG"

  echo "[5/5] Restoring host user ownership on $ROOTFS for easy host editing..."
  chown -R "$HOST_UID:$HOST_GID" "$ROOTFS" "/images"
  chmod -R u+rwX "$ROOTFS"

  echo "Built Bananarchy image for $TARGET_DEVICE:"
  ls -lh "$RAW_IMG"
'
