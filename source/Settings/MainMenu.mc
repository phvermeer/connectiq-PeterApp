import Toybox.Lang;
import Toybox.WatchUi;

(:basic)
class MainMenu extends MyMenu{
    hidden var settings as Settings;

    function initialize(delegate as MyMenuDelegate, settings as Settings){
        self.settings = settings;
        settings.addListener(self);

        MyMenu.initialize(delegate, {
            :title => WatchUi.loadResource(Rez.Strings.settings) as String,
            :focus => 0,
        });

        // create menu items for main menu
		addItem(
			new WatchUi.MenuItem(
				WatchUi.loadResource(Rez.Strings.dataScreens) as String,
				null,
				Settings.ID_DATASCREENS,
				{}
			)
		);

        var ids = [Settings.ID_SPORT, Settings.ID_DARK_MODE, Settings.ID_AUTOPAUSE];
        for(var i=0; i<ids.size(); i++){
            var id = ids[i] as Settings.Id;
            var info = getOptionsInfo(id);
            var values = info.get(:values) as Dictionary;

            addItem(
                new WatchUi.MenuItem(
                    info.get(:title) as String,
                    values.get(settings.get(id) as Number) as String,
                    id,
                    {}
                )
            );
        }
    }

    // update shown values
    function onSetting(id as Settings.Id, value as Settings.ValueType) as Void{
        if(id == Settings.ID_SPORT || id == Settings.ID_DARK_MODE || id == Settings.ID_AUTOPAUSE){
            var item = getItem(findItemById(id));
            if(item != null){
                var info = getOptionsInfo(id);
                var values = info.get(:values) as Dictionary;
                var label = values.get(value as Object) as String;
                item.setSubLabel(label);
            }
        }
    }

    hidden function getOptionsInfo(id as Settings.Id) as {
        :title as String,
        :options as Dictionary,
    }{
        if(id == Settings.ID_SPORT){
            return {
                :title => WatchUi.loadResource(Rez.Strings.activity) as String,
                :values => {
                    Activity.SPORT_WALKING => WatchUi.loadResource(Rez.Strings.walking) as String,
                    Activity.SPORT_HIKING => WatchUi.loadResource(Rez.Strings.hiking) as String,
                    Activity.SPORT_RUNNING => WatchUi.loadResource(Rez.Strings.running) as String,
                    Activity.SPORT_CYCLING => WatchUi.loadResource(Rez.Strings.cycling) as String,
                }
            };
        }else if(id == Settings.ID_DARK_MODE){
            return {
                :title => WatchUi.loadResource(Rez.Strings.backgroundColor) as String,
                :values => {
                    false => WatchUi.loadResource(Rez.Strings.white) as String,
                    true => WatchUi.loadResource(Rez.Strings.black) as String,
                }
            };
        }else if(id == Settings.ID_AUTOPAUSE){
            return {
                :title => WatchUi.loadResource(Rez.Strings.autoPause) as String,
                :values => {
                    false => WatchUi.loadResource(Rez.Strings.off) as String,
                    true => WatchUi.loadResource(Rez.Strings.on) as String,
                }
            };
        }else{
            return {};
        }
    }

    function onSelect(sender as MyMenuDelegate, item as MenuItem) as Boolean{
        var id = item.getId() as Settings.Id;
        if(id == Settings.ID_DATASCREENS){
            var menu = new DataScreensMenu(sender, settings);
            WatchUi.pushView(menu, sender, WatchUi.SLIDE_LEFT);
        }else if(
            id == Settings.ID_SPORT || 
            id == Settings.ID_DARK_MODE ||
            id == Settings.ID_AUTOPAUSE
        ){
            var menu = new MyOptionsMenu(sender, settings, id, getOptionsInfo(id));
            WatchUi.pushView(menu, sender, WatchUi.SLIDE_LEFT);
        }else{
            log(id != null ? id.toString() : "---");
        }
        return true;
    }
}