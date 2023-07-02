import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Application;

class DataScreensMenu extends MyMenu {
	
	const OPTIONS = {
		DataScreenSettings.SETTING_ENABLED => {
			false => WatchUi.loadResource(Rez.Strings.off),		
			true => WatchUi.loadResource(Rez.Strings.on),		
		},
	};
	
	function initialize(){
		MyMenu.initialize({ :title => WatchUi.loadResource(Rez.Strings.dataScreens) as String });
	}

	function onShow(){
		// Update screen sub items
		var screens = new DataScreensSettings($.getApp().settings.get(SETTING_DATASCREENS));
		for(var i=0; i < screens.items.size(); i++){
			addScreenItem(i, screens.items[i]);
		}
		
		// And add an item to add a new one
		addAddItem();
	}
	function onHide(){
		// remove all sub items
		while(deleteItem(0)){}
	}
	
	hidden function addScreenItem(screenIndex as Number, screenSettings as DataScreenSettings) as Void{
		// Show sub menu item for each screen
		var id = DataScreenSettings.SETTING_ENABLED;
		var options = OPTIONS.get(id) as Dictionary;

		var label = Lang.format("$1$ $2$", [WatchUi.loadResource(Rez.Strings.dataScreen), screenIndex+1]);

		var enabled = screenSettings.enabled;
		var subLabel = (screenIndex == 0) ? null : options.get(enabled) as String;
		
		addItem(
			new WatchUi.MenuItem(
				label,
				subLabel,
				screenIndex,
				{}
			)
		);
	}
	protected function addAddItem() as Void{
		addItem(
			new WatchUi.MenuItem(
				WatchUi.loadResource(Rez.Strings.add) as String,
				null,
				"add",
				{}
			)
		);
	}

	// this could be modified or overridden for customization
	function onSelect(item){
		var id = item.getId() as Number | String;
		switch(id){
			case "add":{
				var settings = $.getApp().settings;
				var screens = new DataScreensSettings(settings.get(SETTING_DATASCREENS));

				// remove "add" item after current screen items
				var count = screens.items.size();
				var i = count;
				deleteItem(count);

				// add new screen with default settings
				screens.addScreen(null); 
				count++;
				addScreenItem(i, screens.items[i]);

				// save to settings
				settings.set(SETTING_DATASCREENS, screens.export() as PropertyValueType);
				addAddItem();
				break;			
			}
			default:{
//				var screenIndex = id as Number;
//				var menu = new DataScreenMenu(screenIndex);
//				WatchUi.pushView(menu, menu.getDelegate(), WatchUi.SLIDE_IMMEDIATE);
				break;
			}
		}
		return false;
	}
}