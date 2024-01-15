import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Activity;
import MyBarrel.Drawables;
import MyBarrel.Layout;

//(:advanced)
class StatusField extends MyLabeledField{
    var gpsIndicator as GpsSignalIndicator;

    function initialize(options as {
        :locX as Numeric,
        :locY as Numeric,
        :width as Numeric,
        :height as Numeric,
        :darkMode as Boolean,
    }) {
        options.put(:label, WatchUi.loadResource(Rez.Strings.gps));
        MyLabeledField.initialize(options);
        gpsIndicator = new Drawables.GpsSignalIndicator({
            :darkMode => darkMode,
        });
    }
    function onLayout(dc as Dc) as Void{
        MyLabeledField.onLayout(dc);

        var margin = Math.ceil(0.02 * dc.getHeight()).toNumber();
        var helper = Layout.getLayoutHelper({
            :xMin => locX,
            :xMax => locX + width,
            :yMin => (label != null) ? label.locY + label.height : locY,
            :yMax => locY + height,
            :margin => margin,
        });
        gpsIndicator.setSize(1,1);
        helper.resizeToMax(gpsIndicator, true);
    }

    function onUpdate(dc as Dc) as Void{
        MyLabeledField.onUpdate(dc);
        gpsIndicator.draw(dc);
    }

    function onActivityInfo(info as Activity.Info) as Void{
        var quality = info.currentLocationAccuracy;
        if(quality != null && quality != gpsIndicator.quality){
            gpsIndicator.quality = quality;
            refresh();
        }
    }

    function setDarkMode(darkMode as Boolean) as Void{
        MyLabeledField.setDarkMode(darkMode);
        gpsIndicator.darkMode = darkMode;
    }
}