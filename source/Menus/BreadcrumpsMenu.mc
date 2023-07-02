import Toybox.WatchUi;
import Toybox.Lang;

class BreadcrumpsMenu extends MyMenu {
	hidden var options as Lang.Dictionary;

	function initialize(options as Dictionary){
		MyMenu.initialize({ :title => WatchUi.loadResource(Rez.Strings.autoLap) as String });
		self.options = options;

		var id = SETTING_BREADCRUMPS;
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

		id = SETTING_BREADCRUMPS_MIN_DISTANCE;
		addItem(
			new WatchUi.MenuItem(
				WatchUi.loadResource(Rez.Strings.betweenDistance) as String,
				null,
				id,
				{}
			)
		);

		id = SETTING_BREADCRUMPS_MAX_COUNT;
		addItem(
			new WatchUi.MenuItem(
				WatchUi.loadResource(Rez.Strings.maxCount) as String,
				null,
				id,
				{}
			)
		);
	}

	function onShow(){
		// Update status of settings changed in sub menus

		// Minimum breadcrump distance
		var id = SETTING_BREADCRUMPS_MIN_DISTANCE;
		var value = getApp().settings.get(id) as Lang.Number;
		(getItem(1) as MenuItem).setSubLabel((options.get(id) as Dictionary).get(value) as String);

		// Maximum breadcrump count
		id = SETTING_BREADCRUMPS_MAX_COUNT;
		value = getApp().settings.get(id) as Lang.Number;
		(getItem(2) as MenuItem).setSubLabel((options.get(id) as Dictionary).get(value) as String);

	}

	// this could be modified or overridden for customization
	function onSelect(item as MenuItem) as Boolean{
		var id = item.getId() as SettingId;

		switch(id){
		
		// Option menus
		case SETTING_BREADCRUMPS_MIN_DISTANCE:
		case SETTING_BREADCRUMPS_MAX_COUNT:

			var menu = new MyOptionsMenu(
				WatchUi.loadResource(Rez.Strings.distance) as String,
				id,
				options.get(id as Number) as Dictionary
			);
			WatchUi.pushView(menu, menu.getDelegate(), WatchUi.SLIDE_IMMEDIATE);
			return true;

		// Toggle menus
		case SETTING_BREADCRUMPS:
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