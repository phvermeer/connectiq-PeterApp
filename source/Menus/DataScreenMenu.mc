import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Application;

class DataScreenMenu extends MyMenu {
	protected var screenIndex as Lang.Number;
	hidden var screenSettings as DataScreenSettings;

	function initialize(screenIndex as Lang.Number, screenSettings as DataScreenSettings){
		self.screenIndex = screenIndex;
		self.screenSettings = screenSettings;

		var title = Lang.format("$1$ $2$", [WatchUi.loadResource(Rez.Strings.dataScreen), screenIndex]);
		MyMenu.initialize({ :title => title });
		
		// add the menu items
		if(screenIndex>0){
			var id = DataScreenSettings.SETTING_ENABLED;
			addItem(
				new WatchUi.ToggleMenuItem(
					WatchUi.loadResource(Rez.Strings.state) as String,
					{
						:enabled => WatchUi.loadResource(Rez.Strings.on) as String,
						:disabled => WatchUi.loadResource(Rez.Strings.off) as String,
					} ,
					id,
					screenSettings.enabled, // screen enabled setting
					{}
				)
			);		
		}
		
		// Select Layout item
		var id = DataScreenSettings.SETTING_LAYOUT;
		addItem(
			new WatchUi.MenuItem(
				WatchUi.loadResource(Rez.Strings.dataLayout) as String,
				null,
				id,
				{}
			)
		);		
		
		// Select Fields item
		id = DataScreenSettings.SETTING_FIELDS;
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

		var layout = DataView.getLayoutById(screenSettings.layoutId);

		var count = layout.size();
		var subLabel = Lang.format("$1$ $2$", [
			count, 
			(count==1)
				? WatchUi.loadResource(Rez.Strings.dataField) as String
				: WatchUi.loadResource(Rez.Strings.dataFields) as String
		]);
		(getItem(findItemById(DataScreenSettings.SETTING_LAYOUT)) as MenuItem).setSubLabel(subLabel);	
	}
	
	function onSelect(item){
		var settings = $.getApp().settings;
		var screensSettings = new DataScreensSettings(settings.get(SETTING_DATASCREENS));
		var id = item.getId() as String|DataScreenSettings.DataViewSettingId;

		switch(id){
/*
			// Open LayoutPicker
			case DataScreenSettings.SETTING_LAYOUT:
				{
					var layout = DataView.getLayoutById(screenSettings.layoutId);
					var fields = FieldManager.getFields(screenSettings.fieldIds);

					var view = new DataView({
						:layout => layout,
						:fields => fields
					});
					var delegate = new LayoutPickerDelegate(view, screenIndex);
					WatchUi.pushView(view, delegate, WatchUi.SLIDE_IMMEDIATE);				
					break;
				}
			// Open FieldsPicker
			case DataScreenSettings.SETTING_FIELDS:
				{
					var layout = DataView.getLayoutById(layoutId);
					var fields = FieldManager.getFields(fieldIds);

					var view = new DataView({
						:layout => layout,
						:fields => fields
					});
					var delegate = new FieldPickerDelegate(view, screenIndex);
					WatchUi.pushView(view, delegate, WatchUi.SLIDE_IMMEDIATE);
					break;
				}
			// Toggle menus
*/			case DataScreenSettings.SETTING_ENABLED:
				screenSettings.enabled = (item as ToggleMenuItem).isEnabled();
				screensSettings.items[screenIndex] = screenSettings;
				settings.set(SETTING_DATASCREENS, screensSettings.export());
				return true;
			case "remove":
				screensSettings.removeScreen(screenIndex);
				settings.set(SETTING_DATASCREENS, screensSettings.export());
				
				WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
				return true;
			default:
				return false;
		}
	}

	function onFieldSelected(data as { :fieldIndex as Lang.Number, :field as MyDataField }) as Void{
		//System.println("field selected");	
	}
}