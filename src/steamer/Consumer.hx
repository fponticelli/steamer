package steamer;

import thx.Error;

typedef Consumer<T> = {
	function onPulse(pulse : Pulse<T>) : Void;
}
