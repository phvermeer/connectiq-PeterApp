import Toybox.Lang;
import Toybox.WatchUi;

class BreadcrumpsMenu extends MyMenu{
    var settings as Settings;

    function initialize(delegate as MyMenuDelegate, settings as Settings){
        self.settings = settings;
        settings.addListener(self);

        MyMenu.initialize(delegate, {
            :title => WatchUi.loadResource(Rez.Strings.breadcrumps) as String,
            :focus => 0,
        });

        // create menu items for auto lap menu
        var ids = [
            Settings.ID_BREADCRUMPS, 
            Settings.ID_BREADCRUMPS_MAX_COUNT, 
            Settings.ID_BREADCRUMPS_MIN_DISTANCE
        ];

        for(var i=0; i<ids.size(); i++){
            var id = ids[i] as Settings.Id;
            var menuItem = createMenuItem(id);
            addItem(menuItem);
        }
    }

    hidden function createMenuItem(id as Settings.Id) as MenuItem{
        var title = getMenuItemTitle(id);

        // support different menu item types
        if(id == Settings.ID_BREADCRUMPS){
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
        if(id == Settings.ID_BREADCRUMPS){
            return WatchUi.loadResource(Rez.Strings.state) as String;
        }else if(id == Settings.ID_BREADCRUMPS_MAX_COUNT){
            return WatchUi.loadResource(Rez.Strings.maxCount) as String;
        }else if(id == Settings.ID_BREADCRUMPS_MIN_DISTANCE){
            return WatchUi.loadResource(Rez.Strings.betweenDistance) as String;
        }else{
            return "?";
        }
    }

    hidden function getSubLabel(id as Settings.Id) as String|Null{
        if(
            id == Settings.ID_BREADCRUMPS_MAX_COUNT ||
            id == Settings.ID_BREADCRUMPS_MIN_DISTANCE
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
        if(id == Settings.ID_BREADCRUMPS){
            return {
                false => WatchUi.loadResource(Rez.Strings.off) as String,
                true => WatchUi.loadResource(Rez.Strings.on) as String,
            };
        }else if(id == Settings.ID_BREADCRUMPS_MAX_COUNT){
            return {
                10 => "10",
                20 => "20",
                50 => "50",
                100 => "100",
                200 => "200",
            };
        }else if(id == Settings.ID_BREADCRUMPS_MIN_DISTANCE){
            return {
                10 => "10m",
                20 => "20m",
                50 => "50m",
                100 => "100m",
                200 => "200m",
                500 => "500m",
            };
        }else{
            return {};
        }
    }    

    // update changed values
    function onSetting(id as Settings.Id, value as Settings.ValueType) as Void{
        if(
            id == Settings.ID_BREADCRUMPS_MAX_COUNT ||
            id == Settings.ID_BREADCRUMPS_MIN_DISTANCE
        ){
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