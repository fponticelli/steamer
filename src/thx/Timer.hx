package thx;

class Timer {
	public inline static function setInterval(callback : Void -> Void, delay : Int) : TimerID
		return untyped __js__('setInterval')(callback, delay);

	public inline static function setTimeout(callback : Void -> Void, delay : Int) : TimerID
		return untyped __js__('setTimeout')(callback, delay);

	public inline static function setImmediate(callback : Void -> Void) : TimerID
		return untyped __js__('setImmediate')(callback);

	public inline static function clearTimer(id : TimerID) : Void
		return untyped __js__('clearTimeout')(id);

	static function __init__() untyped {
		var scope : Dynamic = (window || __js__('this'));
		if(!scope.setImmediate)
			scope.setImmediate = function(callback) scope.setTimeout(callback, 0);
	}
}

extern
class TimerID {}

/*
let immediate = require('immediate'),
	Timer = {
	delay(ms, ƒ) {
		if(ƒ)
			return setTimeout(ƒ, ms);
		else
			return new Promise((resolve) => setTimeout(resolve, ms));
	},
	immediate(ƒ) {
		if(ƒ)
			return immediate(ƒ);
		else
			return new Promise((resolve) => immediate(resolve));
	},
	debounce(ƒ, ms = 0) {
		let tid, context, args, laterƒ;
		return function() {
			context = this;
			args = arguments;
			laterƒ = function() {
				if (!immediate) ƒ.apply(context, args);
			};
			clearTimeout(tid);
			tid = setTimeout(laterƒ, ms);
		};
	},
	reduce(ƒ, ms = 0) {
		let tid, context, args;
		return function() {
			context = this;
			args = arguments;
			if(tid) return;
			tid = setTimeout(function() {
				tid = null;
				ƒ.apply(context, args);
			}, ms);
		};
	}
};

export default Timer;
*/