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

sed -i 's/192.168.1.1/172.16.1.1/g' package/base-files/files/bin/config_generate   # 定制默认IP
sed -i 's/ImmortalWrt/Bocchi/g' package/base-files/files/bin/config_generate   # 定制默认主机名字
sed -i 's/  luci-app-quickstart / /g' target/linux/mediatek/Makefile  #移除默认quickstart
# 移除重复软件包
# rm -rf feeds/luci/themes/luci-theme-argon
# wget https://github.com/linkease/istore/raw/main/luci/luci-app-store/src/key-build.pub -O package/istore/luci-app-store/luci/luci-app-store/src/key-build.pub
# 修改 argon 为默认主题,可根据你喜欢的修改成其他的（不选择那些会自动改变为默认主题的主题才有效果）
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile
