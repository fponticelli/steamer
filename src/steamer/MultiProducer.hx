package steamer;

import steamer.Consumer;
import steamer.Producer;

class MultiProducer<T> extends Producer<T> {
	var producers : Array<Producer<T>>;
	var consumers : Array<Consumer<T>>;
	public function new(endOnError = true) {
		producers = [];
		consumers = [];
		super(function(pulse) {}, endOnError);
	}

	public function add(producer : Producer<T>) {
		producers.push(producer);
		for(consumer in consumers)
			producer.feed(consumer);
	}

	public function remove(producer : Producer<T>) {
		producers.remove(producer);
	}

	override function feed(consumer : Consumer<T>) {
		for(producer in producers)
			producer.feed(consumer);
		consumers.push(consumer);
		return this;
	}
}