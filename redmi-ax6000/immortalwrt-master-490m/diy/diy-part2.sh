#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

VARIANT_DIR="${GITHUB_WORKSPACE:-..}/redmi-ax6000/immortalwrt-master-490m"

# ============ 490m 大分区机型注入 ============
# 官方 master 只有 stock 与 ubootmod 两个 AX6000 机型，没有 490m 机型；
# 490m 布局 = 单个 490m ubi 分区，对应 hanwckf uboot 的 immortalwrt-490m 布局。
cp "$VARIANT_DIR/device/mt7986a-xiaomi-redmi-router-ax6000-490m.dts" target/linux/mediatek/dts/ || { echo "490m DTS 注入失败"; exit 1; }
cat "$VARIANT_DIR/device/filogic-490m-device.mk" >> target/linux/mediatek/image/filogic.mk || { echo "490m 机型定义注入失败"; exit 1; }
grep -q "xiaomi_redmi-router-ax6000-490m" target/linux/mediatek/image/filogic.mk || { echo "490m 机型定义未写入 filogic.mk"; exit 1; }
[ -f "target/linux/mediatek/dts/mt7986a-xiaomi-redmi-router-ax6000-490m.dts" ] || { echo "490m DTS 未就位"; exit 1; }
echo "490m 机型注入完成"

# ============ board.d / platform.sh 补 490m 识别（开源 master 特有）============
# 官方 board.d 只认 stock/ubootmod，新 compatible 必须蹭 stock 逻辑，否则灯/网络/升级校验异常。
for f in target/linux/mediatek/filogic/base-files/etc/board.d/01_leds target/linux/mediatek/filogic/base-files/etc/board.d/02_network; do
  if [ -f "$f" ] && ! grep -q "redmi-router-ax6000-490m" "$f"; then
    sed -i 's/xiaomi,redmi-router-ax6000-stock/xiaomi,redmi-router-ax6000-stock|\\\n\txiaomi,redmi-router-ax6000-490m/' "$f"
    echo "已补 $f"
  fi
done
if [ -f target/linux/mediatek/filogic/base-files/lib/upgrade/platform.sh ]; then
  if ! grep -q "redmi-router-ax6000-490m" target/linux/mediatek/filogic/base-files/lib/upgrade/platform.sh; then
    sed -i 's/xiaomi,redmi-router-ax6000-stock)/xiaomi,redmi-router-ax6000-stock|xiaomi,redmi-router-ax6000-490m)/g' target/linux/mediatek/filogic/base-files/lib/upgrade/platform.sh
    echo "已补 platform.sh"
  fi
fi

# ============ 默认网关、主机名、时区 ============
sed -i 's/192.168.1.1/172.16.1.1/g' package/base-files/files/bin/config_generate
sed -i 's/OpenWrt/Miku/g; s/ImmortalWrt/Miku/g' package/base-files/files/bin/config_generate
sed -i "s/timezone='GMT0'/timezone='CST-8'/; s/timezone='UTC'/timezone='CST-8'/" package/base-files/files/bin/config_generate

# ============ apk 软件源预置南大镜像（刷完默认南大源）============

cat > package/base-files/files/etc/apk/repositories << "EOF"
https://mirrors.nju.edu.cn/immortalwrt/snapshots/targets/mediatek/filogic/packages
https://mirrors.nju.edu.cn/immortalwrt/snapshots/packages/aarch64_cortex-a53/base
https://mirrors.nju.edu.cn/immortalwrt/snapshots/packages/aarch64_cortex-a53/luci
https://mirrors.nju.edu.cn/immortalwrt/snapshots/packages/aarch64_cortex-a53/packages
EOF
echo "apk 南大源已预置"


# ============ IPv6 邻居清理 hotplug ============
mkdir -p package/base-files/files/etc/hotplug.d/iface
cat << "EOF" > package/base-files/files/etc/hotplug.d/iface/30-ipv6-event
#!/bin/sh
# IPv6 邻居清理：接口 up 后清掉 STALE/FAILED 的邻居表项，避免运营商换前缀后残留黑洞

[ "$ACTION" = ifup -o "$ACTION" = ifupdate ] || exit 0

logger -t "ipv6-clean" "=== Starting IPv6 neighbor cleanup ==="
ip -6 neigh show | awk '/STALE|FAILED/ {print $1,$3}' | while read -r ip dev; do
    logger -t "ipv6-clean" "Deleting neighbor: IP=$ip, Device=$dev"
    ip -6 neigh del "$ip" dev "$dev"
done
EOF
chmod +x package/base-files/files/etc/hotplug.d/iface/30-ipv6-event

