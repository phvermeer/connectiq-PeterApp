import Toybox.Lang;
import Toybox.Graphics;
import Toybox.Application;

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
}

enum XXX{
    XXX_0,
    XXX_1,
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

        // else create a new datafield
        var backgroundColor = $.getApp().settings.get(SETTING_BACKGROUND_COLOR) as ColorType;
        var field = 
            (id == DATAFIELD_ELAPSED_DISTANCE)
                ? new ElapsedDistanceField({ :backgroundColor => backgroundColor })
                : new TestField({ :backgroundColor => backgroundColor });

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
        if(id == SETTING_BACKGROUND_COLOR){
            var color = value as ColorType;
            var refs = fieldRefs.values();
            for(var i=0; i<refs.size(); i++){
                var ref = refs[i];
                if(ref != null){
                    if(ref.stillAlive()){
                        (ref.get() as MyDataField).setBackgroundColor(color);
                    }
                }
            }
        }
    }
}