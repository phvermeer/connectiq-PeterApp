import Toybox.Lang;
import Toybox.Activity;
import Toybox.Graphics;
import Toybox.System;

// (:advanced)
class SystemStatsField extends NumericField{

    hidden var fieldId as DataFieldId;
    hidden static var ds as System.DeviceSettings;

    function initialize(fieldId as DataFieldId, options as {
        :locX as Numeric,
        :locY as Numeric,
        :width as Numeric,
        :height as Numeric,
        :backgroundColor as ColorType,
    }){
        self.fieldId = fieldId;
        self.ds = System.getDeviceSettings();

        // determine the label
        var strLabel
            = (fieldId == DATAFIELD_CLOCK) ? WatchUi.loadResource(Rez.Strings.clock)
            : (fieldId == DATAFIELD_MEMORY) ? WatchUi.loadResource(Rez.Strings.memory)
            : (fieldId == DATAFIELD_BATTERY) ? WatchUi.loadResource(Rez.Strings.battery)
            : "???";

        options.put(:label, strLabel);
        NumericField.initialize(options);
    }

    function onSystemStats(stats as System.Stats) as Void{
        var value
            = (fieldId == DATAFIELD_CLOCK) ? formatClock(System.getClockTime())
            : (fieldId == DATAFIELD_MEMORY) ? formatPercentage(100f * stats.usedMemory / stats.totalMemory)
            : (fieldId == DATAFIELD_BATTERY) ? formatPercentage(stats.battery)
            : null;

        setValue(value);
    }

    static function formatClock(value as ClockTime) as String{
        value = Lang.format("$1$:$2$", [value.hour.format("%d"), value.min.format("%02d")]);
        return value;
    }

    static function formatPercentage(value as Numeric|Null) as String|Null{
        // xxx %
        if(value != null){
            if(value instanceof Float){
                return value.format("%.1f") + "%";
            }else{
                return value.format("%i") + "%";
            }
        }else{
            return null;
        }
    }
}