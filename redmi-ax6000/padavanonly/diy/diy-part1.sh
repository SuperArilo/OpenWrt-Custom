#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#

# Uncomment a feed source
#sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default

# Add a feed source
## 修改DTS的ubi为490MB的0x1ea00000
#sed -i 's/reg = <0x600000 0x6e00000>/reg = <0x600000 0x1ea00000>/' target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek/mt7986a-xiaomi-redmi-router-ax6000.dts
#git clone https://github.com/sbwml/luci-app-mosdns -b v5 package/luci-app-mosdns
#git clone https://github.com/vernesong/OpenClash package/luci-app-openclash
#git clone https://github.com/kongfl888/luci-app-adguardhome package/luci-app-adguardhome
#git clone https://github.com/sirpdboy/luci-app-ddns-go.git package/ddns-go
