import Toybox.Lang;

class MyException extends Lang.Exception {
	function initialize(msg as String) {
		Exception.initialize();
		self.mMessage = msg;
	}
}