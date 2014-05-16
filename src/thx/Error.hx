package thx;

@:native("Error")
extern class Error {
	public function new(message : String) : Void;
	public var message : String;
}