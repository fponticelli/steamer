package steamer.dom;

import js.html.Element;
import js.html.Event;
import steamer.Consumer;
import steamer.Producer;

class Dom {
	public static function produceEvent(el : Element, name : String) : { producer : Producer<Event>, cancel : Void -> Void } {
		var cancel = null,
			producer =  new Producer(function(forward) {
				var f = function(e) {
					forward(Emit(e));
				};
				el.addEventListener(name, f, false);
				cancel = function() {
					el.removeEventListener(name, f, false);
					forward(End);
				};
			});
		return { producer : producer, cancel : cancel };
	}

	public static function consumeText(el : Element) : Consumer<String>
		return createConsumer(function(v) el.innerText = v);

	public static function consumeHtml(el : Element) : Consumer<String>
		return createConsumer(function(v) el.innerHTML = v);

	public static function consumeAttribute<T>(el : Element, attr : String) : Consumer<String>
		return createConsumer(function(v) el.setAttribute(attr, v));

	public static function consumeToggleClass<T>(el : Element, name : String) : Consumer<Bool>
		return createConsumer(function(v) {
			if(v)
				el.classList.add(name);
			else
				el.classList.remove(name);
		});

	public static function consumeToggleVisibility<T>(el : Element) : Consumer<Bool>
		return createConsumer(function(v) {
			if(v)
				el.style.display = '';
			else
				el.style.display = 'none';
		});

	static function createConsumer<T>(f : T -> Void) {
		return {
			onPulse: function(pulse : Pulse<T>) {
				switch(pulse) {
					case Emit(v):
						f(v);
					case End:
					case Fail(error):
						throw error;
				}
			}
		}
	}
}