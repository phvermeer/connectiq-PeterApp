import Toybox.Lang;
import Toybox.Graphics;

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
        var field = 
            new TestField({});

        // keep weak link in buffer for new requests
        fieldRefs[id] = field.weak();
        return field;
    }
}