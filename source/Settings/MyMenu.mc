import Toybox.Lang;
import Toybox.WatchUi;

(:basic)
class MyMenu extends WatchUi.Menu2{
    private var weakDelegate as WeakReference;
	private var visible as Boolean = false;

	function initialize(
		delegate as MyMenuDelegate,
		options as { 
			:title as String or Symbol or Drawable,
			:focus as Number
		} or Null
	){
		Menu2.initialize(options);
		weakDelegate = delegate.weak();
		delegate.addMenu(self);
	}
	function getDelegate() as MyMenuDelegate|Null{
		return weakDelegate.get() as MyMenuDelegate|Null;
	}
	
	// visibility
	function onShow() as Void{
		visible = true;
	}
	function onHide() as Void{
		visible = false;
	}
	function isVisible() as Boolean{
		return visible;
	}

	// Events from delegates (to override)
	function onBack(sender as MyMenuDelegate) as Boolean {
		return false;
	}
	function onSelect(sender as MyMenuDelegate, item as MenuItem) as Boolean {
		return false;
	}
	function onTitle(sender as MyMenuDelegate) as Boolean{
		return false;	
	}

	// handy functions
	hidden function clearItems() as Void{
		while(deleteItem(0)){
			continue;
		}
	}
}
