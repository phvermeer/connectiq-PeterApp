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
    DATAFIELD_WAYPOINT_DISTANCE = 33,
}

class FieldManager{
    hidden var fieldRefs as Dictionary<DataFieldId, WeakReference>;

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

        var app = $.getApp();
        var options = {
            :darkMode => app.settings.get(Settings.ID_DARK_MODE) as Boolean
        };

        var field = null;
        if(id == DATAFIELD_TEST){ field = new TestField(options); }else
        if(id == DATAFIELD_ELAPSED_TIME){ field = new ActivityField(id, options); }else
        if(id == DATAFIELD_COMPASS){ field = new CompassField(options); }else
        if(id == DATAFIELD_CURRENT_SPEED){ field = new ActivityField(id, options); }else
        if(id == DATAFIELD_AVG_SPEED){ field = new ActivityField(id, options); }else
        if(id == DATAFIELD_MAX_SPEED){ field = new ActivityField(id, options); }else
        if(id == DATAFIELD_ELAPSED_DISTANCE){ field = new ActivityField(id, options); }else
        if(id == DATAFIELD_TOTAL_ASCENT){ field =  new ActivityField(id, options); }else
        if(id == DATAFIELD_TOTAL_DESCENT){ field =  new ActivityField(id, options); }else
        if(id == DATAFIELD_HEART_RATE){ field =  new ActivityField(id, options); }else
        if(id == DATAFIELD_AVG_HEARTRATE){ field = new ActivityField(id, options); }else
        if(id == DATAFIELD_MAX_HEARTRATE){ field =  new ActivityField(id, options); }else
        if(id == DATAFIELD_OXYGEN_SATURATION){ field = new ActivityField(id, options); }else
        if(id == DATAFIELD_ENERGY_RATE){ field = new ActivityField(id, options); }else
        if(id == DATAFIELD_PRESSURE){ field = new ActivityField(id, options); }else
        if(id == DATAFIELD_SEALEVEL_PRESSURE){ field = new ActivityField(id, options); }else
        if(id == DATAFIELD_ALTITUDE){ field = new ActivityField(id, options); }else
        if(id == DATAFIELD_ELEVATION_SPEED){ field = new ElevationSpeedField(options); }else        
        if(id == DATAFIELD_CLOCK){ field = new SystemStatsField(id, options); }else
        if(id == DATAFIELD_MEMORY){ field = new SystemStatsField(id, options); }else
        if(id == DATAFIELD_BATTERY){ field = new SystemStatsField(id, options); }else
        if(id == DATAFIELD_EMPTY){ field = new MyDataField(options); }else
        if(id == DATAFIELD_STATUS){ field = new StatusField(options); }else{
            field = getTrackFields(id, options);
            if(field == null){
                field = new MyDataField(options);
            }
        }

        // keep weak link in buffer for new requests
        fieldRefs.put(id, field.weak());
        log(Lang.format("Field $1$ is created", [id]));

        // keep fields up-to-date
        addListeners(field);
        return field;
    }

    (:noTrack)
    function addListeners(field as MyDataField) as Void{
        var app = $.getApp();
        app.data.addListener(field);
        app.settings.addListener(field);
    }
    (:track)
    function addListeners(field as MyDataField) as Void{
        var app = $.getApp();
        app.data.addListener(field);
        app.settings.addListener(field);
        app.trackManager.addListener(field);
    }

    // additional optional fields
    (:track)
    function getTrackFields(id as DataFieldId, options as { :darkMode as Boolean }) as MyDataField|Null{
        var track = $.getApp().trackManager.track;
        if(track != null){
            options.put(:track, track);
        }

        if(id == DATAFIELD_TRACK_MAP){ return new TrackField(options); }else
        if(id == DATAFIELD_REMAINING_DISTANCE){ return new RemainingDistanceField(id, options); }else
        if(id == DATAFIELD_WAYPOINT_DISTANCE){ return new WaypointDistanceField(options); }else
        { return getAdvancedFields(id, options); }
    }
    (:noTrack)
    function getTrackFields(id as DataFieldId, options as { :darkMode as Boolean }) as MyDataField|Null{
        return null;
    }

    (:advanced)
    function getAdvancedFields(id as DataFieldId, options as { :darkMode as Boolean }) as MyDataField|Null{
        if(id == DATAFIELD_TRACK_PROFILE){ return new TrackProfileField(options); }else  
        if(id == DATAFIELD_TRACK_OVERVIEW){ return new TrackOverviewField(options); }else
        { return null; }
    }
    (:basic)
    function getAdvancedFields(id as DataFieldId, options as { :darkMode as Boolean }) as MyDataField|Null{
        return null;
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