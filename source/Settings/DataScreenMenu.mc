import Toybox.Lang;
import Toybox.WatchUi;
import MyBarrel.Views;

(:basic)
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
					2,
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
                0,
                {}
            )
        );
    }

    function onSelect(sender as MyMenuDelegate, item as MenuItem) as Boolean{
        var id = item.getId();
        var screens = settings.get(Settings.ID_DATASCREENS) as Array;
        var screen = screens[screenIndex] as Array;
        
        if(id == 2){
            // enabled/disabled
            screen[2] = (item as ToggleMenuItem).isEnabled();
        }else if(id == 0){
            // layout
            var delegate = new Views.MyViewDelegate();
            var view = new LayoutPickerView(screenIndex, settings, delegate);
            $.getApp().data.addListener(view);
            WatchUi.pushView(view, delegate, WatchUi.SLIDE_IMMEDIATE);
            return true;
        }else{
            return false;
        }

        screens[screenIndex] = screen;
        settings.set(Settings.ID_DATASCREENS, screens as Settings.ValueType);
        return true;
    }
}