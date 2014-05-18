package steamer;

import steamer.Pulse;
import thx.Error;
import thx.Timer;
import thx.Tuple;

class Producer<T> {
	var handler : ProducerHandler<T>;
	var endOnError : Bool;
	public function new(handler : ProducerHandler<T>, endOnError = true) {
		this.endOnError = endOnError;
		this.handler = handler;
	}

	public function feed(consumer : Consumer<T>) : Void {
		var ended = false;
		function sendPulse(v : Pulse<T>) {
			switch(v) {
				case _ if(ended):
					throw new Error("Feed already reached end but still receiving pulses: ${v}");
				case Fail(_) if(endOnError):
					Timer.setImmediate(consumer.onPulse.bind(v));
					Timer.setImmediate(consumer.onPulse.bind(End));
				case End:
					ended = true;
					Timer.setImmediate(consumer.onPulse.bind(End));
				case _:
					Timer.setImmediate(consumer.onPulse.bind(v));
			}
		}
		handler(sendPulse);
	}

	public function map<TOut>(transform : T -> TOut) : Producer<TOut> {
		return mapAsync(function(v, t) t(transform(v)));
	}

	public function mapAsync<TOut>(transform : T -> (TOut -> Void) -> Void) : Producer<TOut> {
		return new Producer(function(forward : Pulse<TOut> -> Void) {
			this.feed(Bus.passOn(
				function(value : T) {
					try {
						function t(v : TOut) forward(Emit(v));
						transform(value, t);
					} catch(e : Error) {
						forward(Fail(e));
					} catch(e : Dynamic) {
						forward(Fail(new Error(Std.string(e))));
					}
				},
				forward
			));
		}, endOnError);
	}

	public function log(prefix : String, ?posInfo : haxe.PosInfos) {
		prefix = prefix == null ? '': '${prefix}: ';
		return map(function(v) {
			trace(v, posInfo);
			return v;
		});
	}

	public function filter(f : T -> Bool) : Producer<T> {
		return filterAsync(function(v, t) t(f(v)));
	}

	public function filterAsync(f : T -> (Bool -> Void) -> Void) : Producer<T> {
		return new Producer(function(forward : Pulse<T> -> Void) {
			this.feed(Bus.passOn(
				function(value : T) {
					try {
						function t(v : Bool) if(v) forward(Emit(value));
						f(value, t);
					} catch(e : Error) {
						forward(Fail(e));
					} catch(e : Dynamic) {
						forward(Fail(new Error(Std.string(e))));
					}
				},
				forward
			));
		}, endOnError);
	}

	public function merge(other : Producer<T>) : Producer<T> {
		var ended  = false;

		return new Producer(function(forward : Pulse<T> -> Void) {
			function emit(v) {
				forward(Emit(v));
			}
			function end() {
				if(ended)
					forward(End);
				else
					ended = true;
			}
			function fail(error) {
				forward(Fail(error));
			}

			this.feed(new Bus(emit, end, fail));
			other.feed(new Bus(emit, end, fail));
		}, endOnError);
	}

	public function zip<TOther>(other : Producer<TOther>) : Producer<Tuple<T, TOther>> {
		return new Producer(function(forward : Pulse<Tuple<T, TOther>> -> Void) {
			var ended = false,
				endA  = false,
				endB  = false,
				buffA : Array<T> = [],
				buffB : Array<TOther> = [];

			function produce() {
				if(((buffA.length == 0 && endA) || (buffB.length == 0 && endB)) && !ended) {
					buffA = null;
					buffB = null;
					ended = true;
					return forward(End);
				}
				if(buffA.length == 0 || buffB.length == 0) return;
				forward(Emit({
					left  : buffA.shift(),
					right : buffB.shift()
				}));
			}

			this.feed(new Bus(
				function(value : T) {
					if(ended) return;
					buffA.push(value);
					produce();
				},
				function() {
					endA = true;
					produce();
				},
				function(error) {
					forward(Fail(error));
				}
			));

			other.feed(new Bus(
				function(value : TOther) {
					if(ended) return;
					buffB.push(value);
					produce();
				},
				function() {
					endB = true;
					produce();
				},
				function(error) {
					forward(Fail(error));
				}
			));
		});
	}

	public function combine<TOther, TOut>(other : Producer<TOther>, f : T -> TOther -> TOut) : Producer<TOut> {
		return this.zip(other).map(function(tuple) {
			return f(tuple.left, tuple.right);
		});
	}

	// public function distinct() : Producer<T> // or unique
	// public function window(length : Int, fillBeforeEmit = false) : Producer<T> // or unique
	// public function reduce(acc : TOut, TOut -> T) : Producer<TOut>
	// public function debounce(delay : Int) : Producer<T>
	// exact pair
	// public function zip<TOther>(other : Producer<TOther>) : Producer<Tuple<T, TOther>> // or sync
	// public function pair<TOther>(other : Producer<TOther>) : Producer<Tuple<T, TOther>>


	public static function left<TLeft, TRight>(producer : Producer<Tuple<TLeft, TRight>>) : Producer<TLeft>
		return producer.map(function(v) return v.left);

	public static function right<TLeft, TRight>(producer : Producer<Tuple<TLeft, TRight>>) : Producer<TRight>
		return producer.map(function(v) return v.right);

	public static function negate(producer : Producer<Bool>)
		return producer.map(function(v) return !v);

	public static function flatMap<T>(producer : Producer<Array<T>>) : Producer<T> {
		return new Producer(function(forward : Pulse<T> -> Void) {
			producer.feed(Bus.passOn(
				function(arr : Array<T>) arr.map(function(value) forward(Emit(value))),
				forward
			));
		}, producer.endOnError);
	}

	public static function ofArray<T>(values : Array<T>) : Producer<T> {
		return new Producer(function(forward) {
			values.map(function(v) forward(Emit(v)));
			forward(End);
		});
	}
}

class Bus<T> {
	public static function passOn<TIn, TOut>(emit : TIn -> Void, forward : Pulse<TOut> -> Void) {
		return new Bus(
			emit,
			function() forward(End),
			function(error) forward(Fail(error))
		);
	}

	var emit : T -> Void;
	var end : Void -> Void;
	var fail : Error -> Void;
	public function new(emit : T -> Void, end : Void -> Void, fail : Error -> Void) {
		this.emit = emit;
		this.end = end;
		this.fail = fail;
	}

	public function onPulse(pulse : Pulse<T>) {
		switch (pulse) {
			case Emit(value):
				emit(value);
			case End:
				end();
			case Fail(error):
				fail(error);
		}
	}
}

typedef ProducerHandler<T> = (Pulse<T> -> Void) -> Void;