#!/usr/bin/env bash
# 安装签名 APK 需要的 Android build-tools。platform-tools 由 setup-android 提供。

set -euo pipefail

if ! command -v sdkmanager >/dev/null 2>&1; then
	echo "找不到 sdkmanager。请先运行 android-actions/setup-android。" >&2
	exit 1
fi

if ! sdkmanager --install "build-tools;36.1.0"; then
	echo "build-tools 36.1.0 不可用，改试 35.0.0"
	sdkmanager --install "build-tools;35.0.0"
fi
