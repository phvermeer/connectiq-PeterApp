import Toybox.Lang;
import Toybox.Activity;
import Toybox.Graphics;

class ActivityInfoField extends MySimpleDataField{
    enum FormatId {
        FORMAT_NONE = -1,
        FORMAT_SPEED = 0,
        FORMAT_DISTANCE = 1,
        FORMAT_TIME = 2,
        FORMAT_PRESSURE = 3,
        FORMAT_ALTITUDE = 4,
        FORMAT_PERCENTAGE = 5,
    }

    hidden var fieldId as DataFieldId;
    hidden var formatId as FormatId = FORMAT_NONE;

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
            : (fieldId == DATAFIELD_SEALEVEL_PRESSURE) ? WatchUi.loadResource(Rez.Strings.pressure)
            : "???";

        // determin the formatter
        if(
            // speed
            fieldId == DATAFIELD_CURRENT_SPEED ||
            fieldId == DATAFIELD_AVG_SPEED ||
            fieldId == DATAFIELD_MAX_SPEED
        ){
            formatId = FORMAT_SPEED;
        }else if(
            // distance
            fieldId == DATAFIELD_ELAPSED_DISTANCE
        ){
            formatId = FORMAT_DISTANCE;
        }else if(
            // time
            fieldId == DATAFIELD_ELAPSED_TIME
        ){
            formatId = FORMAT_TIME;
        }else if(
            // pressure
            fieldId == DATAFIELD_PRESSURE ||
            fieldId == DATAFIELD_SEALEVEL_PRESSURE
        ){
            formatId = FORMAT_PRESSURE;
        }else if(
            // altitude
            fieldId == DATAFIELD_ALTITUDE ||
            fieldId == DATAFIELD_TOTAL_ASCENT ||
            fieldId == DATAFIELD_TOTAL_DESCENT
        ){
            formatId = FORMAT_ALTITUDE;
        }else if(
            // percentage
            fieldId == DATAFIELD_OXYGEN_SATURATION
        ){
            formatId = FORMAT_PERCENTAGE;
        }

        options.put(:label, strLabel);
        MySimpleDataField.initialize(options);
        onTimer();
    }

    function onTimer() as Void{
        var info = Activity.getActivityInfo();
        if(info != null){
            var value
                = (fieldId == DATAFIELD_ELAPSED_TIME) ? info.timerTime
                : (fieldId == DATAFIELD_CURRENT_SPEED) ? info.currentSpeed
                : (fieldId == DATAFIELD_AVG_SPEED) ? info.averageSpeed
                : (fieldId == DATAFIELD_MAX_SPEED) ? info.maxSpeed
                : (fieldId == DATAFIELD_ELAPSED_DISTANCE) ? info.elapsedDistance
                : (fieldId == DATAFIELD_ALTITUDE) ? info.altitude
                : (fieldId == DATAFIELD_TOTAL_ASCENT) ? info.totalAscent
                : (fieldId == DATAFIELD_TOTAL_DESCENT) ? info.totalDescent
                : (fieldId == DATAFIELD_HEART_RATE) ? info.currentHeartRate
                : (fieldId == DATAFIELD_AVG_HEARTRATE) ? info.averageHeartRate
                : (fieldId == DATAFIELD_MAX_HEARTRATE) ? info.maxHeartRate
                : (fieldId == DATAFIELD_OXYGEN_SATURATION) ? info.currentOxygenSaturation
                : (fieldId == DATAFIELD_ENERGY_RATE) ? info.energyExpenditure
                : (fieldId == DATAFIELD_PRESSURE) ? info.ambientPressure
                : (fieldId == DATAFIELD_SEALEVEL_PRESSURE) ? info.meanSeaLevelPressure
                : null;

            setValue(format(value, formatId));
        }else{
            setValue(null);
        }
    }

    function format(value as Numeric|Null, formatId as FormatId) as Numeric|Null|String{
        var formatters = [
            :formatSpeed,
            :formatDistance,
            :formatTime,
            :formatPressure,
            :formatAltitude,
            :formatPercentage,
        ];
        if(formatId>=0 && formatId < formatters.size()){
            var formatter = method(formatters[formatId as Number] as Symbol) as (Method(value as Numeric|Null) as Numeric|Null|String);
            return formatter.invoke(value);
        }else{
            return value;
        }
    }

    static function formatSpeed(value as Numeric|Null) as Numeric|Null{
        if(value != null){
            value *= 3.6f;
        }
        return value;
    }

    static function formatDistance(value as Numeric|Null) as Numeric|Null{
        if(value != null){
            value /= 1000;
        }
        return value;
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

    static function formatPressure(value as Numeric|Null) as Float|Number|Null{
        // Pa => mBar
        if(value != null){
            value = value.toFloat(); //(value / 100).toNumber();
        }
        return value;
    }

    static function formatAltitude(value as Numeric|Null) as Number|Null{
        // m (no digits)
        if(value != null){
            value = value.toNumber();
        }
        return value;
    }

    static function formatPercentage(value as Numeric|Null) as String|Null{
        // xxx %
        if(value != null){
            value = Lang.format("$1$%", [Math.round(value).format("%d")]);
        }
        return value;
    }

}