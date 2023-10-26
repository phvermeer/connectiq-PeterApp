import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Application;

class DataScreenMenu extends MyMenu {
	protected var screenIndex as Lang.Number;
	hidden var screensSettings as DataScreensSettings;

	function initialize(screenIndex as Lang.Number, screensSettings as DataScreensSettings){
		self.screenIndex = screenIndex;
		self.screensSettings = screensSettings;
		var screenSettings = screensSettings.items[screenIndex];

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
		var screenSettings = screensSettings.items[screenIndex];
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
		var id = item.getId() as String|DataScreenSettings.DataViewSettingId;
		var app = $.getApp();
		var settings = app.settings;
		var fieldManager = app.fieldManager;

		switch(id){
			// Open LayoutPicker
			case DataScreenSettings.SETTING_LAYOUT:
			case DataScreenSettings.SETTING_FIELDS:
				var screenSettings = screensSettings.items[screenIndex];
				var layout = DataView.getLayoutById(screenSettings.layoutId);
				var fields = fieldManager.getFields(screenSettings.fieldIds);

				var view = new DataView({
					:layout => layout,
					:fields => fields
				});

				var delegate = (id == DataScreenSettings.SETTING_LAYOUT)
					? new LayoutPickerDelegate(view, screenIndex, screensSettings)
					: new FieldPickerDelegate(view, screenIndex, screensSettings);
				WatchUi.pushView(view, delegate, WatchUi.SLIDE_IMMEDIATE);				
				return true;
			// Toggle menus
			case DataScreenSettings.SETTING_ENABLED:
				screensSettings.items[screenIndex].enabled = (item as ToggleMenuItem).isEnabled();
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