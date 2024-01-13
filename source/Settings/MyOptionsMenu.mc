import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Application;

(:basic)
class MyOptionsMenu extends MyMenu{
	var settings as Settings;
	var id as Settings.Id;

	function initialize(
		delegate as MyMenuDelegate, 
		settings as Settings, 
		id as Settings.Id,
		options as {
			:title as String,
			:values as Dictionary,
		}
	){
		self.settings = settings;
		self.id = id;

		// header
		MyMenu.initialize(delegate, options);

		// create menu items for each option
		var values = options.get(:values) as Dictionary;
		if(values != null){			
			var ids = values.keys() as Array<Settings.Id>; 
			var titles = values.values() as Array<String>;

			for(var i=0; i<values.size(); i++){
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
	}
	
	// events
	function onSelect(sender as MyMenuDelegate, item as MenuItem) as Boolean {
		var value = item.getId() as PropertyValueType;
		getApp().settings.set(id, value);
		
		WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
		return true;
	}
}
