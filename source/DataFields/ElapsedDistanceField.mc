import Toybox.Lang;
import Toybox.Activity;
import Toybox.Graphics;

class ElapsedDistanceField extends MySimpleDataField{

    function initialize(options as {
        :locX as Numeric,
        :locY as Numeric,
        :width as Numeric,
        :height as Numeric,
        :backgroundColor as ColorType,
    }){
        var strLabel = WatchUi.loadResource(Rez.Strings.distance);
        options.put(:label, strLabel);
        MySimpleDataField.initialize(options);
    }

    function onTimer(){
        var info = Activity.getActivityInfo();
        if(info != null){
            var distance = info.elapsedDistance;
            if(distance != null){
                setValue(distance/1000);
            }else{
                setValue(null);
            }            
        }else{
            setValue(null);
        }
    }
}