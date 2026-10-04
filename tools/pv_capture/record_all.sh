#!/usr/bin/env bash
# 把宣传 PV 的实机片段录成 PNG 序列，再转成 60fps 的 H.264 mp4。
# 视频写到 PV_ARTIFACT_DIR（默认 /opt/cursor/artifacts/pv），不要提交进仓库。

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GODOT="${GODOT_BIN:-${HOME}/.local/share/godot-ci/bin/godot}"
ARTIFACT_DIR="${PV_ARTIFACT_DIR:-/opt/cursor/artifacts/pv}"
WORK_DIR="${PV_WORK_DIR:-/tmp/pv_capture}"
DRIVER="${PV_RENDER_DRIVER:-opengl3}"
OVERRIDE="${ROOT}/override.cfg"

export LIBGL_ALWAYS_SOFTWARE=1
export GALLIUM_DRIVER=llvmpipe

if [[ ! -x "${GODOT}" ]]; then
	echo "找不到 Godot：${GODOT}。先跑 ci/install_godot.sh" >&2
	exit 1
fi

mkdir -p "${ARTIFACT_DIR}"

write_display_override() {
	local width="$1"
	local height="$2"
	# project.godot 把窗口盖成 1280×720。--resolution 盖不住它，电影就录成 720p。
	# 这里只在录制当次写 override.cfg，退出时删掉，不提交。
	cat > "${OVERRIDE}" << EOF
; 录制临时文件。tools/pv_capture/record_all.sh 退出时会删掉。
[display]

window/size/window_width_override=${width}
window/size/window_height_override=${height}
EOF
}

remove_display_override() {
	rm -f "${OVERRIDE}"
}

encode_frames() {
	local name="$1"
	local dir="$2"
	local width="$3"
	local height="$4"
	local mp4="${ARTIFACT_DIR}/${name}.mp4"
	mapfile -t frames < <(find "${dir}" -name 'frame*.png' | sort)
	if [[ ${#frames[@]} -eq 0 ]]; then
		echo "没有帧：${dir}" >&2
		return 1
	fi
	local base digits start
	base="$(basename "${frames[0]}" .png)"
	digits="${base#frame}"
	start=$((10#${digits}))
	echo "转码 ${name}：${#frames[@]} 帧，起始编号 ${start}"
	ffmpeg -y -hide_banner -loglevel error \
		-framerate 60 -start_number "${start}" -i "${dir}/frame%08d.png" \
		-c:v libx264 -preset slow -crf 12 -pix_fmt yuv420p \
		-movflags +faststart "${mp4}"
	ffprobe -v error -show_entries format=duration:stream=width,height,avg_frame_rate,codec_name \
		-of default=nw=1 "${mp4}"
	local actual
	actual="$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0:s=x "${mp4}")"
	if [[ "${actual}" != "${width}x${height}" ]]; then
		echo "分辨率不对：期望 ${width}x${height}，实际 ${actual}" >&2
		return 1
	fi
}

record_segment() {
	local name="$1"
	local width="$2"
	local height="$3"
	local dir="${WORK_DIR}/${name}"
	rm -rf "${dir}"
	mkdir -p "${dir}"
	local timeline="${ARTIFACT_DIR}/${name}_timeline.txt"
	echo "录制 ${name} ${width}x${height} driver=${DRIVER}"
	write_display_override "${width}" "${height}"
	PV_SEGMENT="${name}" PV_TIMELINE="${timeline}" \
		xvfb-run -a -s "-screen 0 ${width}x${height}x24" \
		"${GODOT}" --path "${ROOT}" \
		--rendering-driver "${DRIVER}" \
		--rendering-method gl_compatibility \
		--audio-driver Dummy \
		--resolution "${width}x${height}" \
		--fixed-fps 60 \
		--write-movie "${dir}/frame.png" \
		-s res://tools/pv_capture/pv_demo.gd
	encode_frames "${name}" "${dir}" "${width}" "${height}"
	rm -rf "${dir}"
}

run_probe() {
	echo "试跑灵力时间线（无画面）"
	PV_SEGMENT=probe "${GODOT}" --path "${ROOT}" --headless \
		--audio-driver Dummy \
		-s res://tools/pv_capture/pv_demo.gd
}

usage() {
	echo "用法：tools/pv_capture/record_all.sh [probe|test|all|R1|R2|R3|R4a|R4b|R5|R6x1|R6x2|R7|R8|R9place|R9upgrade]" >&2
}

trap remove_display_override EXIT
cd "${ROOT}"

target="${1:-all}"
case "${target}" in
	probe)
		run_probe
		;;
	test)
		record_segment test 1920 1080
		;;
	R1 | R2 | R3 | R4a | R4b | R5 | R6x1 | R6x2 | R7 | R8)
		record_segment "${target}" 1920 1080
		;;
	R9place | R9upgrade)
		record_segment "${target}" 2560 1440
		;;
	all)
		record_segment R1 1920 1080
		record_segment R2 1920 1080
		record_segment R3 1920 1080
		record_segment R4a 1920 1080
		record_segment R4b 1920 1080
		record_segment R5 1920 1080
		record_segment R6x2 1920 1080
		record_segment R6x1 1920 1080
		record_segment R7 1920 1080
		record_segment R8 1920 1080
		record_segment R9place 2560 1440
		record_segment R9upgrade 2560 1440
		;;
	*)
		usage
		exit 1
		;;
esac
