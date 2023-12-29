import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Time.Gregorian;
import MyTools;
import MyDrawables;

class TestField extends NumericField{
    hidden var v as Float = 0.666666666f;

    function initialize(options as {
        :locX as Numeric,
        :locY as Numeric,
        :width as Numeric,
        :height as Numeric,
    }) {
        options.put(:label, "next lap");
        NumericField.initialize(options);
    }
/*
    function onData(data as Data){
        updateValue();
    }
    function onSetting(id as SettingId, value as Settings.ValueType) as Void{
        if(id == SETTING_AUTOLAP || id == SETTING_AUTOLAP_DISTANCE){
            updateValue();
        }
    }

    hidden function updateValue() as Void{
        // auto lap test data
        var session = $.getApp().session;
        var enabled = session.mAutoLapEnabled;
        if(!enabled){
            setValue(null);
        }else{
            var lapStartedAt = session.mLastLapDistance;
            var lapDistance = session.mAutoLapDistance;
            var lapEndsAt = lapStartedAt + lapDistance;
            setValue(lapEndsAt/1000f);
        }
    }
*/
    function onTap(clickEvent as ClickEvent) as Boolean{
        v *= 10;
        value.text = formatDecimal(v, 2, 5);
        return true;
    }
}