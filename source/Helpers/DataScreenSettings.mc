import Toybox.Lang;

class DataScreenSettings{
	enum DataViewSettingId {
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
            throw new MyTools.MyException("ScreenData should be an array with 3 elements (ScreenSettings: [Layout,Fields,Enabled])");
        }

        var value = screenData[SETTING_LAYOUT];
        if(!(value instanceof Number)){
            throw new MyTools.MyException(Lang.format("ScreenData[$1$] should be of type Number (Screen Layout)",[SETTING_LAYOUT]));
        }
        layoutId = value as LayoutId;

        value = screenData[SETTING_FIELDS];
        if(!(value instanceof Array)){
            throw new MyTools.MyException(Lang.format("ScreenData[$1$] should be of type Array (Fields)",[SETTING_FIELDS]));
        }else{
            var values = value as Array;
            for(var i=0; i<values.size(); i++){
                if(!(values[i] instanceof Number)){
                    throw new MyTools.MyException(Lang.format("ScreenData[$1$][$2] should be of type Number (FieldId)",[SETTING_FIELDS, i]));
                }
            }
        }
        fieldIds = value as Array<DataFieldId>;

        value = screenData[SETTING_ENABLED];
        if(!(value instanceof Boolean)){
            throw new MyTools.MyException(Lang.format("Settings[$1$][?][$2$] should be of type Boolean (Screen Enabled)",[SETTING_DATASCREENS, SETTING_ENABLED]));
        }
        enabled = value as Boolean;
    }

    function export() as Array{
        return [layoutId, fieldIds, enabled];
    }
}