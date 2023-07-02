import Toybox.Lang;
import Toybox.Application;

class DataScreensSettings{
    var items as Array<DataScreenSettings>;

    function initialize(screensData as PropertyValueType){
        if(screensData instanceof Array){
            var screensData_ = screensData as Array;
            var count = screensData_.size();
            items = new Array<DataScreenSettings>[count];
            for(var i=0; i< count; i++){
                var screenData = screensData_[i];
                if(screenData instanceof Array){
                    items[i] = new DataScreenSettings(screenData as Array);
                }else{
                    throw new Lang.UnexpectedTypeException(Lang.format("Setting values for DataView[$1$] should be of type array", [i]), null, null);
                }
            }
        }else{
            throw new Lang.UnexpectedTypeException("Setting values for DataViews should be of type array", null, null);
        }
    }

    function removeScreen(index as Number) as Void{

    }

    function addScreen(screenSettings as DataScreenSettings?) as Void{
        if(screenSettings == null){
            // use default screen settings
            var defaultScreensData = Settings.DEFAULT_VALUES.get(SETTING_DATASCREENS);
            if(!(defaultScreensData instanceof Array)){
                throw new Lang.UnexpectedTypeException("The default screens settings should be of type Array", null, null);
            }
            var screenData = (defaultScreensData as Array)[0];
            if(!(screenData instanceof Array)){
                throw new Lang.UnexpectedTypeException("ScreenData should be an array (ScreenSettings)", null, null);
            }

            screenSettings = new DataScreenSettings(screenData as Array);
        }

        if(screenSettings != null){
            // Now add the screen settings
            items.add(screenSettings);
        }
    }

    function export() as PropertyValueType{
        var count = items.size();
        var data = new Array<Array>[items.size()];
        for(var i=0; i<count; i++){
            data[i] = items[i].export();
        }
        return data as PropertyValueType;
    }
}