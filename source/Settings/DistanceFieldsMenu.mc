import Toybox.Lang;
import Toybox.WatchUi;
using Toybox.Graphics;

(:basic)
class DistanceFieldsMenu extends ListMenu{
	hidden var settings as Settings;
	hidden var screenIndex as Number;
	hidden var fieldIndex as Number;

	function initialize(delegate as MyMenuDelegate, settings as Settings, screenIndex as Number, fieldIndex as Number){
		self.settings = settings;
		self.screenIndex = screenIndex;
		self.fieldIndex = fieldIndex;

		ListMenu.initialize(
            delegate,
            WatchUi.loadResource(Rez.Strings.distanceFields) as String,
            [
                WatchUi.loadResource(Rez.Strings.distance),
                WatchUi.loadResource(Rez.Strings.remainingDistance),
            ] as Array<String>
        );
	}

 	function onSelect(sender as MyMenuDelegate, item as WatchUi.MenuItem) as Boolean {
		var id = item.getId() as String;

        var fieldId = (id == 0)
            ? DATAFIELD_ELAPSED_DISTANCE
            : DATAFIELD_REMAINING_DISTANCE;

        // save field selection
        var screensSettings = settings.get(Settings.ID_DATASCREENS) as DataView.ScreensSettings;
        var screenSettings = screensSettings[screenIndex] as DataView.ScreenSettings;
        var fieldIds = screenSettings[DataView.SETTING_FIELDS] as Array<DataFieldId>;
        fieldIds[fieldIndex] = fieldId;
        screenSettings[DataView.SETTING_FIELDS] = fieldIds;
        screensSettings[screenIndex] = screenSettings;
        settings.set(Settings.ID_DATASCREENS, screensSettings);
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
		return true;
	}
}