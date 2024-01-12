import Toybox.Lang;
import Toybox.WatchUi;
import MyBarrel.Views;

class LayoutPickerView extends DataView{
    hidden var settings as Settings;
    hidden var layoutId as Number;
    hidden var initialFields as Array<DataFieldId>;

    function initialize(screenIndex as Number, settings as Settings, delegate as MyViewDelegate){
        self.settings = settings;
        var screensSettings = settings.get(Settings.ID_DATASCREENS) as DataView.ScreensSettings;
        var screenSettings = screensSettings[screenIndex] as DataView.ScreenSettings;
        layoutId = screenSettings[DataView.SETTING_LAYOUT] as Number;
        initialFields = screenSettings[DataView.SETTING_FIELDS] as Array<DataFieldId>;

        DataView.initialize(screenIndex, screensSettings, delegate);
        log("LayoutPickerView initialized");
    }

    function onBack(sender as MyViewDelegate) as Boolean{
        // block original action to open stop view
        return false;
    }

    function onSwipe(sender as MyViewDelegate, swipeEvent as SwipeEvent) as Boolean{
        // swipe through all possible layouts
        var direction = swipeEvent.getDirection();
        if(direction == WatchUi.SWIPE_UP){
            // next
            layoutId = (layoutId < LAYOUT_MAX) ? layoutId + 1 : 0;
        }else if(direction == WatchUi.SWIPE_DOWN){
            // previous
            layoutId = (layoutId >0) ? layoutId - 1 : LAYOUT_MAX;
        }else{
            return false;
        }

        // update layout
        var layout = getLayoutById(layoutId as LayoutId);
        // adjust number of fields
        var fieldManager = $.getApp().fieldManager;
        for(var i=fields.size(); i<layout.size(); i++){
            fields.add(fieldManager.getField(DATAFIELD_EMPTY));
        }

        setFieldsLayout(layout);
        WatchUi.requestUpdate();
        return true;
    }

    function onTap(sender as MyViewDelegate, clickEvent as ClickEvent) as Boolean{
        saveLayout();
        return true;
    }
    function onKey(sender as MyViewDelegate, keyEvent as KeyEvent) as Boolean{
        saveLayout();
        return true;
    }

    hidden function saveLayout() as Void{
        var screenSettings = screensSettings[screenIndex] as DataView.ScreenSettings;
        // update layout id
        screenSettings[SETTING_LAYOUT] = layoutId as LayoutId;

        // update number of fields corresponding to layout
        var count = getLayoutById(layoutId as LayoutId).size();
        var fieldIds = initialFields.slice(null, count);
        while(fieldIds.size() < count){
            fieldIds.add(DATAFIELD_EMPTY);
        }
        screenSettings[SETTING_FIELDS] = fieldIds;

        // save settings
        screensSettings[screenIndex] = screenSettings;
        settings.set(Settings.ID_DATASCREENS, screensSettings);
    }
}