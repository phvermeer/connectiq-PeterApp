import Toybox.Lang;

class DataScreenSettings{
	hidden enum DataViewSettingId {
		SETTING_LAYOUT = 0,
		SETTING_FIELDS = 1,
		SETTING_ENABLED = 2,
	}

    var layoutId as LayoutId;
    var fieldIds as Array<DataFieldId>;
    var enabled as Boolean;

    function initialize(screenData as Array){
        // validate data
        if(screenData.size() != 3){
            throw new Lang.UnexpectedTypeException("ScreenData should be an array with 3 elements (ScreenSettings: [Layout,Fields,Enabled])", null, null);
        }

        var value = screenData[SETTING_LAYOUT];
        if(!(value instanceof Number)){
            throw new Lang.UnexpectedTypeException(Lang.format("ScreenData[$1$] should be of type Number (Screen Layout)",[SETTING_LAYOUT]), null, null);
        }
        layoutId = value as LayoutId;

        value = screenData[SETTING_FIELDS];
        if(!(value instanceof Array)){
            throw new Lang.UnexpectedTypeException(Lang.format("ScreenData[$1$] should be of type Array (Fields)",[SETTING_FIELDS]), null, null);
        }else{
            var values = value as Array;
            for(var i=0; i<values.size(); i++){
                if(!values[i] instanceof Number){
                    throw new Lang.UnexpectedTypeException(Lang.format("ScreenData[$1$][$2] should be of type Number (FieldId)",[SETTING_FIELDS, i]), null, null);
                }
            }
        }
        fieldIds = value as Array<DataFieldId>;

        value = screenData[SETTING_ENABLED];
        if(!(value instanceof Boolean)){
            throw new Lang.UnexpectedTypeException(Lang.format("Settings[$1$][?][$2$] should be of type Boolean (Screen Enabled)",[SETTING_DATASCREENS, SETTING_ENABLED]), null, null);
        }
        enabled = value as Boolean;
    }

    function export() as Array{
        return [layoutId, fieldIds, enabled];
    }
}