import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Time.Gregorian;
import MyBarrel.Drawables;
using Toybox.Activity;

class TestField extends NumericField{
    hidden var counter as Number = 0;

    function initialize(options as {
        :locX as Numeric,
        :locY as Numeric,
        :width as Numeric,
        :height as Numeric,
    }) {
        options.put(:label, "counter");
        NumericField.initialize(options);
    }

    function onActivityInfo(info as Activity.Info) as Void{
        counter++;
        setValue(counter);
    }
}