package steamer;

import steamer.producers.Interval;
import steamer.Pulse;
import thx.Error;
import thx.Nil;
import thx.Timer;
import thx.Tuple;
import haxe.ds.Option;

class Producer<T> {
	var handler : ProducerHandler<T>;
	var endOnError : Bool;
	public function new(handler : ProducerHandler<T>, endOnError = true) {
		this.handler = handler;
		this.endOnError = endOnError;
	}

	public function feed(consumer : Consumer<T>) : Producer<T> {
		var ended = false;
		function sendPulse(v : Pulse<T>) {
			switch(v) {
				case _ if(ended):
					throw new Error("Feed already reached end but still receiving pulses: ${v}");
				case Fail(_) if(endOnError):
					Timer.setImmediate(consumer.toImplementation().onPulse.bind(v));
					Timer.setImmediate(consumer.toImplementation().onPulse.bind(End));
				case End:
					ended = true;
					Timer.setImmediate(consumer.toImplementation().onPulse.bind(End));
				case _:
					Timer.setImmediate(consumer.toImplementation().onPulse.bind(v));
			}
		}
		handler(sendPulse);
		return this;
	}

	public function toOption() : Producer<Option<T>> {
		return map(function(v) return null == v ? None : Some(v));
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

	public function toNil() : Producer<Nil> {
		return map(function(_) return nil);
	}

	public function toTrue() : Producer<Bool> {
		return map(function(_) return true);
	}

	public function toFalse() : Producer<Bool> {
		return map(function(_) return false);
	}

	public function log(?prefix : String, ?posInfo : haxe.PosInfos) {
		prefix = prefix == null ? '': '${prefix}: ';
		return map(function(v) {
			haxe.Log.trace('$prefix$v', posInfo);
			return v;
		});
	}

	public function filterMap<TOut>(transform : T -> Option<TOut>) : Producer<TOut>
		return filterMapAsync(function(v, t) t(transform(v)));

	public function filterMapAsync<TOut>(transform : T -> (Option<TOut> -> Void) -> Void) : Producer<TOut>
		return Producer.filterOption(mapAsync(transform));

	public function filter(f : T -> Bool) : Producer<T>
		return filterAsync(function(v, t) t(f(v)));

	public function filterValue(value : T) : Producer<T>
		return filterAsync(function(v, t) t(v == value));

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

	public function concat(other : Producer<T>) : Producer<T> {
		return new Producer(function(forward : Pulse<T> -> Void) {
			function emit(v) {
				forward(Emit(v));
			}
			function fail(error) {
				forward(Fail(error));
			}

			this.feed(new Bus(
				emit,
				function() other.feed(Bus.passOn(emit, forward)),
				fail
			));
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
		}, endOnError);
	}

	public function blend<TOther, TOut>(other : Producer<TOther>, f : T -> TOther -> TOut) : Producer<TOut> {
		return this.zip(other).map(function(tuple) {
			return f(tuple.left, tuple.right);
		});
	}

	public function pair<TOther>(other : Producer<TOther>) : Producer<Tuple<T, TOther>> {
		return new Producer(function(forward : Pulse<Tuple<T, TOther>> -> Void) {
			var endA  = false,
				endB  = false,
				buffA : T = null,
				buffB : TOther = null;

			function produce() {
				if(endA && endB) {
					buffA = null;
					buffB = null;
					return forward(End);
				}
				if(buffA == null || buffB == null) return;
				forward(Emit({
					left  : buffA,
					right : buffB
				}));
			}

			this.feed(new Bus(
				function(value : T) {
					buffA = value;
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
					buffB = value;
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

		}, endOnError);
	}

	public function distinct(?equals : T -> T -> Bool) : Producer<T> {
		var last : T = null;
		if(null == equals)
			equals = function(a, b) return a == b;
		return new Producer(function(forward) {
			this.feed(Bus.passOn(
				function(v) {
					if(equals(v, last)) return;
					last = v;
					forward(Emit(v));
				},
				forward
			));
		}, endOnError);
	}

	public  function debounce(delay : Int) : Producer<T> {
		var id : TimerID = null;
		return new Producer(function(forward) {
			this.feed(Bus.passOn(
				function(v : T) {
					Timer.clearTimer(id);
					id = Timer.setTimeout(forward.bind(Emit(v)), delay);
				},
				forward
			));
		}, endOnError);
	}

	public function sampleBy<TSampler>(sampler : Producer<TSampler>) : Producer<Tuple<T, TSampler>> {
		return new Producer(function(forward) {
			var latest : T = null;
			this.feed(Bus.passOn(
				function(v) latest = v,
				forward
			));
			sampler.feed(Bus.passOn(
				function(v) {
					// skip if this hasn't produced anything yet or has been cleared
					if(null == latest) return;
					forward(Emit({ left : latest, right : v }));
					latest = null;
				},
				forward
			));
		}, endOnError);
	}

	public function keep(n : Int) : Producer<Array<T>> {
		return new Producer(function(forward) {
			var acc = [];
			this.feed(Bus.passOn(
				function(v) {
					acc.push(v);
					if(acc.length > n)
						acc.shift();
					forward(Emit(acc));
				},
				forward
			));
		}, endOnError);
	}

	public function previous() : Producer<T> {
		return new Producer(function(forward) {
			var isFirst   = true,
				state : T = null;
			this.feed(Bus.passOn(
				function(v) {
					if(isFirst) {
						isFirst = false;
					} else {
						forward(Emit(state));
					}
					state = v;
				},
				forward
			));
		}, endOnError);
	}

	// public function window(length : Int, fillBeforeEmit = false) : Producer<T> // or unique
	// public function reduce(acc : TOut, TOut -> T) : Producer<TOut>
	// public function debounce(delay : Int) : Producer<T>
	// exact pair
	// public function zip<TOther>(other : Producer<TOther>) : Producer<Tuple<T, TOther>> // or sync

	public static function filterOption<T>(producer : Producer<Option<T>>) : Producer<T>
		return producer
			.filter(function(opt) return switch opt { case Some(_): true; case None: false; })
			.map(function(opt) return switch opt { case Some(v) : v; case None: throw 'filterOption failed'; });

	public static function toValue<T>(producer : Producer<Option<T>>) : Producer<Null<T>>
		return producer
			.map(function(opt) return switch opt { case Some(v) : v; case None: null; });

	public static function toBool<T>(producer : Producer<Option<T>>) : Producer<Bool>
		return producer
			.map(function(opt) return switch opt { case Some(_) : true; case None: false; });

	public static function skipNull<T>(producer : Producer<Null<T>>) : Producer<T>
		return producer
			.filter(function(value) return null != value);

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

	public static function ofTimedArray<T>(values : Array<T>, delay : Int) : Producer<T> {
		return left(ofArray(values).zip(new Interval(delay, values.length)));
	}

	public static function delayed<T>(producer : Producer<T>, delay : Int) : Producer<T> {
		return new Producer(function(forward) {
			producer.feed(new Bus(
				function(v)
					Timer.setTimeout(function() forward(Emit(v)), delay),
				function()
					Timer.setTimeout(function() forward(End), delay),
				function(error)
					Timer.setTimeout(function() forward(Fail(error)), delay)
			));
		}, producer.endOnError);
	}
}

class StringProducer {
	public static function toBool(producer : Producer<String>) : Producer<Bool>
		return producer
			.map(function(s) return s != null && s != "");
}

class Bus<T> {
	public static function feed<T>(forward : Pulse<T> -> Void) {
		return new Bus(
			function(v) forward(Emit(v)),
			function() forward(End),
			function(error) forward(Fail(error))
		);
	}

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