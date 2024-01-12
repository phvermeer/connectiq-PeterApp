import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Application;

class FieldsSubMenu extends MyMenu{
	hidden var dataView as DataView;
	hidden var screenIndex as Number; 
	hidden var screensSettings as DataView.ScreensSettings;
	hidden var fieldIndex as Number; 

	function initialize(
		settings as {:title as String, :items as Dictionary },
		dataView as DataView, 
		screenIndex as Number,
		screensSettings as DataView.ScreensSettings,
		fieldIndex as Number
	){
		self.dataView = dataView;
		self.screenIndex = screenIndex;
		self.screensSettings = screensSettings;
		self.fieldIndex = fieldIndex;

		MyMenu.initialize({
		  :title => settings.get(:title) as String
		});
		
		// Add options
		var items = settings.get(:items) as Dictionary;
		var ids = items.keys() as Array<String>;
		var values = items.values() as Array<String>;
		for(var i=0; i<ids.size(); i++){
			addItem(
				new WatchUi.MenuItem(
					values[i],
					null,
					ids[i],
					null
				)
			);
		}
	}

	function onSelect(item as MenuItem) as Boolean{
		var fieldId = item.getId() as DataFieldId;

		// save to settings
		var screenSettings = screensSettings[screenIndex] as DataView.ScreenSettings;
		var fieldIds = screenSettings[DataView.SETTING_FIELDS] as Array<DataFieldId>;
		fieldIds[fieldIndex] = fieldId;
		screenSettings[DataView.SETTING_FIELDS] = fieldIds;
		screensSettings[screenIndex] = screenSettings;

		$.getApp().settings.set(Settings.ID_DATASCREENS, screensSettings);
		
		// close field select menu's
		WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); // close FieldsSubMenu		
		WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); // close FieldsMainMenu
		return true;
	}
}