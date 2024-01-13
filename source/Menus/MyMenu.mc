import Toybox.Lang;
import Toybox.WatchUi;

(:advanced)
class MyMenu extends WatchUi.Menu2{

	function initialize(
		options as { 
			:title as String or Symbol or Drawable,
			:focus as Number
		} or Null
	){
		Menu2.initialize(options);
	}
	
	function getDelegate() as WatchUi.Menu2InputDelegate{
		return new MyMenuDelegate(self);
	}
	
	// Events from delegates (to override)
	function onBack() as Boolean {
		return false;
	}
	function onSelect(item as MenuItem) as Boolean {
		return false;
	}
	function onTitle() as Boolean{
		return false;	
	}
}
