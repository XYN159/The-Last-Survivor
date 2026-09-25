#!/usr/bin/env bash
# 无界面导入工程、跑 GUT，再让标题场景实际启动几帧。

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

if ! command -v godot >/dev/null 2>&1; then
	# shellcheck disable=SC1091
	source "${ROOT}/ci/install_godot.sh"
fi

echo "导入工程资源"
godot --headless --path "${ROOT}" --import
echo "运行单元测试"
godot --headless --path "${ROOT}" -s addons/gut/gut_cmdln.gd -gexit
echo "启动标题场景"
godot --headless --path "${ROOT}" --quit-after 8
echo "测试通过"
