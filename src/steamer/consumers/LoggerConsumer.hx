package steamer.consumers;

import steamer.Pulse;

class LoggerConsumer {
	public var prefix : String;
	public function new(?prefix : String) {
		this.prefix = prefix;
	}

	public function onPulse(pulse : Pulse<String>) {
		switch pulse {
			case Emit(v):
				log(p(v));
			case End:
				warn(p('End'));
			case Fail(err):
				error(p(Std.string(err)));
		}
	}

	function p(v : String)
		return (null == prefix ? '' : prefix + ': ') + v;

	static dynamic function log(v : String)
		trace(v);
	static dynamic function warn(v : String)
		trace('[W] $v');
	static dynamic function error(v : String)
		trace('[E] $v');

#if js
	static function __init__() {
		log   = function(v) untyped __js__('console').log(v);
		warn  = function(v) untyped __js__('console').warn(v);
		error = function(v) untyped __js__('console').error(v);
	}
#end
}