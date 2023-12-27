import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Application;

class DataScreenMenu extends MyMenu {
	protected var screenIndex as Lang.Number;
	hidden var screensSettings as DataView.ScreensSettings;

	function initialize(screenIndex as Lang.Number, screensSettings as DataView.ScreensSettings){
		self.screenIndex = screenIndex;
		self.screensSettings = screensSettings;
		var screenSettings = screensSettings[screenIndex];

		var title = Lang.format("$1$ $2$", [WatchUi.loadResource(Rez.Strings.dataScreen), screenIndex]);
		MyMenu.initialize({ :title => title });
		
		// add the menu items
		if(screenIndex>0){
			var id = DataView.SETTING_ENABLED;
			addItem(
				new WatchUi.ToggleMenuItem(
					WatchUi.loadResource(Rez.Strings.state) as String,
					{
						:enabled => WatchUi.loadResource(Rez.Strings.on) as String,
						:disabled => WatchUi.loadResource(Rez.Strings.off) as String,
					} ,
					id,
					screenSettings[DataView.SETTING_ENABLED] as Boolean, // screen enabled setting
					{}
				)
			);		
		}
		
		// Select Layout item
		var id = DataView.SETTING_LAYOUT;
		addItem(
			new WatchUi.MenuItem(
				WatchUi.loadResource(Rez.Strings.dataLayout) as String,
				null,
				id,
				{}
			)
		);		
		
		// Select Fields item
		id = DataView.SETTING_FIELDS;
		addItem(
			new WatchUi.MenuItem(
				WatchUi.loadResource(Rez.Strings.dataFields) as String,
				null,
				id,
				{}
			)
		);		

		// Remove item
		if(screenIndex>0){
			addItem(
				new WatchUi.MenuItem(
					WatchUi.loadResource(Rez.Strings.remove) as String,
					null,
					"remove",
					{}
				)
			);
		}
	}
	
	function onShow(){
		var screenSettings = screensSettings[screenIndex];
		var layoutId = screenSettings[DataView.SETTING_LAYOUT] as LayoutId;
		var layout = DataView.getLayoutById(layoutId);

		var count = layout.size();
		var subLabel = Lang.format("$1$ $2$", [
			count, 
			(count==1)
				? WatchUi.loadResource(Rez.Strings.dataField) as String
				: WatchUi.loadResource(Rez.Strings.dataFields) as String
		]);
		(getItem(findItemById(DataView.SETTING_LAYOUT)) as MenuItem).setSubLabel(subLabel);	
	}
	
	function onSelect(item){
		var id = item.getId() as String|DataView.SettingId;
		var app = $.getApp();
		var settings = app.settings;

		switch(id){
			// Open LayoutPicker
			case DataView.SETTING_LAYOUT:
			case DataView.SETTING_FIELDS:
				var view = new DataView(screenIndex, screensSettings);
				settings.addListener(view);
				app.data.addListener(view);
				var delegate = (id == DataView.SETTING_LAYOUT)
					? new LayoutPickerDelegate(view, screenIndex, screensSettings)
					: new FieldPickerDelegate(view, screenIndex, screensSettings);
				WatchUi.pushView(view, delegate, WatchUi.SLIDE_IMMEDIATE);				
				return true;
			// Toggle menus
			case DataView.SETTING_ENABLED:
				screensSettings[screenIndex][DataView.SETTING_ENABLED] = (item as ToggleMenuItem).isEnabled();
				settings.set(SETTING_DATASCREENS, screensSettings);
				return true;
			case "remove":
				screensSettings = screensSettings.slice(null, screenIndex-1).addAll(screensSettings.slice(screenIndex+1, null));
				settings.set(SETTING_DATASCREENS, screensSettings);

				WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
				return true;
			default:
				return false;
		}
	}
}