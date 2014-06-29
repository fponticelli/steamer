package steamer;

import thx.Error;
import steamer.Pulse;

typedef ConsumerType<T> = {
	function onPulse(pulse : Pulse<T>) : Void;
}

abstract Consumer<T>(ConsumerType<T>) {
	public inline function new(consumer : ConsumerType<T>)
		this = consumer;

	@:from public inline static function fromConsumer(consumer : ConsumerType<T>) : Consumer<T>
		return new Consumer(consumer);

	@:from public inline static function fromFunction(f : T -> Void) : Consumer<T>
		return new Consumer({
			onPulse : function(pulse) {
				switch pulse {
					case Emit(v): f(v);
					case _:
				}
			}
		});

	@:from public static function fromObject<T>(o : { ?emit : T -> Void, ?end : Void -> Void, ?error : Error -> Void }) : Consumer<T> {
		if(null == o.emit) o.emit = function(_) {};
		if(null == o.end) o.end = function() {};
		if(null == o.error) o.error = function(e) { throw e; };
		return new Consumer({
			onPulse : function(pulse) {
				switch pulse {
					case Emit(v): o.emit(v);
					case End: o.end();
					case Fail(e): o.error(e);
				}
			}
		});
	}

	@:to public inline function toImplementation() : ConsumerType<T>
		return this;
}