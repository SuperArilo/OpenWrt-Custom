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

# Vantage 主题 feed（ImmortalWrt 自带 luci feeds 里没有）
echo 'src-git vantage https://github.com/anothaDev/luci-theme-vantage.git' >> feeds.conf.default

# daed 依赖 eBPF 工具链，但它只有 build 依赖 bpf-headers、没有 select NEED_BPF_TOOLCHAIN，
# Kconfig 推不出要用 LLVM，bpf.mk 会拿到 /invalid/clang 报错。给两个隐藏符号补默认值。
KCONF=toolchain/Config.in
sed -i '/^config NEED_BPF_TOOLCHAIN$/,/^\tbool$/ s/^\tbool$/\tbool\n\tdefault y/' "$KCONF"
sed -i '/^config USE_LLVM_BUILD$/,/^\tdefault y if .*/ s/^\tdefault y if .*$/\tdefault y/' "$KCONF"
grep -q -A2 'config NEED_BPF_TOOLCHAIN' "$KCONF" || { echo "NEED_BPF_TOOLCHAIN 补丁失败"; exit 1; }
