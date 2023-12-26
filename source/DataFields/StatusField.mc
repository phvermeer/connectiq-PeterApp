import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;
import MyTools;
import MyDrawables;

class StatusField extends MySimpleDataField{
    var gpsIndicator as GpsSignalIndicator;

    function initialize(options as {
        :locX as Numeric,
        :locY as Numeric,
        :width as Numeric,
        :height as Numeric,
        :darkMode as Boolean,
    }) {
        options.put(:label, WatchUi.loadResource(Rez.Strings.gps));
        MySimpleDataField.initialize(options);
        gpsIndicator = new MyDrawables.GpsSignalIndicator({
            :darkMode => darkMode,
        });

        onData($.getApp().data);
    }
    function onLayout(dc as Dc) as Void{
        MySimpleDataField.onLayout(dc);

        var margin = Math.ceil(0.02 * dc.getHeight()).toNumber();
        var helper = MyLayoutHelper.getLayoutHelper({
            :xMin => locX,
            :xMax => locX + width,
            :yMin => label.locY + label.height,
            :yMax => locY + height,
            :margin => margin,
        });
        gpsIndicator.setSize(1,1);
        helper.resizeToMax(gpsIndicator, true);
    }

    function onUpdate(dc as Dc) as Void{
        label.draw(dc);
        gpsIndicator.draw(dc);
    }

    function onData(data as Data){
        var quality = data.positionInfo.accuracy;
        if(quality != gpsIndicator.quality){
            gpsIndicator.quality = quality;
            refresh();
        }
    }

    function setDarkMode(darkMode as Boolean) as Void{
        MyDataField.setDarkMode(darkMode);
        gpsIndicator.darkMode = darkMode;
    }
}