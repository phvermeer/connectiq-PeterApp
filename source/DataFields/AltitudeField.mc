import Toybox.Lang;
import Toybox.Activity;
import Toybox.Graphics;

class AltitudeField extends MySimpleDataField{
    var calculator as Altitude.Calculator?;

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
        var calibrated = settings.get(SETTING_ALTITUDE_CALIBRATED) as Boolean;
        setCalibrated(calibrated);
    }

    hidden function setCalibrated(calibrated as Boolean) as Void{
        var calibratedOld = (calculator != null);

        if(calibrated != calibratedOld){
            if(calibrated){
                var settings = $.getApp().settings;
                var p0 = settings.get(SETTING_ALTITUDE_P0) as Float;
                var t0 = settings.get(SETTING_ALTITUDE_T0) as Float;
                calculator = new Altitude.Calculator(p0, t0);
            }else{
                calculator = null;
            }
        }
    }

    function onActivityInfo(info as Activity.Info){
        var altitude = null;
        if(calculator != null){
            // calibrated altitude value (using air pressure)
            var pressure = info.ambientPressure;
            if(pressure != null){
                altitude = calculator.calculateAltitude(pressure);
            }
        }else{
            // standard altitude value
            altitude = info.altitude;
        }

        // round to whole number
        if(altitude != null){
            altitude = altitude.toNumber();
        }        
        setValue(altitude);
    }

    function onSetting(id, value){
        if(id == SETTING_ALTITUDE_CALIBRATED){
            setCalibrated(value as Boolean);
        }else if(calculator != null){
            if(id == SETTING_ALTITUDE_P0){
                calculator.p0 = value as Float;
            }else if(id == SETTING_ALTITUDE_T0){
                calculator.t0 = value as Float;
            }
        }
    }
}