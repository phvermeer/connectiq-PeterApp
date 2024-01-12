using Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Application;

class MyOptionsMenu extends MyMenu{
	var id as Settings.Id;

	function initialize(title as String, id as Settings.Id, options as Dictionary ){
		MyMenu.initialize( { :title => title } );
		self.id = id;

		// create menu items for each option
		var ids = options.keys() as Array<Settings.Id>; 
		var titles = options.values() as Array<String>;
		for(var i=0; i<options.size(); i++){
			addItem(
				new WatchUi.MenuItem(
					titles[i],
					null,
					ids[i],
					{}
				)
			);
		}			
	}
	
	// events
	function onSelect(item as WatchUi.MenuItem) as Boolean {
		var value = item.getId() as PropertyValueType;
		getApp().settings.set(id, value);
		
		WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
		return true;
	}
}
