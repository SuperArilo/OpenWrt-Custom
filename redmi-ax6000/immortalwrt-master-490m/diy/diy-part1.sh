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

# honk/daed 依赖 eBPF 工具链，但它只有 build 依赖 bpf-headers、没有 select
# NEED_BPF_TOOLCHAIN，Kconfig 推不出要用 LLVM，bpf.mk 会拿到 /invalid/clang 报错。
# 给两个隐藏符号补默认值。官方 master 符号名若有变化则跳过，不报错退出。
KCONF=toolchain/Config.in
[ -f "$KCONF" ] || { echo "WARN: $KCONF 不存在，跳过 BPF 工具链补默认值"; exit 0; }

if grep -q '^config NEED_BPF_TOOLCHAIN$' "$KCONF"; then
  sed -i '/^config NEED_BPF_TOOLCHAIN$/,/^\tbool$/ s/^\tbool$/\tbool\n\tdefault y/' "$KCONF"
  echo "NEED_BPF_TOOLCHAIN 已补 default y"
else
  echo "NEED_BPF_TOOLCHAIN 不存在，跳过"
fi

if grep -q '^config USE_LLVM_BUILD$' "$KCONF"; then
  sed -i '/^config USE_LLVM_BUILD$/,/^\tdefault y if .*/ s/^\tdefault y if .*$/\tdefault y/' "$KCONF"
  echo "USE_LLVM_BUILD 已补 default y"
else
  echo "USE_LLVM_BUILD 不存在，跳过"
fi
