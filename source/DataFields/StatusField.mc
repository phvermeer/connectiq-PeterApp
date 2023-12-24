import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;
import MyTools;
import MyDrawables;

class StatusField extends MyDataField{
    var gpsIndicator as SignalIndicator;    

    function initialize(options as {
        :locX as Numeric,
        :locY as Numeric,
        :width as Numeric,
        :height as Numeric,
        :darkMode as Boolean,
    }) {
        MyDataField.initialize(options);
        gpsIndicator = new MyDrawables.SignalIndicator({
            :darkMode => darkMode,
            :width => 32,
            :height => 32,
        });

        onData($.getApp().data);
    }
    function onLayout(dc){
        var margin = Math.ceil(0.05 * dc.getHeight()).toNumber();
        var helper = MyLayoutHelper.getLayoutHelper({
            :xMin => locX,
            :xMax => locX + width,
            :yMin => locY,
            :yMax => locY + height,
            :margin => margin,
        });

        helper.resizeToMax(gpsIndicator, true);
    }

    function onUpdate(dc){
        gpsIndicator.draw(dc);
    }

    function onData(data as Data){
        var accuracy = data.positionInfo.accuracy;
        
        var signalLevel = (accuracy == Position.QUALITY_GOOD) ? SignalIndicator.SIGNAL_GOOD
            : (accuracy == Position.QUALITY_USABLE) ? SignalIndicator.SIGNAL_FAIR
            : (accuracy == Position.QUALITY_POOR) ? SignalIndicator.SIGNAL_POOR
            : SignalIndicator.SIGNAL_NONE;
        gpsIndicator.level = signalLevel;
    }

    function setDarkMode(darkMode as Boolean) as Void{
        MyDataField.setDarkMode(darkMode);
        gpsIndicator.darkMode = darkMode;
    }
}