package steamer.dom;

import js.html.Element;
import js.html.Event;
import steamer.Producer;

class Dom {
	public static function emit(el : Element, name : String) : CancellableProducer<Event> {
		var cancel = null;
		return new CancellableProducer(
			function(forward) {
				var f = function(e) {
					forward(Emit(e));
				};
				el.addEventListener(name, f, false);
				cancel = function() {
					el.removeEventListener(name, f, false);
					forward(End);
				};
			},
			function() {
				cancel();
			}
		);
	}
}