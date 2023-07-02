import Toybox.WatchUi;
import Toybox.Lang;

class AutoLapMenu extends MyMenu {
	hidden var options as Lang.Dictionary;

	function initialize(options as Dictionary){
		MyMenu.initialize({ :title => WatchUi.loadResource(Rez.Strings.autoLap) as String });
		self.options = options;

		var id = SETTING_AUTOLAP;
		
		addItem(
			new WatchUi.ToggleMenuItem(
				WatchUi.loadResource(Rez.Strings.state) as String,
				{
					:enabled => (options.get(id) as Dictionary).get(true) as String,
					:disabled => (options.get(id) as Dictionary).get(false) as String,
				},
				id,
				getApp().settings.get(id) as Boolean,
				null
			)
		);

		id = SETTING_AUTOLAP_DISTANCE;
		addItem(
			new WatchUi.MenuItem(
				WatchUi.loadResource(Rez.Strings.distance) as String,
				null,
				id,
				{}
			)
		);

	}

	function onShow(){
		// Update status of settings changed in sub menus
		// Auto Lap Distance
		var id = SETTING_AUTOLAP_DISTANCE;
		var value = getApp().settings.get(id) as Lang.Number;
		(getItem(1) as MenuItem).setSubLabel((options.get(id) as Dictionary).get(value) as String);
	}

	// this could be modified or overridden for customization
	function onSelect(item as MenuItem) as Boolean{
		var id = item.getId() as SettingId;

		switch(id){
		
		// Option menus
		case SETTING_AUTOLAP_DISTANCE:

			var menu = new MyOptionsMenu(
				WatchUi.loadResource(Rez.Strings.distance) as String,
				id,
				options.get(id as Number) as Dictionary
			);
			WatchUi.pushView(menu, menu.getDelegate(), WatchUi.SLIDE_IMMEDIATE);
			return true;

		// Toggle menus
		case SETTING_AUTOLAP:
			getApp().settings.set(id, (item as ToggleMenuItem).isEnabled());
			return true;
		default:
			return false;
		}
	}

	function onBack() as Boolean{
		return false;
	}
}