import Toybox.Lang;
import Toybox.WatchUi;
import MyBarrel.Views;

class DataScreenMenu extends MyMenu{
    hidden var settings as Settings;
    hidden var screenIndex as Number;

    function initialize(screenIndex as Number, settings as Settings, delegate as MyMenuDelegate){
        self.settings = settings;
        self.screenIndex = screenIndex;
        MyMenu.initialize(delegate,{
            :title => WatchUi.loadResource(Rez.Strings.dataScreen) as String,
        });
        //updateItems();
    }

    function onShow(){
        MyMenu.onShow();
        updateItems();
    }

    hidden function updateItems() as Void{
        clearItems();

        var screens = settings.get(Settings.ID_DATASCREENS) as Array;
        var screen = screens[screenIndex] as Array;

        var fields = screen[1] as Array;
        var enabled = screen[2] as Boolean;

        if(screenIndex > 0){
            addItem(
				new WatchUi.ToggleMenuItem(
					WatchUi.loadResource(Rez.Strings.state) as String,
					{
						:enabled => WatchUi.loadResource(Rez.Strings.on) as String,
						:disabled => WatchUi.loadResource(Rez.Strings.off) as String,
					} ,
					DataView.SETTING_ENABLED,
					enabled, // screen enabled setting
					{}
				)
            );
        }

        var count = fields.size();
        var txtInfo = Lang.format("$1$ $2$", [
			count, 
			(count==1)
				? WatchUi.loadResource(Rez.Strings.dataField) as String
				: WatchUi.loadResource(Rez.Strings.dataFields) as String
		]);

        addItem(
            new WatchUi.MenuItem(
                WatchUi.loadResource(Rez.Strings.dataLayout) as String,
                txtInfo,
                DataView.SETTING_LAYOUT,
                {}
            )
        );

        addItem(
            new WatchUi.MenuItem(
                WatchUi.loadResource(Rez.Strings.dataFields) as String,
                null,
                DataView.SETTING_FIELDS,
                {}
            )
        );

        addItem(
            new WatchUi.MenuItem(
                WatchUi.loadResource(Rez.Strings.remove) as String,
                null,
                -1,
                {}
            )
        );
    }

    function onSelect(sender as MyMenuDelegate, item as MenuItem) as Boolean{
        var id = item.getId();
        var screens = settings.get(Settings.ID_DATASCREENS) as Array;
        var screen = screens[screenIndex] as Array;
        var data = $.getApp().data;
        
        if(id == DataView.SETTING_ENABLED){
            // enabled/disabled
            screen[DataView.SETTING_ENABLED] = (item as ToggleMenuItem).isEnabled();
            screens[screenIndex] = screen;
            settings.set(Settings.ID_DATASCREENS, screens as Settings.ValueType);
        }else if(id == DataView.SETTING_LAYOUT || id == DataView.SETTING_FIELDS){
            // open customized dataview to pick layout or field
            var delegate = new Views.MyViewDelegate();
            var view = (id == DataView.SETTING_LAYOUT)
                ? new LayoutPickerView(screenIndex, settings, delegate)
                : new FieldPickerView(screenIndex, settings, delegate);
            data.addListener(view);
            settings.addListener(view);
            WatchUi.pushView(view, delegate, WatchUi.SLIDE_IMMEDIATE);
        }else if(id == -1){
            // remove this datascreen
            screens = settings.get(Settings.ID_DATASCREENS) as DataView.ScreensSettings;
            screen = screens[screenIndex];
            screens.remove(screen);
            settings.set(Settings.ID_DATASCREENS, screens);
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        }else{
            return false;
        }
        return true;
    }
}