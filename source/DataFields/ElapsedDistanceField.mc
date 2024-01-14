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

    function onData(data as Data) as Void{
        var info = data.activityInfo;
        var value = (info != null) ? info.elapsedDistance : null;
        setValue(value);
    }
}