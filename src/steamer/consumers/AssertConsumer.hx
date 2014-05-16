package steamer.consumers;

import utest.Assert;
import steamer.Pulse;

class AssertConsumer<T> {
	var pulses : Iterator<Pulse<T>>;
	var afterEnd : Void -> Void;

	public static function ofPulses<T>(arr : Array<Pulse<T>>, ?afterEnd : Void -> Void) : AssertConsumer<T>
		return new AssertConsumer(arr.concat([End]).iterator(), afterEnd);

	public static function ofArray<T>(arr : Array<T>, ?afterEnd : Void -> Void) : AssertConsumer<T>
		return ofPulses(arr.map(function(v) return Emit(v)), afterEnd);

	public function new(iterator : Iterator<Pulse<T>>, ?afterEnd : Void -> Void) {
		this.afterEnd = null != afterEnd ? afterEnd : function(){};
		this.pulses = iterator;
	}

	public function onPulse(pulse : Pulse<T>) {
		if(!pulses.hasNext())
			return Assert.fail('Received ${pulse} but the expectation queue is empty');
		var expect = pulses.next();
		Assert.same(expect, pulse);
		if(Type.enumEq(pulse, steamer.Pulse.End))
			afterEnd();
	}

	public function assertEmpty()
		Assert.isFalse(pulses.hasNext(), "Consumer expectation iterator is not empty");

	public function assertNotEmpty()
		Assert.isTrue(pulses.hasNext(), "Consumer expectation iterator is empty");
}