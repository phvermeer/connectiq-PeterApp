import Toybox.Lang;
import Toybox.Graphics;
import Toybox.Application;
import Toybox.Position;
import Toybox.Activity;
import Toybox.System;

enum DataFieldId{
    DATAFIELD_TEST = 0,
    DATAFIELD_ELAPSED_TIME = 1,
    DATAFIELD_TRACK_MAP = 2,
    DATAFIELD_TRACK_OVERVIEW = 3,
    DATAFIELD_TRACK_PROFILE = 4,
    DATAFIELD_COMPASS = 5,
    DATAFIELD_CURRENT_SPEED = 6,
    DATAFIELD_AVG_SPEED = 7,
    DATAFIELD_MAX_SPEED = 8,
    DATAFIELD_ELAPSED_DISTANCE = 9,
    DATAFIELD_REMAINING_DISTANCE = 10,
    DATAFIELD_ALTITUDE = 11,
    DATAFIELD_ELEVATION_SPEED = 12,
    DATAFIELD_TOTAL_ASCENT = 13,
    DATAFIELD_TOTAL_DESCENT = 14,
    DATAFIELD_LAP_TIME = 15,
    DATAFIELD_LAP_DISTANCE = 16,
    DATAFIELD_LAP_SPEED = 17,
    DATAFIELD_HEART_RATE = 18,
    DATAFIELD_AVG_HEARTRATE = 19,
    DATAFIELD_MAX_HEARTRATE = 20,
    DATAFIELD_OXYGEN_SATURATION = 21,
    DATAFIELD_ENERGY_RATE = 22,
    DATAFIELD_CLOCK = 23,
    DATAFIELD_MEMORY = 24,
    DATAFIELD_BATTERY = 25,
    DATAFIELD_COUNTER = 26,
    DATAFIELD_BATTERY_CONSUMPTION = 27,
    DATAFIELD_LAYOUT_TEST = 28,
    DATAFIELD_FONT_TEST = 29,
    DATAFIELD_PRESSURE = 30,
    DATAFIELD_SEALEVEL_PRESSURE = 31,
    DATAFIELD_EMPTY = 32,
}

class FieldManager{
    hidden var fieldRefs as Dictionary<DataFieldId, WeakReference>;
    hidden var lastActivityInfo as Activity.Info?;
    hidden var lastSystemStats as System.Stats?;

    typedef IMyDataField as interface{
        function updateTrack() as Void;
        function onPosition(xy as PositionManager.XyPoint?, info as Position.Info) as Void;
        function onActivityInfo(info as Activity.Info) as Void;
        function onSystemInfo(stats as System.Stats) as Void;
        function onSetting(id as SettingId, value as PropertyValueType) as Void;
    };

    function initialize(){
        fieldRefs = {} as Dictionary<DataFieldId, WeakReference>;
    }

    function getField(id as DataFieldId) as MyDataField{
        // check if field already is created
        var ref = fieldRefs.get(id);
        if(ref != null){
            if(ref.stillAlive()){
                return ref.get() as MyDataField;
            }
        }

        // else create a new datafield
        var app = $.getApp();
        var backgroundColor = app.settings.get(SETTING_BACKGROUND_COLOR) as ColorType;

        var options = { :backgroundColor => backgroundColor };
        if(app.track != null){
            options.put(:track, app.track);
        }
        var field
            = (id == DATAFIELD_TEST) ? new TestField(options)
            : (id == DATAFIELD_ELAPSED_TIME) ? new ActivityInfoField(id, options)
            : (id == DATAFIELD_TRACK_MAP) ? new TrackField(options)
            : (id == DATAFIELD_TRACK_OVERVIEW) ? new TrackOverviewField(options)
            : (id == DATAFIELD_TRACK_PROFILE) ? new TrackProfileField(options)
            : (id == DATAFIELD_CURRENT_SPEED) ? new ActivityInfoField(id, options)
            : (id == DATAFIELD_AVG_SPEED) ? new ActivityInfoField(id, options)
            : (id == DATAFIELD_MAX_SPEED) ? new ActivityInfoField(id, options)
            : (id == DATAFIELD_ELAPSED_DISTANCE) ? new ActivityInfoField(id, options)
            : (id == DATAFIELD_REMAINING_DISTANCE) ? new RemainingDistanceField(id, options)
            //: (id == DATAFIELD_ELEVATION_SPEED) ? new ActivityInfoField(id, options)
            : (id == DATAFIELD_TOTAL_ASCENT) ?  new ActivityInfoField(id, options)
            : (id == DATAFIELD_TOTAL_DESCENT) ?  new ActivityInfoField(id, options)
            : (id == DATAFIELD_HEART_RATE) ?  new ActivityInfoField(id, options)
            : (id == DATAFIELD_AVG_HEARTRATE) ? new ActivityInfoField(id, options)
            : (id == DATAFIELD_MAX_HEARTRATE) ?  new ActivityInfoField(id, options)
            : (id == DATAFIELD_OXYGEN_SATURATION) ? new ActivityInfoField(id, options)
            : (id == DATAFIELD_ENERGY_RATE) ? new ActivityInfoField(id, options)
            : (id == DATAFIELD_PRESSURE) ? new ActivityInfoField(id, options)
            : (id == DATAFIELD_SEALEVEL_PRESSURE) ? new ActivityInfoField(id, options)
            : (id == DATAFIELD_CLOCK) ? new SystemInfoField(id, options)
            : (id == DATAFIELD_MEMORY) ? new SystemInfoField(id, options)
            : (id == DATAFIELD_BATTERY) ? new SystemInfoField(id, options)
            : (id == DATAFIELD_EMPTY) ? new EmptyField(options)
            : (id == DATAFIELD_ALTITUDE) ? new AltitudeField(options)
            : new EmptyField(options);

        // update field with latest Activity Info
        if(lastActivityInfo == null){
            lastActivityInfo = Activity.getActivityInfo();
        }
        if(lastActivityInfo != null){
            if((field as IMyDataField) has :onActivityInfo){
                (field as IMyDataField).onActivityInfo(lastActivityInfo);
            }
        }
        // update field with latest System stats
        if(lastSystemStats == null){
            lastSystemStats = System.getSystemStats();
        }
        if(lastSystemStats != null){
            if((field as IMyDataField) has :onSystemInfo){
                (field as IMyDataField).onSystemInfo(lastSystemStats);
            }
        }

        // keep weak link in buffer for new requests
        fieldRefs.put(id, field.weak());
        return field;
    }

    function getFields(ids as Array<DataFieldId>) as Array<MyDataField>{
        var count = ids.size();
        var fields = new Array<MyDataField>[count];
        for(var i=0; i<count; i++){
            fields[i] = getField(ids[i]);
        }
        return fields;
    }

    function onSetting(id as SettingId, value as PropertyValueType) as Void{
        var refs = fieldRefs.values();

        for(var i=refs.size()-1; i>=0; i--){
            var ref = refs[i];
            if(ref.stillAlive()){
                var field = ref.get() as MyDataField;
                if((field as IMyDataField) has :onSetting){
                    (field as IMyDataField).onSetting(id, value);
                }
            }else{
                var key = fieldRefs.keys()[i] as DataFieldId;
                fieldRefs.remove(key);
            }
        }
    }
    function onActivityInfo(info as Activity.Info) as Void{
        lastActivityInfo = info;
        var fields = getSupportedFields(:onActivityInfo);
        for(var i=0; i<fields.size(); i++){
            var field = fields[i];
            field.onActivityInfo(info);
        }
    }
    function onPosition(xy as PositionManager.XyPoint?, info as Position.Info) as Void{
        var fields = getSupportedFields(:onPosition);
        for(var i=0; i<fields.size(); i++){
            var field = fields[i];
            field.onPosition(xy, info);
        }
    }
    function onSystemInfo(stats as System.Stats) as Void{
        lastSystemStats = stats;

        var fields = getSupportedFields(:onSystemInfo);
        for(var i=0; i<fields.size(); i++){
            var field = fields[i];
            field.onSystemInfo(stats);
        }
    }

    hidden function getSupportedFields(method as Symbol) as Array<IMyDataField>{
        var refs = fieldRefs.values();
        var fields = [] as Array<IMyDataField>;
        for(var i=refs.size()-1; i>=0; i--){
            var ref = refs[i];
            if(ref.stillAlive()){
                var field = ref.get() as MyDataField;
                if((field as IMyDataField) has method){
                    fields.add(field as IMyDataField);
                }
            }else{
                var key = fieldRefs.keys()[i] as DataFieldId;
                fieldRefs.remove(key);
            }
        }
        return fields;
    }
}