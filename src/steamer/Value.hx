package steamer;

import steamer.Consumer;
import steamer.Producer;

class Value<T> extends Producer<T> {
	public static function string(value = "", ?defaultValue)
		return new Value(value, defaultValue);

	public static function number(value = 0.0, ?defaultValue)
		return new Value(value, defaultValue);

	public static function bool(value = false, ?defaultValue)
		return new Value(value, defaultValue);

	@:isVar public var value(get, set) : T;

	public var defaultValue(default, null) : T;
	var forwards : Array<Pulse<T> -> Void>;

	public function new(initialValue : T, ?defaultValue : T) {
		forwards = [];
		super(function(forward) {
			this.forwards.push(forward);
		}, false);
		this.defaultValue = null == defaultValue ? initialValue : defaultValue;
		this.value = initialValue;
	}

	function forward(pulse : Pulse<T>) {
		for(f in forwards)
			f(pulse);
		switch pulse {
			case End: forwards = [];
			case _:
		}
	}

	function get_value() : T
		return value;

	function set_value(v : T) : T {
		if(v == value)
			return v;
		value = v;
		forward(Emit(v));
		return v;
	}

	override function feed(consumer : Consumer<T>) {
		super.feed(consumer);
		consumer.toImplementation().onPulse(Emit(value));
		return this;
	}

	public function end() {
		forward(End);
	}

	public function onPulse(pulse : Pulse<T>) {
		switch pulse {
			case Emit(v): value = v;
			case Fail(e): forward(Fail(e));
			case End:     forward(End);
		}
	}

	public function reset() {
		this.value = defaultValue;
	}

	public function isDefault() {
		return this.value = defaultValue;
	}
}