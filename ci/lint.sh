#!/usr/bin/env bash
# 检查 GDScript 格式和静态规则。只覆盖本仓库自己的脚本，不检查第三方 addons/gut。

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

gdformat --check scripts tests
gdlint scripts tests
