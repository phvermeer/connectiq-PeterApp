import Toybox.WatchUi;
import Toybox.Lang;
import MyBarrel.Views;

(:advanced)
class FieldPickerDelegate extends MyViewDelegate{
	protected var screenIndex as Number;
	hidden var screensSettings as DataView.ScreensSettings;

	function initialize(screenIndex as Lang.Number, screensSettings as DataView.ScreensSettings){
		MyViewDelegate.initialize();
		self.screenIndex = screenIndex;
		self.screensSettings = screensSettings;
	}

	function onTap(clickEvent as ClickEvent) as Lang.Boolean{
		// Determine the field that is tapped
		var view = getView();
		if(view != null && view instanceof DataView){
			var dataView = view as DataView;

			var layout = dataView.getFieldsLayout();
			for(var i=layout.size()-1; i>=0; i--){
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
		}
		return false;
	}

	function onBack(){
		// prevent opening the stop screen
		return false;
	}	
}