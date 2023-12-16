import Toybox.Lang;
import Toybox.Application;
/*
class DataScreensSettings{
    var items as Array<DataScreenSettings>;

    function initialize(screensData as Array){
        var screensData_ = screensData as Array;
        var count = screensData_.size();
        items = new Array<DataScreenSettings>[count];
        for(var i=0; i<count; i++){
            var screenData = screensData_[i];
            if(screenData instanceof Array){
                items[i] = new DataScreenSettings(screenData as Array);
            }else{
                throw new MyTools.MyException(Lang.format("Setting values for DataView[$1$] should be of type array", [i]));
            }
        }
    }

    function removeScreen(index as Number) as Void{
        var lastIndex = items.size()-1;
        // keep items before selected item
        var itemsUpdated = (index>0) ? items.slice(0,index) : [] as Array<DataScreenSettings>;
        // keep items after selected item
        if(index<lastIndex){
            itemsUpdated.addAll(items.slice(index+1, null));
        }
        items = itemsUpdated;
    }

    function addScreen(screenSettings as DataScreenSettings?) as Void{
        if(screenSettings == null){
            // use default screen settings
            var defaultScreensData = Settings.DEFAULT_VALUES.get(SETTING_DATASCREENS);
            if(!(defaultScreensData instanceof Array)){
                throw new MyTools.MyException("The default screens settings should be of type Array");
            }
            var screenData = (defaultScreensData as Array)[0];
            if(!(screenData instanceof Array)){
                throw new MyTools.MyException("ScreenData should be an array (ScreenSettings)");
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
*/