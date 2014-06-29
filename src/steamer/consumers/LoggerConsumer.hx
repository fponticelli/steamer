package steamer.consumers;

import haxe.PosInfos;
import steamer.Pulse;

class LoggerConsumer {
	public var prefix : String;
	public var pos : PosInfos;
	public function new(?prefix : String, ?pos : PosInfos) {
		this.prefix = prefix;
		this.pos = pos;
#if js
		function p()
			return ' ---> ' + pos.className + '.' + pos.methodName + '() at ' + pos.lineNumber;
		log   = function(v) untyped __js__('console').log(v, p());
		warn  = function(v) untyped __js__('console').warn(v, p());
		error = function(v) untyped __js__('console').error(v, p());
#end
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

	dynamic function log(v : String)
		haxe.Log.trace(v, pos);
	dynamic function warn(v : String)
		haxe.Log.trace('[W] $v', pos);
	dynamic function error(v : String)
		haxe.Log.trace('[E] $v', pos);

}