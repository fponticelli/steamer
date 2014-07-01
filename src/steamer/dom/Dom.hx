package steamer.dom;

import js.html.Element;
import js.html.Event;
import steamer.Consumer;
import steamer.Producer;
import thx.Error;
import thx.Assert;

class Dom {
	public static function produceEvent(el : Element, name : String) : EventProducer {
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

	public static function consumeText(el : Element) : Consumer<String> {
		var originalText = el.innerText;
		function consume(text : String)
			el.innerText = text;
		return {
			emit : consume,
			end  : consume.bind(originalText)
		};
	}

	public static function consumeHtml(el : Element) : Consumer<String> {
		var originalHtml = el.innerHTML;
		function consume(html : String)
			el.innerHTML = html;
		return {
			emit : consume,
			end  : consume.bind(originalHtml)
		};
	}

	public static function consumeAttribute<T>(el : Element, name : String) : Consumer<T> {
		var originalValue : T = cast el.getAttribute(name);
		function consume(value : T)
			el.setAttribute(name, cast value);
		return {
			emit : consume,
			end  : null == originalValue ?
					function() el.removeAttribute(name) :
					consume.bind(originalValue)
		};
	}

	public static function consumeToggleAttribute<T>(el : Element, name : String) : Consumer<Bool> {
		var originalValue = el.hasAttribute(name);
		function consume(v : Bool)
			if(v)
				el.setAttribute(name, name);
			else
				el.removeAttribute(name);
		return {
			emit : consume,
			end  : consume.bind(originalValue)
		};
	}

	public static function consumeToggleClass<T>(el : Element, name : String) : Consumer<Bool> {
		var originalValue = el.classList.contains(name);
		function consume(v : Bool)
			if(v)
				el.classList.add(name);
			else
				el.classList.remove(name);
		return {
			emit : consume,
			end  : consume.bind(originalValue)
		};
	}

	public static function consumeToggleVisibility<T>(el : Element) : Consumer<Bool> {
		var originalDisplay = el.style.display;
		Assert.notNull(originalDisplay, 'original element.style.display for visibility is NULL');
		if(originalDisplay == 'none')
			originalDisplay = '';
		function consume(value : Bool) {
			if(value) {
				el.style.display = originalDisplay;
			} else {
				el.style.display = 'none';
			}
		}
		return {
			emit : consume,
			end  : consume.bind(true)
		};
	}
}

typedef EventProducer = {
	producer : Producer<Event>,
	cancel : Void -> Void
}