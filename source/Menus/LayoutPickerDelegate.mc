import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Application;
import MyBarrel.Views;

class LayoutPickerDelegate extends MyViewDelegate{
	hidden var screenIndex as Lang.Number;
	hidden var screensSettings as DataView.ScreensSettings;
	hidden var layoutId as LayoutId;
	hidden var fieldIds as Array<DataFieldId>;
	hidden var fieldIdsInitial as Array<DataFieldId>;

	function initialize(screenIndex as Lang.Number, screensSettings as DataView.ScreensSettings){
		self.screenIndex = screenIndex;
		self.screensSettings = screensSettings;

		// get initial values
		var screenSettings = screensSettings[screenIndex];
		layoutId = screenSettings[DataView.SETTING_LAYOUT] as LayoutId;
		fieldIds = screenSettings[DataView.SETTING_FIELDS] as Array<DataFieldId>;
		fieldIdsInitial = fieldIds;

		MyViewDelegate.initialize();
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

		var view = getView();
		if(view != null && view instanceof DataView){
			var dataView = view as DataView;
			dataView.setFieldsLayout(layout);
			dataView.setFields(fields);
			WatchUi.requestUpdate();
		}
	}
	
	function onSelect() as Lang.Boolean{
		// save current layout
		var screenSettings = screensSettings[screenIndex];
		screenSettings[DataView.SETTING_LAYOUT] = layoutId;
		screenSettings[DataView.SETTING_FIELDS] = fieldIds;

		$.getApp().settings.set(SETTING_DATASCREENS, screensSettings);
		return true;
	}
}