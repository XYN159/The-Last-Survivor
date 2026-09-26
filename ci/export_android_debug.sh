#!/usr/bin/env bash
# 用临时 debug keystore 导出 Android 调试 APK。证书只存在于本次运行，不进仓库。

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APK_PATH="${1:-${ROOT}/build/android/the-last-survivor-debug.apk}"
SDK_PATH="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
JAVA_PATH="${JAVA_HOME:-}"
KEYSTORE_PATH="${RUNNER_TEMP:-/tmp}/the-last-survivor-debug.keystore"

if [[ -z "${SDK_PATH}" || -z "${JAVA_PATH}" ]]; then
	echo "需要 ANDROID_HOME（或 ANDROID_SDK_ROOT）以及 JAVA_HOME。" >&2
	exit 1
fi

INSTALL_EXPORT_TEMPLATES=1
# shellcheck disable=SC1091
source "${ROOT}/ci/install_godot.sh"

echo "生成临时调试证书"
rm -f "${KEYSTORE_PATH}"
keytool -genkeypair -keystore "${KEYSTORE_PATH}" \
	-storepass android \
	-alias androiddebugkey \
	-keypass android \
	-keyalg RSA \
	-keysize 2048 \
	-validity 10000 \
	-dname "CN=Android Debug,O=Android,C=US"

export GODOT_ANDROID_KEYSTORE_DEBUG_PATH="${KEYSTORE_PATH}"
export GODOT_ANDROID_KEYSTORE_DEBUG_USER="androiddebugkey"
export GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD="android"

echo "导入工程资源"
godot --headless --path "${ROOT}" --import

# Godot 4.7 把编辑器设置写在 editor_settings-4.7.tres。导入之后再改 Android 路径，避免覆盖整份设置。
python3 - "${HOME}/.config/godot" "${SDK_PATH}" "${JAVA_PATH}" "${KEYSTORE_PATH}" <<'PY'
import sys
from pathlib import Path

config_dir = Path(sys.argv[1])
sdk_path, java_path, keystore_path = sys.argv[2:]
updates = {
    "export/android/android_sdk_path": f'"{sdk_path}"',
    "export/android/java_sdk_path": f'"{java_path}"',
    "export/android/debug_keystore": f'"{keystore_path}"',
    "export/android/debug_keystore_user": '"androiddebugkey"',
    "export/android/debug_keystore_pass": '"android"',
}
files = sorted(config_dir.glob("editor_settings-*.tres"))
if not files:
    raise SystemExit(f"没有找到编辑器设置：{config_dir}")
for settings_file in files:
    lines = settings_file.read_text(encoding="utf-8").splitlines()
    seen = set()
    rewritten = []
    for line in lines:
        key = line.split("=", 1)[0].strip() if "=" in line else ""
        if key in updates:
            rewritten.append(f"{key} = {updates[key]}")
            seen.add(key)
        else:
            rewritten.append(line)
    missing = [f"{key} = {value}" for key, value in updates.items() if key not in seen]
    if missing and rewritten:
        rewritten.extend(missing)
    settings_file.write_text("\n".join(rewritten) + "\n", encoding="utf-8")
    print(f"已写入 Android 导出设置：{settings_file}")
PY

mkdir -p "$(dirname "${APK_PATH}")"
echo "导出调试 APK 到 ${APK_PATH}"
godot --headless --path "${ROOT}" --verbose --export-debug "Android" "${APK_PATH}"

if [[ ! -f "${APK_PATH}" ]]; then
	echo "导出结束但没有找到 APK。" >&2
	exit 1
fi

size="$(stat -c%s "${APK_PATH}")"
if (( size < 1000000 )); then
	echo "APK 只有 ${size} 字节，导出结果不可用。" >&2
	exit 1
fi

unzip -t "${APK_PATH}" > /dev/null
echo "APK 已生成，大小 ${size} 字节"
