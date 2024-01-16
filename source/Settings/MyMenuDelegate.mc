using Toybox.WatchUi;
import Toybox.Lang;

class MyMenuDelegate extends WatchUi.Menu2InputDelegate {
    private var weakMenus as Array<WeakReference> = [] as Array<WeakReference>;
	
	function initialize(){
		Menu2InputDelegate.initialize();
	}

    function addMenu(menu as MyMenu) as Void{
        weakMenus.add(menu.weak());
    }
    function getMenu() as MyMenu|Null{
        // get the menu which is visible
        for(var i=weakMenus.size()-1; i>=0; i--){
            var weakMenu = weakMenus[i];
            if(weakMenu.stillAlive()){
                var menu = weakMenu.get() as MyMenu;
                if(menu.isVisible()){
                    return menu;
                }
            }else{
                weakMenus.remove(weakMenu);
            }
        }
        return null;
    }

	function onBack() as Void {
        var menu = getMenu();
		if(menu != null && menu.onBack(self)){
            return;
        }else{
    		Menu2InputDelegate.onBack();
        }
	}
	
	function onSelect(item as WatchUi.MenuItem) as Void {
        var menu = getMenu();
		if(menu != null && menu.onSelect(self, item)){
            return;
        }else{
    		Menu2InputDelegate.onSelect(item);
        }
	}
	
	function onTitle() as Void {
        var menu = getMenu();
		if(menu != null && menu.onTitle(self)){
            return;
        }else{
    		Menu2InputDelegate.onTitle();
        }
	}
}