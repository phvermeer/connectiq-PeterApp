import Toybox.Lang;
import Toybox.WatchUi;
using Toybox.Graphics;

class FieldsSubMenu extends MyMenu{
	hidden var settings as Settings;
	hidden var screenIndex as Number;
	hidden var fieldIndex as Number;

	function initialize(
        delegate as MyMenuDelegate, 
        settings as Settings, 
        screenIndex as Number, 
        fieldIndex as Number, 
        title as String, 
        fieldList as Dictionary
    ){
		self.settings = settings;
		self.screenIndex = screenIndex;
		self.fieldIndex = fieldIndex;

   		MyMenu.initialize(delegate,
		{
		  :title => title
		});

        var ids = fieldList.keys();
        var names = fieldList.values();
        for(var i=0; i<ids.size(); i++){
            addItem(
				new WatchUi.MenuItem(
					names[i] as String,
					null,
					ids[i] as Number,
					{}
				)
			);
        }
	}

 	function onSelect(sender as MyMenuDelegate, item as WatchUi.MenuItem) as Boolean {
		var fieldId = item.getId() as DataFieldId;

        // save field selection
        var screensSettings = settings.get(Settings.ID_DATASCREENS) as DataView.ScreensSettings;
        var screenSettings = screensSettings[screenIndex] as DataView.ScreenSettings;
        var fieldIds = screenSettings[DataView.SETTING_FIELDS] as Array<DataFieldId>;
        fieldIds[fieldIndex] = fieldId;
        screenSettings[DataView.SETTING_FIELDS] = fieldIds;
        screensSettings[screenIndex] = screenSettings;
        settings.set(Settings.ID_DATASCREENS, screensSettings);

        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
		return true;
	}
}