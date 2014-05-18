import utest.Assert;
import utest.Runner;
import utest.ui.Report;

using steamer.Producer;
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

	public function testFlatMap() {
		Producer.ofArray([
				[1],
				[2,3],
				[4,5,6]
			])
			.flatMap()
			.feed(
				AssertConsumer.ofArray(
					[1,2,3,4,5,6],
					Assert.createAsync()
				)
			);
	}

	public function testFilter() {
		Producer.ofArray([1,2,3,4,5])
			.filter(function(v) return v % 2 == 0)
			.feed(
				AssertConsumer.ofArray([2,4], Assert.createAsync())
			);
	}

	public function testMerge() {
		Producer
			.ofArray([1,2,3])
			.merge(Producer.ofArray([4,5,6]))
			.feed(
				AssertConsumer.ofArray([1,2,3,4,5,6], Assert.createAsync())
			);
	}

	public function testCombina() {
		Producer
			.ofArray([1,2,3,4,5])
			.combine(Producer.ofArray(["a","b","c"]), function(i, s) return s + i)
			.feed(
				AssertConsumer.ofArray(["a1","b2","c3"], Assert.createAsync())
			);
	}
}