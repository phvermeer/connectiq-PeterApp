import Toybox.Lang;
import Toybox.Graphics;
import Toybox.Application;

enum DataFieldId{
    DATAFIELD_TEST = 0,
    DATAFIELD_MAX = 0
}

class FieldManager{
    hidden var fieldRefs as Array<WeakReference?>;

    function initialize(){
        fieldRefs = new Array<WeakReference>[DATAFIELD_MAX + 1];
    }

    function getField(dataFieldId as DataFieldId) as MyDataField{
        var id = dataFieldId as Number;
        // check if field already is created
        var ref = fieldRefs[id];
        if(ref != null){
            if(ref.stillAlive()){
                return ref.get() as MyDataField;
            }
        }

        // else create a new datafield
        var backgroundColor = $.getApp().settings.get(SETTING_BACKGROUND_COLOR) as ColorType;
        var field = 
            new TestField({
                :backgroundColor => backgroundColor
            });

        // keep weak link in buffer for new requests
        fieldRefs[id] = field.weak();
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
            for(var i=0; i<fieldRefs.size(); i++){
                var ref = fieldRefs[i];
                if(ref != null){
                    if(ref.stillAlive()){
                        (ref.get() as MyDataField).setBackgroundColor(color);
                    }
                }
            }
        }
    }
}