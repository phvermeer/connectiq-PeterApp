using Toybox.WatchUi;
import Toybox.Lang;

class MyMenuDelegate extends WatchUi.Menu2InputDelegate {
	protected var menuRef as WeakReference;
	
	function initialize(menu as MyMenu){
		Menu2InputDelegate.initialize();
		self.menuRef = menu.weak();
	}

	function onBack() as Void {
		var obj = menuRef.get();
		if(obj != null && obj instanceof MyMenu){
			if((obj as MyMenu).onBack()){
				return;
			}
		}
		Menu2InputDelegate.onBack();
	}
	
	function onSelect(item as WatchUi.MenuItem) as Void {
		var obj = menuRef.get();
		if(obj != null && obj instanceof MyMenu){
			if((obj as MyMenu).onSelect(item)){
				return;
			}
		}
		Menu2InputDelegate.onSelect(item);
	}
	
	function onTitle() as Void {
		var obj = menuRef.get();
		if(obj != null && obj instanceof MyMenu){
			if((obj as MyMenu).onTitle()){
				return;
			}
		}
		Menu2InputDelegate.onTitle();
	}
}