import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Application;

(:advanced)
class DataScreensMenu extends MyMenu {
	
	const OPTIONS = {
		DataView.SETTING_ENABLED => {
			false => WatchUi.loadResource(Rez.Strings.off),		
			true => WatchUi.loadResource(Rez.Strings.on),		
		},
	};
	
	function initialize(){
		MyMenu.initialize({ :title => WatchUi.loadResource(Rez.Strings.dataScreens) as String });
	}

	function onShow(){
		// Update screen sub items
		var screensSettings = $.getApp().settings.get(Settings.ID_DATASCREENS) as DataView.ScreensSettings;
		for(var i=0; i < screensSettings.size(); i++){
			addScreenItem(i, screensSettings[i]);
		}
		
		// And add an item to add a new one
		addAddItem();
	}
	function onHide(){
		// remove all sub items
		while(deleteItem(0)){}
	}
	
	hidden function addScreenItem(screenIndex as Number, screenSettings as DataView.ScreenSettings) as Void{
		// Show sub menu item for each screen
		var id = DataView.SETTING_ENABLED;
		var options = OPTIONS.get(id) as Dictionary;

		var label = Lang.format("$1$ $2$", [WatchUi.loadResource(Rez.Strings.dataScreen), screenIndex+1]);

		var enabled = screenSettings[DataView.SETTING_ENABLED] as Boolean;
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
		var settings = $.getApp().settings;
		var screensSettings = settings.get(Settings.ID_DATASCREENS) as DataView.ScreensSettings;

		switch(id){
			case "add":{

				// remove "add" item after current screen items
				var count = screensSettings.size();
				var i = count;
				deleteItem(count);

				// add new screen with default settings
				var screenSettings = [LAYOUT_ONE_FIELD, [DATAFIELD_TEST], true] as DataView.ScreenSettings;
				screensSettings.add(screenSettings);
				count++;
				addScreenItem(i, screenSettings);

				// save to settings
				settings.set(Settings.ID_DATASCREENS, screensSettings);
				addAddItem();
				break;			
			}
			default:{
				var screenIndex = id as Number;
				var menu = new DataScreenMenu(screenIndex, screensSettings);
				WatchUi.pushView(menu, menu.getDelegate(), WatchUi.SLIDE_IMMEDIATE);
				break;
			}
		}
		return false;
	}
}