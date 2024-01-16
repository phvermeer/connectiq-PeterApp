import Toybox.Lang;
import Toybox.WatchUi;
import MyBarrel.Views;

class FieldPickerView extends DataView{
    hidden var settings as Settings;

    function initialize(screenIndex as Number, settings as Settings, delegate as MyViewDelegate){
        self.settings = settings;
        var screensSettings = settings.get(Settings.ID_DATASCREENS) as DataView.ScreensSettings;
        DataView.initialize(screenIndex, screensSettings, delegate);
    }

    function onBack(sender as MyViewDelegate) as Boolean{
        // block original action to open stop view
        return false;
    }

    // disable swipe to next datascreen
    function onPreviousPage(sender as MyViewDelegate) as Boolean{
        return true;
    }
    function onNextPage(sender as MyViewDelegate) as Boolean{
        return true;
    }

    // (override DataView.onFieldTap) open FieldPickerMenu for selected field position 
    hidden function onFieldTap(clickEvent as ClickEvent, fieldIndex as Number, field as MyDataField) as Boolean{
        var delegate = new MyMenuDelegate();
        var menu = new FieldsMainMenu(delegate, settings, screenIndex, fieldIndex);
        WatchUi.pushView(menu, delegate, WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
    

}