import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Application;

class LayoutPickerDelegate extends WatchUi.BehaviorDelegate{
	hidden var screenIndex as Lang.Number;
	hidden var dataView as DataView;
	hidden var screensSettings as DataScreensSettings;
	hidden var layoutId as LayoutId;
	hidden var fieldIds as Array<DataFieldId>;
	hidden var fieldIdsInitial as Array<DataFieldId>;

	function initialize(dataView as DataView, screenIndex as Lang.Number, screensSettings as DataScreensSettings){
		self.dataView = dataView;
		self.screenIndex = screenIndex;
		self.screensSettings = screensSettings;

		// get initial values
		var screenSettings = screensSettings.items[screenIndex];
		layoutId = screenSettings.layoutId;
		fieldIds = screenSettings.fieldIds;
		fieldIdsInitial = fieldIds;

		BehaviorDelegate.initialize();
	}

	function onNextPage() as Boolean{
		layoutId = ((layoutId >= LAYOUT_MAX) ? 0 : layoutId + 1) as LayoutId;
		showLayout();
		return true;
	}
	
	function onPreviousPage() as Boolean{
		layoutId = ((layoutId <= 0) ? LAYOUT_MAX : layoutId - 1) as LayoutId;
		showLayout();
		return true;
	}
	
	function showLayout() as Void{
		// Get the Layout
		var layout = DataView.getLayoutById(layoutId);

		// Make sure that the field count is corresponding with the layout
		var count = layout.size();
		fieldIds = [] as Array<DataFieldId>;
		for(var i=0; i<count; i++){
			if(i < fieldIdsInitial.size()){
				fieldIds.add(fieldIdsInitial[i]);
			}else{
				fieldIds.add(DATAFIELD_EMPTY);
			}
		}

		// determine the fields for selected layout style
		var fieldManager = $.getApp().fieldManager;
		var fields = fieldManager.getFields(fieldIds);

		dataView.setFieldsLayout(layout);
		dataView.setFields(fields);
		WatchUi.requestUpdate();
	}
	
	function onSelect() as Lang.Boolean{
		// save current layout
		var screenSettings = screensSettings.items[screenIndex];
		screenSettings.layoutId = layoutId;
		screenSettings.fieldIds = fieldIds;

		$.getApp().settings.set(SETTING_DATASCREENS, screensSettings.export());
		return true;
	}
}