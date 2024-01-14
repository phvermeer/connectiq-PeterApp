import Toybox.Lang;
import Toybox.WatchUi;

class AutoLapMenu extends MyMenu{
    hidden var settings as Settings;

    function initialize(delegate as MyMenuDelegate, settings as Settings){
        self.settings = settings;
        settings.addListener(self);

        MyMenu.initialize(delegate, {
            :title => WatchUi.loadResource(Rez.Strings.autoLap) as String,
            :focus => 0,
        });

        // create menu items for auto lap menu
        var ids = [Settings.ID_AUTOLAP, Settings.ID_AUTOLAP_DISTANCE];
        for(var i=0; i<ids.size(); i++){
            var id = ids[i] as Settings.Id;
            var info = getOptionsInfo(id);
            var title = info.get(:title) as String;
            var values = info.get(:values) as Dictionary;

            if(id == Settings.ID_AUTOLAP){
                addItem(
                    new WatchUi.ToggleMenuItem(
                        title,
                        {
                            :enabled => values.get(true) as String,
                            :disabled => values.get(false) as String,
                        },
                        id,
                        settings.get(id) as Boolean, // screen enabled setting
                        {}
                    )
                );
            }else{
                addItem(
                    new WatchUi.MenuItem(
                        title,
                        values.get(settings.get(id) as Number) as String,
                        id,
                        {}
                    )
                );
            }
        }
    }

    function onSetting(id as Settings.Id, value as Settings.ValueType) as Void{
        if(id == Settings.ID_AUTOLAP_DISTANCE){
            var item = getItem(findItemById(id));
            if(item != null){
                var info = getOptionsInfo(id);
                var values = info.get(:values) as Dictionary;
                var label = values.get(value as Object) as String;
                item.setSubLabel(label);
            }
        }
    }

    static function getOptionsInfo(id as Settings.Id) as {
        :title as String,
        :values as Dictionary,
    }{
        if(id == Settings.ID_AUTOLAP){
            return{
                :title => WatchUi.loadResource(Rez.Strings.state) as String,
                :values => {
                    false => WatchUi.loadResource(Rez.Strings.off) as String,
                    true => WatchUi.loadResource(Rez.Strings.on) as String,
                }
            };
        }else if(id == Settings.ID_AUTOLAP_DISTANCE){
            return{
                :title => WatchUi.loadResource(Rez.Strings.distance) as String,
                :values => {
                    100 => "100m",
                    200 => "200m",
                    500 => "500m",
                    1000 => "1km",
                    2000 => "2km",		
                    5000 => "5km",		
                    10000 => "10km",		
                }
            };
        }else{
            return {};
        }
    }

	function onSelect(sender as MyMenuDelegate, item as MenuItem) as Boolean {
        var id = item.getId() as Settings.Id;
        if(id == Settings.ID_AUTOLAP){
            // save setting
            settings.set(id, (item as ToggleMenuItem).isEnabled());
        }else if(id == Settings.ID_AUTOLAP_DISTANCE){
            // open option menu
            var info = getOptionsInfo(id);
            var menu = new MyOptionsMenu(sender, settings, id, info);
            WatchUi.pushView(menu, sender, WatchUi.SLIDE_LEFT);
        }
		return true;
	}
}