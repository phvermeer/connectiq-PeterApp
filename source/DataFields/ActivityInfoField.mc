import Toybox.Lang;
import Toybox.Activity;
import Toybox.Graphics;

class ActivityInfoField extends MySimpleDataField{
    hidden var fieldId as DataFieldId;
    hidden var formatter as Null | Method(value as Numeric|Null) as Numeric|Null|String;

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
                : (fieldId == DATAFIELD_ELEVATION_SPEED) ? WatchUi.loadResource(Rez.Strings.elevationSpeed)
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
            fieldId == DATAFIELD_CURRENT_SPEED ||
            fieldId == DATAFIELD_AVG_SPEED ||
            fieldId == DATAFIELD_MAX_SPEED
        ){
            // speed
            formatter = method(:formatSpeed);
        }else if(
            fieldId == DATAFIELD_ELAPSED_DISTANCE
        ){
            // distance
            formatter = method(:formatDistance);
        }else if(
            fieldId == DATAFIELD_ELAPSED_TIME
        ){
            // time
            formatter = method(:formatTime);
        }else if(
            fieldId == DATAFIELD_PRESSURE ||
            fieldId == DATAFIELD_SEALEVEL_PRESSURE
        ){
            // time
            formatter = method(:formatPressure);
        }


        options.put(:label, strLabel);
        MySimpleDataField.initialize(options);
    }

    function onTimer(){
        var info = Activity.getActivityInfo();
        if(info != null){
            var value
                = (fieldId == DATAFIELD_ELAPSED_TIME) ? info.elapsedTime
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

            if(formatter != null){
                value = formatter.invoke(value);
            }
            setValue(value);
        }else{
            setValue(null);
        }
    }

    function formatSpeed(value as Numeric|Null) as Numeric|Null{
        if(value != null){
            value *= 3.6f;
        }
        return value;
    }

    function formatDistance(value as Numeric|Null) as Numeric|Null{
        if(value != null){
            value /= 1000;
        }
        return value;
    }

    function formatTime(value as Numeric|Null) as String|Null{
        if(value != null){
            var minutes = (value / 60000).toNumber(); // msec => minutes
            var hours = (minutes / 60).toNumber(); // minutes => hours
            value = Lang.format("$1$:$2$", [hours, (minutes % 60).format("%02d")]);
        }
        return value;
    }

    function formatPressure(value as Numeric|Null) as Numeric|Null{
        // Pa => mBar
        if(value != null){
            value /= 100;
        }
        return value;
    }

}