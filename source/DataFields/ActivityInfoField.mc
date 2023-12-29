import Toybox.Lang;
import Toybox.Activity;
import Toybox.Graphics;
import Toybox.System;

class ActivityInfoField extends NumericField{


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
            = (fieldId == DATAFIELD_ELAPSED_TIME) ? WatchUi.loadResource(Rez.Strings.time)
            : (fieldId == DATAFIELD_CURRENT_SPEED) ? WatchUi.loadResource(Rez.Strings.speed)
            : (fieldId == DATAFIELD_AVG_SPEED) ? WatchUi.loadResource(Rez.Strings.avgSpeed)
            : (fieldId == DATAFIELD_MAX_SPEED) ? WatchUi.loadResource(Rez.Strings.maxSpeed)
            : (fieldId == DATAFIELD_ELAPSED_DISTANCE) ? WatchUi.loadResource(Rez.Strings.distance)
            : (fieldId == DATAFIELD_ALTITUDE) ? WatchUi.loadResource(Rez.Strings.altitude)
            : (fieldId == DATAFIELD_TOTAL_ASCENT) ? WatchUi.loadResource(Rez.Strings.totalAscent)
            : (fieldId == DATAFIELD_TOTAL_DESCENT) ? WatchUi.loadResource(Rez.Strings.totalDescent)
            : (fieldId == DATAFIELD_HEART_RATE) ? WatchUi.loadResource(Rez.Strings.heartRate)
            : (fieldId == DATAFIELD_AVG_HEARTRATE) ? WatchUi.loadResource(Rez.Strings.avgHeartRate)
            : (fieldId == DATAFIELD_MAX_HEARTRATE) ? WatchUi.loadResource(Rez.Strings.maxHeartRate)
            : (fieldId == DATAFIELD_OXYGEN_SATURATION) ? WatchUi.loadResource(Rez.Strings.oxygenSaturation)
            : (fieldId == DATAFIELD_ENERGY_RATE) ? WatchUi.loadResource(Rez.Strings.energyRate)
            : (fieldId == DATAFIELD_PRESSURE) ? WatchUi.loadResource(Rez.Strings.pressure)
            : (fieldId == DATAFIELD_SEALEVEL_PRESSURE) ? WatchUi.loadResource(Rez.Strings.seaLevelPressure)
            : (fieldId == DATAFIELD_CLOCK) ? WatchUi.loadResource(Rez.Strings.clock)
            : (fieldId == DATAFIELD_MEMORY) ? WatchUi.loadResource(Rez.Strings.memory)
            : (fieldId == DATAFIELD_BATTERY) ? WatchUi.loadResource(Rez.Strings.battery)
            : "???";

        options.put(:label, strLabel);
        NumericField.initialize(options);
    }

    function onData(data as Data) as Void{
        var info = data.activityInfo;
        var value
            = (info == null) ? null 
            : (fieldId == DATAFIELD_ELAPSED_TIME) ? formatTime(info.timerTime)
            : (fieldId == DATAFIELD_CURRENT_SPEED) ? toSpeedUnit(info.currentSpeed)
            : (fieldId == DATAFIELD_AVG_SPEED) ? toSpeedUnit(info.averageSpeed)
            : (fieldId == DATAFIELD_MAX_SPEED) ? toSpeedUnit(info.maxSpeed)
            : (fieldId == DATAFIELD_ELAPSED_DISTANCE) ? toDistanceUnit(info.elapsedDistance)
            : (fieldId == DATAFIELD_ALTITUDE) ? toHeightUnit(info.altitude)
            : (fieldId == DATAFIELD_TOTAL_ASCENT) ? toHeightUnit(info.totalAscent)
            : (fieldId == DATAFIELD_TOTAL_DESCENT) ? toHeightUnit(info.totalDescent)
            : (fieldId == DATAFIELD_HEART_RATE) ? info.currentHeartRate
            : (fieldId == DATAFIELD_AVG_HEARTRATE) ? info.averageHeartRate
            : (fieldId == DATAFIELD_MAX_HEARTRATE) ? info.maxHeartRate
            : (fieldId == DATAFIELD_OXYGEN_SATURATION) ? formatPercentage(info.currentOxygenSaturation)
            : (fieldId == DATAFIELD_ENERGY_RATE) ? info.energyExpenditure
            : (fieldId == DATAFIELD_PRESSURE) ? toPressureUnit(info.ambientPressure)
            : (fieldId == DATAFIELD_SEALEVEL_PRESSURE) ? toPressureUnit(info.meanSeaLevelPressure)

            // system stats
            : (fieldId == DATAFIELD_CLOCK) ? formatClock(System.getClockTime())
            : (fieldId == DATAFIELD_MEMORY) ? formatPercentage(100 * data.stats.usedMemory / data.stats.totalMemory)
            : (fieldId == DATAFIELD_BATTERY) ? formatPercentage(data.stats.battery)

            : null;

        setValue(value);
    }

    function toSpeedUnit(value as Numeric|Null) as Decimal|Null{
        if(value != null){
            // [m/s]
            if(ds.distanceUnits == System.UNIT_METRIC){
                return value * 3.6f; // [km/h]
            }else{
                return value / 0.44704f; // [mi/h]
            }
        }else{
            return null;
        }
    }

    static function toDistanceUnit(value as Numeric|Null) as Decimal|Null{
        if(value != null){ // [m]
            if(ds.distanceUnits == System.UNIT_METRIC){
                return value / 1000f; // [km]
            }else{
                return value / 1609.344f; // [mi];
            }
        }else{
            return null;
        }
    }

    static function formatTime(value as Numeric|Null) as String|Null{
        if(value != null){
            var seconds = (value / 1000).toNumber(); // msec => seconds
            var minutes = (seconds / 60).toNumber(); // seconds => minutes
            var hours = (minutes / 60).toNumber(); // minutes => hours
            if(hours == 0){
                value = Lang.format("$1$:$2$", [(minutes % 60).format("%02d"), (seconds % 60).format("%02d")]);
            }else{
                value = Lang.format("$1$:$2$", [hours, (minutes % 60).format("%02d")]);
            }
        }
        return value;
    }

    static function formatClock(value as ClockTime) as String{
        value = Lang.format("$1$:$2$", [value.hour.format("%02d"), value.min.format("%02d")]);
        return value;
    }


    static function toPressureUnit(value as Numeric|Null) as Decimal|Null{
        // Pa => mBar
        if(value != null){
            return (value / 100f);
        }else{
            return null;
        }
    }

    static function toHeightUnit(value as Numeric|Null) as Numeric|Null{
        if(value != null){
            // [m]
            if(ds.heightUnits == System.UNIT_STATUTE){
                // [feet]
                value /= 0.3048;
            }
        }
        return value;
    }

    static function formatPercentage(value as Numeric|Null) as String|Null{
        // xxx %
        if(value != null){
            return Math.round(value).format("%i") + "%";
        }else{
            return null;
        }
    }

    static function formatNumeric(value as Numeric|Null, digits as Number, maxLength as Number) as String|Null{
        if(value != null){
            // prevent "-" sign for 0f value
            if(value.toFloat() == 0f){
                value = 0;
            }

            // get number count in front of decimal separator
            var x = 1f;
            var count = 0;
            while(x <= value){
                count++;
                x *= 10;
            }

            if(count > maxLength){
                return value.format("%e");
            }else{
                if(digits <= 0){
                    return value.format("%i");
                }else{
                    var digitsMax = maxLength - count - 1; // excluding decimal character
                    var d = (digits > digitsMax) ? digitsMax : digits;
                    return value.format("%."+d+"f");
                }
            }
        }else{
            return null;
        }
    }
}