import Toybox.Lang;
import Toybox.Activity;
import Toybox.Graphics;

class ElapsedDistanceField extends NumericField{
    function initialize(options as {
        :locX as Numeric,
        :locY as Numeric,
        :width as Numeric,
        :height as Numeric,
        :backgroundColor as ColorType,
    }){
        options.put(:label, WatchUi.loadResource(Rez.Strings.distance) as String);
        NumericField.initialize(options);
    }

    function onActivityInfo(info as Activity.Info) as Void{
        var value = info.elapsedDistance;
        setValue(value);
    }
}