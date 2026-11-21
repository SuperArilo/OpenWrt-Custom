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

VARIANT_DIR="${GITHUB_WORKSPACE:-..}/redmi-ax6000/chasey-25.12-490m"

# ============ 490m 大分区机型注入 ============
# rebase 上游只有 stock 与 ubootmod 两个 AX6000 机型，没有 490m 机型；
# 490m 布局 = 单个 490m ubi 分区，对应 hanwckf uboot 的 immortalwrt-490m 布局。
cp "$VARIANT_DIR/device/mt7986a-xiaomi-redmi-router-ax6000-490m.dts" target/linux/mediatek/dts/ || { echo "490m DTS 注入失败"; exit 1; }
cat "$VARIANT_DIR/device/filogic-490m-device.mk" >> target/linux/mediatek/image/filogic.mk || { echo "490m 机型定义注入失败"; exit 1; }
grep -q "xiaomi_redmi-router-ax6000-490m" target/linux/mediatek/image/filogic.mk || { echo "490m 机型定义未写入 filogic.mk"; exit 1; }
[ -f "target/linux/mediatek/dts/mt7986a-xiaomi-redmi-router-ax6000-490m.dts" ] || { echo "490m DTS 未就位"; exit 1; }
echo "490m 机型注入完成"

# ============ 默认网关、主机名 ============
sed -i 's/192.168.1.1/172.16.1.1/g' package/base-files/files/bin/config_generate
sed -i 's/OpenWrt/RedMi-AX6000/g' package/base-files/files/bin/config_generate

# ============ firewall4 FullCone 补丁（新版才替换）============
if grep -q "^PKG_SOURCE_DATE:=2026-11-08" package/network/config/firewall4/Makefile 2>/dev/null; then
  cp "${GITHUB_WORKSPACE:-..}/patches/001-firewall4-add-support-for-fullcone-nat.patch" \
     package/network/config/firewall4/patches/001-firewall4-add-support-for-fullcone-nat.patch
  echo "已替换 firewall4 FullCone 补丁为适配新版（2026-11-08）的版本"
fi

# ============ MTK 两个全局 sysctl 改 per-net（消 daed/unshare 的 register_net_sysctl_sz WARNING）============
mkdir -p target/linux/mediatek/patches-6.12
cp "${GITHUB_WORKSPACE:-..}/patches/999-ppe-54-netfilter-fix-per-net-nf_conntrack_qos-sysctl.patch" \
   target/linux/mediatek/patches-6.12/999-ppe-54-netfilter-fix-per-net-nf_conntrack_qos-sysctl.patch
# 613 是 chasey 自带的全局变量版 tcp_no_window_check，614 排在它后面改成 per-netns
cp "${GITHUB_WORKSPACE:-..}/patches/614-netfilter-tcp-no-window-check-per-netns.patch" \
   target/linux/mediatek/patches-6.12/614-netfilter-tcp-no-window-check-per-netns.patch
echo "已注入 nf_conntrack_qos / tcp_no_window_check 两个 per-net 补丁"

# ============ IPv6 邻居清理 hotplug ============
mkdir -p package/base-files/files/etc/hotplug.d/iface
cat << "EOF" > package/base-files/etc/hotplug.d/iface/30-ipv6-event
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
