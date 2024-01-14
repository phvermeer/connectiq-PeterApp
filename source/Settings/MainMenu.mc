import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Activity;

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
        var ids = [
            Settings.ID_DATASCREENS,
            Settings.ID_SPORT,
            Settings.ID_DARK_MODE,
            Settings.ID_AUTOLAP,
            Settings.ID_AUTOPAUSE,
            Settings.ID_BREADCRUMPS,
            -1 // clear settings
        ];

        for(var i=0; i<ids.size(); i++){
            var id = ids[i] as Settings.Id|Number;
            var menuItem = createMenuItem(id);
            addItem(menuItem);
        }
    }

    hidden function createMenuItem(id as Number|Settings.Id) as MenuItem{
        var title = getMenuItemTitle(id);

        // support different menu item types
        if(id == Settings.ID_AUTOPAUSE){
            // ToggleMenuItem
            id = id as Settings.Id;
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
                getSubLabel(id as Settings.Id),
                id,
                {}
            );
        }
    }    

    hidden function getMenuItemTitle(id as Number|Settings.Id) as String{
        if(id == Settings.ID_DATASCREENS){
            return WatchUi.loadResource(Rez.Strings.dataScreens) as String;
        }else if(id == Settings.ID_SPORT){
            return WatchUi.loadResource(Rez.Strings.activity) as String;
        }else if(id == Settings.ID_DARK_MODE){
            return WatchUi.loadResource(Rez.Strings.backgroundColor) as String;
        }else if(id == Settings.ID_AUTOPAUSE){
            return WatchUi.loadResource(Rez.Strings.autoPause) as String;
        }else if(id == Settings.ID_AUTOLAP){
            return WatchUi.loadResource(Rez.Strings.autoLap) as String;
        }else if(id == Settings.ID_BREADCRUMPS){
            return WatchUi.loadResource(Rez.Strings.breadcrumps) as String;
        }else if(id == -1){
            return WatchUi.loadResource(Rez.Strings.clearSettings) as String;
        }else{
            return "?";
        }
    }

    hidden function getSubLabel(id as Settings.Id) as String|Null{
        if(id == Settings.ID_DARK_MODE || id == Settings.ID_SPORT || id == Settings.ID_AUTOPAUSE){
            // generic value to text translation
            var value = settings.get(id) as Number|Boolean;
            var textValues = getTextValues(id);
            return textValues.get(value) as String;           

        }else if(id == Settings.ID_AUTOLAP){
            var enabled = settings.get(Settings.ID_AUTOLAP) as Boolean;
            if(enabled){
                var distance = settings.get(Settings.ID_AUTOLAP_DISTANCE) as Number;
                var textValues = AutoLapMenu.getTextValues(Settings.ID_AUTOLAP_DISTANCE);
                return textValues.get(distance) as String;
            }else{
                var textValues = AutoLapMenu.getTextValues(Settings.ID_AUTOLAP);
                return textValues.get(enabled) as String;
            }

        }else if(id == Settings.ID_BREADCRUMPS){
            var enabled = settings.get(Settings.ID_BREADCRUMPS) as Boolean;
            if(enabled){
                var count = settings.get(Settings.ID_BREADCRUMPS_MAX_COUNT) as Number;
                var distance = settings.get(Settings.ID_BREADCRUMPS_MIN_DISTANCE) as Number;
                var textCounts = BreadcrumpsMenu.getTextValues(Settings.ID_BREADCRUMPS_MAX_COUNT);
                var textDistances = BreadcrumpsMenu.getTextValues(Settings.ID_BREADCRUMPS_MIN_DISTANCE);
                return Lang.format("$1$ x $2$",[textCounts.get(count) as String, textDistances.get(distance) as String]);
            }else{
                var textValues = BreadcrumpsMenu.getTextValues(Settings.ID_BREADCRUMPS);
                return textValues.get(enabled) as String;
            }

        }else{
            return null;
        }
    }

    static function getTextValues(id as Settings.Id) as Dictionary{
        if(id == Settings.ID_SPORT){
            return {
                Activity.SPORT_WALKING => WatchUi.loadResource(Rez.Strings.walking) as String,
                Activity.SPORT_HIKING => WatchUi.loadResource(Rez.Strings.hiking) as String,
                Activity.SPORT_RUNNING => WatchUi.loadResource(Rez.Strings.running) as String,
                Activity.SPORT_CYCLING => WatchUi.loadResource(Rez.Strings.cycling) as String,
            };
        }else if(id == Settings.ID_DARK_MODE){
            return {
                true => WatchUi.loadResource(Rez.Strings.black) as String,
                false => WatchUi.loadResource(Rez.Strings.white) as String,
            };
        }else if(id == Settings.ID_AUTOPAUSE){
            return {
                false => WatchUi.loadResource(Rez.Strings.off) as String,
                true => WatchUi.loadResource(Rez.Strings.on) as String,
            };
        }else{
            return {};
        }
    }    

    // update changed values
    function onSetting(id as Settings.Id, value as Settings.ValueType) as Void{
        if(
            id == Settings.ID_SPORT || 
            id == Settings.ID_DARK_MODE ||
            id == Settings.ID_AUTOLAP || id == Settings.ID_AUTOLAP_DISTANCE ||
            id == Settings.ID_AUTOPAUSE ||
            id == Settings.ID_BREADCRUMPS || id == Settings.ID_BREADCRUMPS_MAX_COUNT || id == Settings.ID_BREADCRUMPS_MIN_DISTANCE
        ){
            if(id == Settings.ID_AUTOLAP_DISTANCE){
                id = Settings.ID_AUTOLAP;
            }else if(id == Settings.ID_BREADCRUMPS_MAX_COUNT || id == Settings.ID_BREADCRUMPS_MIN_DISTANCE){
                id = Settings.ID_BREADCRUMPS;
            }
            var item = getItem(findItemById(id));
            if(item != null){
                var subLabel = getSubLabel(id);
                item.setSubLabel(subLabel);
            }
        }
        
        if(id == Settings.ID_SPORT){
            // sport is changed => update all values for new profile
            var ids = [
                Settings.ID_DARK_MODE, 
                Settings.ID_AUTOPAUSE, 
                Settings.ID_AUTOLAP, 
                Settings.ID_BREADCRUMPS
            ];
            for(var i=0; i<ids.size(); i++){
                id = ids[i] as Settings.Id;
                onSetting(id, settings.get(id));
            }
        }
    }

    function onSelect(sender as MyMenuDelegate, item as MenuItem) as Boolean{
        var id = item.getId() as Settings.Id;
        if(item instanceof ToggleMenuItem){
            // save value from toggle menu item
            settings.set(id, (item as ToggleMenuItem).isEnabled());
        }else if(id == Settings.ID_DATASCREENS){
            // open menu with all datascreen settings
            var menu = new DataScreensMenu(sender, settings);
            WatchUi.pushView(menu, sender, WatchUi.SLIDE_LEFT);
        }else if(id == Settings.ID_AUTOLAP){
            var menu = new AutoLapMenu(sender, settings);
            WatchUi.pushView(menu, sender, WatchUi.SLIDE_LEFT);
        }else if(id == Settings.ID_BREADCRUMPS){
            var menu = new BreadcrumpsMenu(sender, settings);
            WatchUi.pushView(menu, sender, WatchUi.SLIDE_LEFT);
        }else if(
            id == Settings.ID_SPORT || id == Settings.ID_DARK_MODE
        ){
            // open menu with options
            var title = getMenuItemTitle(id);
            var textValues = getTextValues(id);
            var menu = new MyOptionsMenu(sender, settings, id, title, textValues);
            WatchUi.pushView(menu, sender, WatchUi.SLIDE_LEFT);
        }else if(id == -1){
            // clear settings
            settings.clear();
        }else if(id == -2){
            // clear track
            $.getApp().track = null;
        }else{
            throw new MyException("unhandled onSelect event");
        }
        return true;
    }

}