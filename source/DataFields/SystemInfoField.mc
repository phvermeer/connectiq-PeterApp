import Toybox.Lang;
import Toybox.Activity;
import Toybox.Graphics;
import Toybox.System;

class SystemInfoField extends MySimpleDataField{
    hidden var fieldId as DataFieldId;

    function initialize(fieldId as DataFieldId, options as {
        :locX as Numeric,
        :locY as Numeric,
        :width as Numeric,
        :height as Numeric,
        :backgroundColor as ColorType,
    }){
        self.fieldId = fieldId;

        // determine the label
        var strLabel
            = (fieldId == DATAFIELD_CLOCK) ? WatchUi.loadResource(Rez.Strings.clock)
            : (fieldId == DATAFIELD_MEMORY) ? WatchUi.loadResource(Rez.Strings.memory)
            : (fieldId == DATAFIELD_BATTERY) ? WatchUi.loadResource(Rez.Strings.battery)
            : "???";

        options.put(:label, strLabel);
        MySimpleDataField.initialize(options);
        onTimer();
    }

    function onTimer() as Void{
        var stats = System.getSystemStats();
        var info = Activity.getActivityInfo();
        if(info != null){
            var value
                = (fieldId == DATAFIELD_CLOCK) ? formatClock(System.getClockTime())
                : (fieldId == DATAFIELD_MEMORY) ? formatPercentage(100 * stats.usedMemory / stats.totalMemory)
                : (fieldId == DATAFIELD_BATTERY) ? formatPercentage(stats.battery)
                : null;

            setValue(value);
        }else{
            setValue(null);
        }
    }

    static function formatClock(value as ClockTime) as String{
        value = Lang.format("$1$:$2$", [value.hour.format("%02d"), value.min.format("%02d")]);
        return value;
    }

    static function formatPercentage(value as Numeric) as String{
        // 0 % - 100 %
        value = Lang.format("$1$%", [Math.round(value).format("%d")]);
        return value;
    }
}