import Toybox.WatchUi;
import Toybox.Lang;

class FieldPickerDelegate extends WatchUi.BehaviorDelegate{
	protected var dataView as DataView;
	protected var screenIndex as Number;
	hidden var screensSettings as DataScreensSettings;

	function initialize(dataView as DataView, screenIndex as Lang.Number, screensSettings as DataScreensSettings){
		BehaviorDelegate.initialize();
		self.dataView = dataView;
		self.screenIndex = screenIndex;
		self.screensSettings = screensSettings;
	}

	function onTap(clickEvent as ClickEvent) as Lang.Boolean{
		// Determine the field that is tapped
		var layout = dataView.getLayout();
		for(var i=0; i<layout.size(); i++){
			var fl = layout[i];
			var xy = clickEvent.getCoordinates();
			var x = xy[0];
			var y = xy[1];
			if(
				(x >= fl[0]) && (x <= fl[0] + fl[2]) &&
				(y >= fl[1]) && (y <= fl[1] + fl[3])
			){
				var menu = new FieldsMainMenu(dataView, screenIndex, screensSettings, i);
				WatchUi.pushView(menu, menu.getDelegate(), WatchUi.SLIDE_IMMEDIATE);
				return true;
			}
		}
		return false;
	}
}