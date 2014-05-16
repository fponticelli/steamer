package steamer;

import thx.Error;
import thx.Nil;

enum Pulse<T> {
	Emit(value : T);
	End;
	Fail(error : Error);
}

class Pulses {
	public static var nil(default, null) : Pulse<Nil> = Emit(thx.Nil.nil);

	public static function times<T>(n : Int, pulse : Pulse<T>) {
		return [for(i in 0...n) pulse].concat([End]);
	}
}