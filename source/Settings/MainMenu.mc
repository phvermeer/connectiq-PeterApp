import Toybox.Lang;
import Toybox.WatchUi;

(:basic)
class MainMenu extends MyMenu{
    hidden var settings as Settings;

    enum MenuId {
        ID_SCREENS = 0,
        ID_SPORT = 1,
        ID_BACKGROUND = 2,
    }

    function initialize(delegate as MyMenuDelegate, settings as Settings){
        self.settings = settings;

        MyMenu.initialize(delegate, {
            :title => WatchUi.loadResource(Rez.Strings.settings) as String,
            :focus => 0,
        });

        // create menu items for main menu
		addItem(
			new WatchUi.MenuItem(
				WatchUi.loadResource(Rez.Strings.dataScreens) as String,
				null,
				ID_SCREENS,
				{}
			)
		);

		addItem( // index 1
			new WatchUi.MenuItem(
				WatchUi.loadResource(Rez.Strings.activity) as String,
				null,
				ID_SPORT,
				{}
			)
		);

		addItem(// index 3
			new WatchUi.MenuItem(
				WatchUi.loadResource(Rez.Strings.backgroundColor) as String,
				null,
				ID_BACKGROUND,
				{}
			)
		);
    }

    function onSelect(sender as MyMenuDelegate, item as MenuItem) as Boolean{
        var id = item.getId();
        if(id == ID_SCREENS){
            var menu = new DataScreensMenu(settings, sender);
            WatchUi.pushView(menu, sender, WatchUi.SLIDE_LEFT);
        }else{
            log(id != null ? id.toString() : "---");
        }
        return true;
    }
}