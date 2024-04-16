import Toybox.Lang;
import Toybox.WatchUi;

class DataScreensMenu extends MyMenu{
    hidden var settings as Settings;

    function initialize(delegate as MyMenuDelegate, settings as Settings){
        self.settings = settings;
        MyMenu.initialize(delegate,{
            :title => WatchUi.loadResource(Rez.Strings.dataScreens) as String,
        });
    }

    function onShow(){
        MyMenu.onShow();
        updateItems();
    }

    hidden function updateItems() as Void{
        clearItems();
        var screens = settings.get(Settings.ID_DATASCREENS);

        if(screens instanceof Array){
            var txtScreen = WatchUi.loadResource(Rez.Strings.dataScreen) as String;
            for(var i=0; i<screens.size(); i++){
                var screen = screens[i] as DataView.ScreenSettings;
                var fieldIds = screen[DataView.SETTING_FIELDS] as Array;
                var fieldCount = fieldIds.size();
                var txtInfo = Lang.format("$1$ $2$", [
                    fieldCount, 
                    (fieldCount==1)
                        ? WatchUi.loadResource(Rez.Strings.dataField) as String
                        : WatchUi.loadResource(Rez.Strings.dataFields) as String
                ]);

                addItem(
                    new WatchUi.MenuItem(
                        Lang.format("$1$ $2$", [txtScreen, i+1]),
                        txtInfo,
                        i,
                        {}
                    )
                );
            }
            // item to add new screen
            var txtAdd = WatchUi.loadResource(Rez.Strings.add) as String;
            addItem(
                new WatchUi.MenuItem(
                    txtAdd,
                    null,
                    -1,
                    {}
                )
            );
        }
    }

    function onSelect(sender as MyMenuDelegate, item as MenuItem) as Boolean{
        var id = item.getId() as Number;
        if(id >= 0){
            // show menu for selected dataview
            var menu = new DataScreenMenu(id, settings, sender);
            WatchUi.pushView(menu, sender, WatchUi.SLIDE_IMMEDIATE);
        }else if(id == -1){
            // add new screen
            var screens = settings.get(Settings.ID_DATASCREENS) as DataView.ScreensSettings;
            var screensDefault = Settings.DEFAULT_VALUES[Settings.ID_DATASCREENS] as DataView.ScreensSettings;
            screens.add(screensDefault[0].slice(null, null)); // clone this, to avoid updating defaults
            settings.set(Settings.ID_DATASCREENS, screens);
            updateItems();
        }

        return true;
    }
}