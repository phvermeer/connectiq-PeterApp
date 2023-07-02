import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Application;

class LayoutPickerDelegate extends WatchUi.BehaviorDelegate{
	hidden var screenIndex as Lang.Number;
	hidden var dataView as DataView;
	hidden var screensSettings as DataScreensSettings;
	hidden var originalFields as Array<MyDataField>;

	function initialize(dataView as DataView, screenIndex as Lang.Number, screensSettings as DataScreensSettings){
		self.dataView = dataView;
		self.screenIndex = screenIndex;
		self.originalFields = dataView.getFields();
		self.screensSettings = screensSettings;

		BehaviorDelegate.initialize();
	}

	function onNextPage() as Boolean{
		var layoutId = screensSettings.items[screenIndex].layoutId;
		layoutId = ((layoutId >= LAYOUT_MAX) ? 0 : layoutId + 1) as LayoutId;
		screensSettings.items[screenIndex].layoutId = layoutId;

		var layout = DataView.getLayoutById(layoutId);
		showLayout(layout);
		return true;
	}
	
	function onPreviousPage() as Boolean{
		var layoutId = screensSettings.items[screenIndex].layoutId;
		layoutId = ((layoutId <= 0) ? LAYOUT_MAX : layoutId - 1) as LayoutId;
		screensSettings.items[screenIndex].layoutId = layoutId;

		var layout = DataView.getLayoutById(layoutId);
		showLayout(layout);
		return true;
	}
	
	function showLayout(layout as Layout) as Void{
		// determine the fields for selected layout style
		var newCount = layout.size();
		var oldCount = originalFields.size();
		var fields = new [newCount] as Array<MyDataField>;
		for(var i=0; i<newCount; i++){
			if(i<oldCount){
				fields[i] = originalFields[i];
			}else{
				fields[i] = getApp().fieldManager.getField(DATAFIELD_TEST);
			}
		}

		dataView.setLayout(layout);
		dataView.setFields(fields);
		WatchUi.requestUpdate();
	}
	
	function onSelect() as Lang.Boolean{
		// save current layout
		$.getApp().settings.set(SETTING_DATASCREENS, screensSettings.export());
		return true;
	}
}