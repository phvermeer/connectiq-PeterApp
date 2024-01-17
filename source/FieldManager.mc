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
    DATAFIELD_STATUS = 27,
    DATAFIELD_LAYOUT_TEST = 28,
    DATAFIELD_FONT_TEST = 29,
    DATAFIELD_PRESSURE = 30,
    DATAFIELD_SEALEVEL_PRESSURE = 31,
    DATAFIELD_EMPTY = 32,
}

class FieldManager{
    hidden var fieldRefs as Dictionary<DataFieldId, WeakReference>;

    function initialize(){
        fieldRefs = {} as Dictionary<DataFieldId, WeakReference>;
    }

    (:track)
    function getField(id as DataFieldId) as MyDataField{
        // check if field already is created
        var ref = fieldRefs.get(id);
        if(ref != null){
            if(ref.stillAlive()){
                return ref.get() as MyDataField;
            }
        }

        var app = $.getApp();
        var options = {
            :darkMode => app.settings.get(Settings.ID_DARK_MODE) as Boolean
        };

        var field = null;
        if(id == DATAFIELD_TEST){ field = new TestField(options); }else
        if(id == DATAFIELD_ELAPSED_TIME){ field = new MultiDataField(id, options); }else
        if(id == DATAFIELD_TRACK_MAP){ field = new TrackField(options); }else
        if(id == DATAFIELD_TRACK_OVERVIEW){ field = new TrackOverviewField(options); }else
        if(id == DATAFIELD_TRACK_PROFILE){ field = new TrackProfileField(options); }else
        if(id == DATAFIELD_COMPASS){ field = new CompassField(options); }else
        if(id == DATAFIELD_CURRENT_SPEED){ field = new MultiDataField(id, options); }else
        if(id == DATAFIELD_AVG_SPEED){ field = new MultiDataField(id, options); }else
        if(id == DATAFIELD_MAX_SPEED){ field = new MultiDataField(id, options); }else
        if(id == DATAFIELD_ELAPSED_DISTANCE){ field = new MultiDataField(id, options); }else
        if(id == DATAFIELD_REMAINING_DISTANCE){ field = new RemainingDistanceField(id, options); }else
        // if(id == DATAFIELD_ELEVATION_SPEED){ field = new MultiDataField(id, options); }else
        if(id == DATAFIELD_TOTAL_ASCENT){ field =  new MultiDataField(id, options); }else
        if(id == DATAFIELD_TOTAL_DESCENT){ field =  new MultiDataField(id, options); }else
        if(id == DATAFIELD_HEART_RATE){ field =  new MultiDataField(id, options); }else
        if(id == DATAFIELD_AVG_HEARTRATE){ field = new MultiDataField(id, options); }else
        if(id == DATAFIELD_MAX_HEARTRATE){ field =  new MultiDataField(id, options); }else
        if(id == DATAFIELD_OXYGEN_SATURATION){ field = new MultiDataField(id, options); }else
        if(id == DATAFIELD_ENERGY_RATE){ field = new MultiDataField(id, options); }else
        if(id == DATAFIELD_PRESSURE){ field = new MultiDataField(id, options); }else
        if(id == DATAFIELD_SEALEVEL_PRESSURE){ field = new MultiDataField(id, options); }else
        if(id == DATAFIELD_ALTITUDE){ field = new MultiDataField(id, options); }else
        if(id == DATAFIELD_CLOCK){ field = new MultiDataField(id, options); }else
        if(id == DATAFIELD_MEMORY){ field = new MultiDataField(id, options); }else
        if(id == DATAFIELD_BATTERY){ field = new MultiDataField(id, options); }else
        if(id == DATAFIELD_EMPTY){ field = new EmptyField(options); }else
        if(id == DATAFIELD_STATUS){ field = new StatusField(options); }else
        { field = new EmptyField(options); }

        // keep weak link in buffer for new requests
        fieldRefs.put(id, field.weak());
        log(Lang.format("Field $1$ is created", [id]));

        // keep fields up-to-date
        app.data.addListener(field);
        app.settings.addListener(field);
        return field;
    }

    (:noTrack)
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
        var options = {
            :darkMode => app.settings.get(Settings.ID_DARK_MODE) as Boolean,
        };
        
        var field = null;
        if(id == DATAFIELD_TEST){ field = new TestField(options); }else
        if(id == DATAFIELD_ELAPSED_TIME){ field = new MultiDataField(id, options); }else
        // if(id == DATAFIELD_TRACK_MAP){ field = new TrackField(options); }else
        // if(id == DATAFIELD_TRACK_OVERVIEW){ field = new TrackOverviewField(options); }else
        // if(id == DATAFIELD_TRACK_PROFILE){ field = new TrackProfileField(options); }else
        if(id == DATAFIELD_COMPASS){ field = new CompassField(options); }else
        if(id == DATAFIELD_CURRENT_SPEED){ field = new MultiDataField(id, options); }else
        if(id == DATAFIELD_AVG_SPEED){ field = new MultiDataField(id, options); }else
        if(id == DATAFIELD_MAX_SPEED){ field = new MultiDataField(id, options); }else
        if(id == DATAFIELD_ELAPSED_DISTANCE){ field = new MultiDataField(id, options); }else
        // if(id == DATAFIELD_REMAINING_DISTANCE){ field = new RemainingDistanceField(id, options); }else
        //  if(id == DATAFIELD_ELEVATION_SPEED){ field = new MultiDataField(id, options); }else
        if(id == DATAFIELD_TOTAL_ASCENT){ field =  new MultiDataField(id, options); }else
        if(id == DATAFIELD_TOTAL_DESCENT){ field =  new MultiDataField(id, options); }else
        if(id == DATAFIELD_HEART_RATE){ field =  new MultiDataField(id, options); }else
        if(id == DATAFIELD_AVG_HEARTRATE){ field = new MultiDataField(id, options); }else
        if(id == DATAFIELD_MAX_HEARTRATE){ field =  new MultiDataField(id, options); }else
        if(id == DATAFIELD_OXYGEN_SATURATION){ field = new MultiDataField(id, options); }else
        if(id == DATAFIELD_ENERGY_RATE){ field = new MultiDataField(id, options); }else
        if(id == DATAFIELD_PRESSURE){ field = new MultiDataField(id, options); }else
        if(id == DATAFIELD_SEALEVEL_PRESSURE){ field = new MultiDataField(id, options); }else
        if(id == DATAFIELD_ALTITUDE){ field = new MultiDataField(id, options); }else
        if(id == DATAFIELD_CLOCK){ field = new SystemStatsField(id, options); }else
        if(id == DATAFIELD_MEMORY){ field = new SystemStatsField(id, options); }else
        if(id == DATAFIELD_BATTERY){ field = new SystemStatsField(id, options); }else
        if(id == DATAFIELD_EMPTY){ field = new EmptyField(options); }else
        // if(id == DATAFIELD_STATUS){ field = new StatusField(options); }else
        { field = new EmptyField(options); }

        // keep weak link in buffer for new requests
        fieldRefs.put(id, field.weak());
        log(Lang.format("Field $1$ is created", [id]));

        // keep fields up-to-date
        app.data.addListener(field);
        app.settings.addListener(field);
        return field;
    }

    function getFields(ids as Array<DataFieldId>) as Array<MyDataField>{
        var count = ids.size();
        var fields = new Array<MyDataField>[count];
        for(var i=0; i<count; i++){
            fields[i] = getField(ids[i]);
        }
        cleanup();
        return fields;
    }

    function cleanup() as Void{
        var keys = fieldRefs.keys();
        var values = fieldRefs.values();
        for(var i=0; i<fieldRefs.size(); i++){
            if(!(values[i] as WeakReference).stillAlive()){
                fieldRefs.remove(keys[i]);
                log(Lang.format("Field $1$ is released", [keys[i]]));
            }
        }
    }
}