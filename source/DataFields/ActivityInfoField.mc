import Toybox.Lang;
import Toybox.Activity;
import Toybox.Graphics;
import Toybox.System;

class ActivityInfoField extends MySimpleDataField{


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
/*
        // determine unit of measurement
        units = (
            fieldId == DATAFIELD_ALTITUDE |||
            fieldId == DATAFIELD_TOTAL_ASCENT ||
            fieldId == DATAFIELD_TOTAL_DESCENT
        )   
            ? ds.heightUnits
            : ds.distanceUnits;
*/
        options.put(:label, strLabel);
        MySimpleDataField.initialize(options);
    }

    function onData(data as Data) as Void{
        var info = data.activityInfo;
        var value
            = (info == null) ? null
            : (fieldId == DATAFIELD_ELAPSED_TIME) ? formatTime(info.timerTime)
            : (fieldId == DATAFIELD_CURRENT_SPEED) ? formatNumeric(toSpeedUnit(info.currentSpeed), 1, 5)
            : (fieldId == DATAFIELD_AVG_SPEED) ? formatNumeric(toSpeedUnit(info.averageSpeed), 1, 5)
            : (fieldId == DATAFIELD_MAX_SPEED) ? formatNumeric(toSpeedUnit(info.maxSpeed), 1, 5)
            : (fieldId == DATAFIELD_ELAPSED_DISTANCE) ? formatNumeric(toDistanceUnit(info.elapsedDistance), 2, 5)
            : (fieldId == DATAFIELD_ALTITUDE) ? formatNumeric(toHeightUnit(info.altitude), 0, 5)
            : (fieldId == DATAFIELD_TOTAL_ASCENT) ? formatNumeric(toHeightUnit(info.totalAscent), 0, 5)
            : (fieldId == DATAFIELD_TOTAL_DESCENT) ? formatNumeric(toHeightUnit(info.totalDescent), 0, 5)
            : (fieldId == DATAFIELD_HEART_RATE) ? formatNumeric(info.currentHeartRate, 0, 5)
            : (fieldId == DATAFIELD_AVG_HEARTRATE) ? formatNumeric(info.averageHeartRate, 0, 5)
            : (fieldId == DATAFIELD_MAX_HEARTRATE) ? formatNumeric(info.maxHeartRate, 0, 5)
            : (fieldId == DATAFIELD_OXYGEN_SATURATION) ? formatPercentage(info.currentOxygenSaturation)
            : (fieldId == DATAFIELD_ENERGY_RATE) ? formatNumeric(info.energyExpenditure, 2, 5)
            : (fieldId == DATAFIELD_PRESSURE) ? formatNumeric(toPressureUnit(info.ambientPressure), 0, 5)
            : (fieldId == DATAFIELD_SEALEVEL_PRESSURE) ? formatNumeric(toPressureUnit(info.meanSeaLevelPressure), 0, 5)

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