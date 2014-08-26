package steamer.producers;

import steamer.Pulse;
import steamer.Consumer;
import steamer.Producer;

import thx.core.Nil;
import thx.Timer;

class Interval extends Producer<Nil> {
	public function new(delay : Int, times : Int = 0) {
		super(function(pulse) {
			var callback = null;
			if(times <= 0){
				callback = function() {
					Timer.setInterval(function() pulse(Pulses.nil), delay);
				};
			} else {
				callback = function() {
					pulse(Pulses.nil);
					if(0 == --times)
						pulse(End);
					else
						Timer.setTimeout(callback, delay);
				};
			}
			callback();
		});
	}
}