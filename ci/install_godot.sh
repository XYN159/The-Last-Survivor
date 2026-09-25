#!/usr/bin/env bash
# 按 godot-version.txt 安装官方 Linux 版 Godot。需要导出模板时设置 INSTALL_EXPORT_TEMPLATES=1。

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(tr -d '[:space:]' < "${ROOT}/godot-version.txt")"
PREFIX="${GODOT_INSTALL_DIR:-${HOME}/.local/share/godot-ci}"
BIN_DIR="${PREFIX}/bin"
TEMPLATE_DIR="${HOME}/.local/share/godot/export_templates/${VERSION}.stable"
GODOT_BIN="${BIN_DIR}/godot"

mkdir -p "${BIN_DIR}"

if [[ ! -x "${GODOT_BIN}" ]]; then
	tmp="$(mktemp -d)"
	url="https://github.com/godotengine/godot/releases/download/${VERSION}-stable/Godot_v${VERSION}-stable_linux.x86_64.zip"
	echo "下载 Godot ${VERSION}"
	curl -fsSL -o "${tmp}/godot.zip" "${url}"
	unzip -q "${tmp}/godot.zip" -d "${tmp}"
	install -m 0755 "${tmp}/Godot_v${VERSION}-stable_linux.x86_64" "${GODOT_BIN}"
	rm -rf "${tmp}"
fi

if [[ "${INSTALL_EXPORT_TEMPLATES:-0}" == "1" && ! -f "${TEMPLATE_DIR}/android_debug.apk" ]]; then
	tmp="$(mktemp -d)"
	url="https://github.com/godotengine/godot/releases/download/${VERSION}-stable/Godot_v${VERSION}-stable_export_templates.tpz"
	echo "下载 Godot ${VERSION} 导出模板"
	curl -fsSL -o "${tmp}/templates.tpz" "${url}"
	unzip -q "${tmp}/templates.tpz" -d "${tmp}"
	mkdir -p "${TEMPLATE_DIR}"
	if [[ -d "${tmp}/templates" ]]; then
		cp -a "${tmp}/templates/." "${TEMPLATE_DIR}/"
	else
		cp -a "${tmp}/." "${TEMPLATE_DIR}/"
	fi
	rm -rf "${tmp}"
fi

if [[ -n "${GITHUB_PATH:-}" ]]; then
	echo "${BIN_DIR}" >> "${GITHUB_PATH}"
fi

export PATH="${BIN_DIR}:${PATH}"
echo "Godot 已就绪：$(${GODOT_BIN} --version)"
