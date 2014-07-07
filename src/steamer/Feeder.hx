package steamer;

import steamer.Consumer;
import steamer.Producer;

class Feeder<T> extends Producer<T> {
	var forwards : Array<Pulse<T> -> Void>;

	public function new() {
		forwards = [];
		super(function(forward) {
			this.forwards.push(forward);
		}, false);
	}

	public function forward(pulse : Pulse<T>) {
		for(f in forwards)
			f(pulse);
		switch pulse {
			case End: forwards = [];
			case _:
		}
	}

	public function onPulse(pulse : Pulse<T>) {
		switch pulse {
			case Emit(v): forward(Emit(v));
			case Fail(e): forward(Fail(e));
			case End:     forward(End);
		}
	}
}