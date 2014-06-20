package thx;

import haxe.PosInfos;
import haxe.CallStack;

class Error {
	public var message(default, null) : String;
	public var stack(default, null) : Array<StackItem>;
	public var pos(default, null) : PosInfos;
	public function new(message : String, ?stack : Array<StackItem>, ?pos : PosInfos) {
		this.message = message;
		if(null == stack) {
			stack = CallStack.exceptionStack();
			if(stack.length == 0)
				stack = CallStack.callStack();
		}
		this.stack = stack;
		this.pos = pos;
	}

	public function toString() {
		return message + "from: " + pos.className + "." + pos.methodName + "() at " + pos.lineNumber + "\n\n" + CallStack.toString(stack);
	}
}