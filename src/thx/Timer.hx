package thx;

class Timer {
	public static function setInterval(callback : Void -> Void, delay : Int) : TimerID
		return untyped __js__('setInterval')(callback, delay);

	public static function setTimeout(callback : Void -> Void, delay : Int) : TimerID
		return untyped __js__('setTimeout')(callback, delay);

	public static function setImmediate(callback : Void -> Void) : TimerID
		return untyped __js__('setTimeout')(callback, 0);

	public static function clearTimer(id : TimerID) : Void
		return untyped __js__('clearTimeout')(id);
}

extern
class TimerID {}