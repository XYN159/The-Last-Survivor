class_name MotionEase
extends RefCounted

## 动效用的缓动曲线。都是纯函数，输入 0~1 的进度，方便测试直接算。


static func clamp01(value: float) -> float:
	return clampf(value, 0.0, 1.0)


static func ratio(elapsed: float, duration: float) -> float:
	if duration <= 0.0:
		return 1.0
	return clamp01(elapsed / duration)


static func out_cubic(t: float) -> float:
	var inv := 1.0 - clamp01(t)
	return 1.0 - inv * inv * inv


static func in_quad(t: float) -> float:
	var x := clamp01(t)
	return x * x


## 先冲过终点再回落，用来做回弹。overshoot 越大冲得越远。
static func out_back(t: float, overshoot: float) -> float:
	var x := clamp01(t) - 1.0
	return 1.0 + (overshoot + 1.0) * x * x * x + overshoot * x * x
