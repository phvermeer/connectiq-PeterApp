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
            var menuItem = createMenuItem(id);
            addItem(menuItem);
        }
    }

    hidden function createMenuItem(id as Settings.Id) as MenuItem{
        var title = getMenuItemTitle(id);

        // support different menu item types
        if(id == Settings.ID_AUTOLAP){
            // ToggleMenuItem
            var value = settings.get(id) as Boolean;
            var textValues = getTextValues(id);
            return new ToggleMenuItem(
                title,
                {
                    :enabled => textValues.get(true) as String,
                    :disabled => textValues.get(false) as String,
                },
                id,
                value, // current state
                {}
            );
        }else{
            // MenuItem
       		return new WatchUi.MenuItem(
                title,
                getSubLabel(id),
                id,
                {}
            );
        }
    }    

    hidden function getMenuItemTitle(id as Number|Settings.Id) as String{
        if(id == Settings.ID_AUTOLAP){
            return WatchUi.loadResource(Rez.Strings.state) as String;
        }else if(id == Settings.ID_AUTOLAP_DISTANCE){
            return WatchUi.loadResource(Rez.Strings.distance) as String;
        }else{
            return "?";
        }
    }

    hidden function getSubLabel(id as Settings.Id) as String|Null{
        if(
            id == Settings.ID_AUTOLAP_DISTANCE
        ){
            // generic value to text translation
            var value = settings.get(id) as Number|Boolean;
            var textValues = getTextValues(id);
            return textValues.get(value) as String;
        }else{
            return null;
        }
    }

    static function getTextValues(id as Settings.Id) as Dictionary{
        if(id == Settings.ID_AUTOLAP){
            return {
                false => WatchUi.loadResource(Rez.Strings.off) as String,
                true => WatchUi.loadResource(Rez.Strings.on) as String,
            };
        }else if(id == Settings.ID_AUTOLAP_DISTANCE){
            return {
                100 => "100m",
                200 => "200m",
                500 => "500m",
                1000 => "1km",
                2000 => "2km",
                5000 => "5km",
                10000 => "10km",
            };
        }else{
            return {};
        }
    }    

    // update changed values
    function onSetting(sender as Object, id as Settings.Id, value as Settings.ValueType) as Void{
        if(id == Settings.ID_AUTOLAP_DISTANCE){
            var item = getItem(findItemById(id));
            if(item != null){
                var subLabel = getSubLabel(id);
                item.setSubLabel(subLabel);
            }
        }
    }

    function onSelect(sender as MyMenuDelegate, item as MenuItem) as Boolean{
        var id = item.getId() as Settings.Id;
        if(item instanceof ToggleMenuItem){
            // save value from toggle
            settings.set(id, (item as ToggleMenuItem).isEnabled());
        }else{
            // open menu with options
            var title = getMenuItemTitle(id);
            var textValues = getTextValues(id);
            var menu = new MyOptionsMenu(sender, settings, id, title, textValues);
            WatchUi.pushView(menu, sender, WatchUi.SLIDE_LEFT);
        }
        return true;
    }
}