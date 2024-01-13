import Toybox.Lang;
import Toybox.WatchUi;


(:basic)
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
                addItem(
                    new WatchUi.MenuItem(
                        Lang.format("$1$ $2$", [txtScreen, i+1]),
                        null,
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
        }

        return true;
    }

}