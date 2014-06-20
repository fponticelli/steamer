package steamer;

import thx.Error;
import steamer.Pulse;

class SimpleConsumer<T> {
	public var onEmit(default, null) : T -> Void;
	public var onEnd(default, null) : Void -> Void;
	public var onFail(default, null) : Error -> Void;
	public function new(?onEmit : T -> Void, ?onEnd : Void -> Void, ?onFail : Error -> Void) {
		this.onEmit  = null == onEmit  ? function(_) {} : onEmit;
		this.onEnd   = null == onEnd   ? function() {} : onEnd;
		this.onFail = null == onFail ? function(error : Error) throw error : onFail;
	}

	public function onPulse(pulse : Pulse<T>) {
		switch pulse {
			case Emit(value): onEmit(value);
			case End: onEnd;
			case Fail(error): onFail(error);
		}
	}
}