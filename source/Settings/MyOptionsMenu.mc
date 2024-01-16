import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Application;

class MyOptionsMenu extends MyMenu{
	var settings as Settings;
	var id as Settings.Id;

	function initialize(
		delegate as MyMenuDelegate, 
		settings as Settings, 
		id as Settings.Id,
		title as String,
		textValues as Dictionary // { <value1> => <text1>, <value2> => <text2>, ... , <valueN> => <textn> }
	){
		self.settings = settings;
		self.id = id;

		// header
		MyMenu.initialize(delegate, { :title => title });

		// create menu items for each option
		var values = textValues.keys() as Array<Settings.Id>;
		var names = textValues.values() as Array<String>;

		for(var i=0; i<textValues.size(); i++){
			addItem(
				new WatchUi.MenuItem(
					names[i],
					null,
					values[i],
					{}
				)
			);
		}
	}
	
	// events
	function onSelect(sender as MyMenuDelegate, item as MenuItem) as Boolean {
		var value = item.getId() as PropertyValueType;
		settings.set(id, value);
		
		WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
		return true;
	}
}
