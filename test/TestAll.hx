import utest.Assert;
import utest.Runner;
import utest.ui.Report;

import steamer.*;
import steamer.Pulse;
import steamer.consumers.*;
import steamer.producers.*;
import thx.Nil;


class TestAll {
	public static function main() {
		var runner = new Runner(),
			report = Report.create(runner);

		runner.addCase(new TestAll());

		runner.run();
	}

	public function new() { }

	public function testConsumer() {
		var consumer = AssertConsumer.ofArray([1,2]);

		consumer.onPulse(Emit(1));
		consumer.onPulse(Emit(2));
		consumer.onPulse(End);

		consumer.assertEmpty();
	}

	public function testInterval() {
		new Interval(10, 5) // 10ms, 5 times
			.feed(
				AssertConsumer.ofArray(
					[nil,nil,nil,nil,nil],
					Assert.createAsync()
				)
			);
	}

	public function testArray() {
		Producer
			.ofArray([1,2,3])
			.feed(
				AssertConsumer.ofArray(
					[1,2,3],
					Assert.createAsync()
				)
			);
	}

	public function testMap() {
		Producer
			.ofArray([1,2,3])
			.map(function(v) return ""+v+v)
			.feed(
				AssertConsumer.ofArray(
					["11","22","33"],
					Assert.createAsync()
				)
			);
	}
}