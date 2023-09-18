import Toybox.Lang;
import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Math;

class AltitudeField extends MySimpleDataField{
    var calculator as Altitude.Calculator;


    function initialize(options as {
        :locX as Numeric,
        :locY as Numeric,
        :width as Numeric,
        :height as Numeric,
        :backgroundColor as ColorType,
    }){
        var strLabel = WatchUi.loadResource(Rez.Strings.altitude);
        options.put(:label, strLabel);
        MySimpleDataField.initialize(options);

        var settings = $.getApp().settings;
        var p0 = settings.get(SETTING_ALTITUDE_P0) as Float;
        var t0 = settings.get(SETTING_ALTITUDE_T0) as Float;
        calculator = new Altitude.Calculator(p0, t0);
    }

    function onTimer(){
        var info = Activity.getActivityInfo();
        if(info != null){
            var pressure = info.ambientPressure;
            if(pressure != null){
                var altitude = calculator.getAltitude(pressure);
                setValue(Math.round(altitude).toNumber());
            }else{
                setValue(null);
            }            
        }else{
            setValue(null);
        }
    }

    function onSetting(id, value){
        switch(id){
            case SETTING_ALTITUDE_P0:
                calculator.p0 = value as Float;
                break;
            case SETTING_ALTITUDE_T0:
                calculator.t0 = value as Float;
                break;
        }
    }
}