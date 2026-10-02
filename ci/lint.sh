#!/usr/bin/env bash
# 检查 GDScript 格式和静态规则，并检查 ci/ 里 shell 脚本的语法。
# 不检查第三方 addons/gut。

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

gdformat --check scripts tests
gdlint scripts tests

# 改名时曾把 ${...} 的结尾括号弄丢，脚本要等到导出步骤才报错。这里先做语法检查。
for script in ci/*.sh; do
	bash -n "${script}"
done
