import Toybox.Lang;
import Toybox.Activity;
import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Graphics;
import MyTools;

enum SettingId{
    // global settings
    SETTING_SPORT = 0,
    SETTING_TRACK = 1,
    SETTING_ZOOMFACTOR = 2,
    SETTING_ALTITUDE_CALIBRATED = 3,
    SETTING_ALTITUDE_P0 = 4,
    SETTING_ALTITUDE_T0 = 5,
    SETTING_GLOBAL_MAX = 5,
    // profile settings
    SETTING_BACKGROUND_COLOR = 6,
    SETTING_AUTOPAUSE = 7,
    SETTING_AUTOLAP = 8,
    SETTING_AUTOLAP_DISTANCE = 9,
    SETTING_DATASCREENS = 10,
    SETTING_BREADCRUMPS = 11,
    SETTING_BREADCRUMPS_MIN_DISTANCE = 12,
    SETTING_BREADCRUMPS_MAX_COUNT = 13,
    SETTING_PROFILE_MAX = 13,
}

class Settings{
    typedef ValueType as PropertyValueType|Track;
    typedef IListener as interface{
        function onSetting(id as SettingId, value as ValueType) as Void;
    };

    hidden enum ProfileSection{
        SECTION_GLOBAL = 0,
        SECTION_PROFILE_WALKING = 1,
        SECTION_PROFILE_HIKING = 2,
        SECTION_PROFILE_RUNNING = 3,
        SECTION_PROFILE_CYCLING = 4
    }

    // default values
	static const DEFAULT_VALUES = {
        SETTING_SPORT => Activity.SPORT_WALKING,
        SETTING_TRACK => null,
        SETTING_ZOOMFACTOR=> 1.0f,
        SETTING_ALTITUDE_CALIBRATED => false,
        SETTING_ALTITUDE_P0 => 100000f,
        SETTING_ALTITUDE_T0 => 25f,
        SETTING_BACKGROUND_COLOR => Graphics.COLOR_WHITE,
        SETTING_AUTOPAUSE => true,
        SETTING_AUTOLAP => false,
        SETTING_AUTOLAP_DISTANCE => 1000,
        SETTING_DATASCREENS => [[LAYOUT_ONE_FIELD, [DATAFIELD_TEST], true]],
        SETTING_BREADCRUMPS => true,
	    SETTING_BREADCRUMPS_MIN_DISTANCE => 50,
	    SETTING_BREADCRUMPS_MAX_COUNT => 50,
	};    

    hidden var globalData as Array<PropertyValueType>;
    hidden var profileId as ProfileSection;
    hidden var profileData as Array<PropertyValueType>;

    hidden var listeners as Array<WeakReference> = [] as Array<WeakReference>;

    function initialize(){
        // load global data
        var size = SETTING_GLOBAL_MAX+1;
        var data = Storage.getValue(SECTION_GLOBAL);
        globalData = (data == null || (data as Array).size() != size)
            ? new Array<PropertyValueType>[size]
            : data as Array<PropertyValueType>;

        // load profile data
        var sport = get(SETTING_SPORT) as Activity.Sport;
        profileId = getProfileSection(sport);
        profileData = getProfileData(profileId);
    }
    hidden function getProfileData(profileId as ProfileSection) as Array<PropertyValueType>{
        var size = SETTING_PROFILE_MAX - SETTING_GLOBAL_MAX;
        var data = Storage.getValue(profileId as Number);
        return (data == null || (data as Array).size() != size)
            ? new Array<PropertyValueType>[size]
            : data as Array<PropertyValueType>;
    }

    function get(settingId as SettingId) as ValueType{
        var id = settingId as Number;
        var value = null;
        if(id <= SETTING_GLOBAL_MAX){
            value = globalData[id] as PropertyValueType;
        }else if(id <= SETTING_PROFILE_MAX){
            value =  profileData[id - (SETTING_GLOBAL_MAX + 1)] as PropertyValueType;
        }
        if(value == null){
            // get default value
            value = DEFAULT_VALUES.get(id) as ValueType?;
//            if(value == null){
//                throw new MyTools.MyException(Lang.format("No default value available for setting $1$", [settingId]));
//            }
            self.set(settingId, value);
        }
        return value;
    }

    function set(settingId as SettingId, value as ValueType) as Void{
        // update instance and app data
        var id = settingId as Number;
        if (id <= SETTING_GLOBAL_MAX){
            if(id == SETTING_SPORT){
                //disable changing a profile during an active session
                var session = $.getApp().session;
                if(session.getState() != SESSION_STATE_IDLE){
                    return;
                }
            }

            globalData[id] = value;
            Storage.setValue(SECTION_GLOBAL, globalData);
        }else if(id <= SETTING_PROFILE_MAX){
            profileData[id - (SETTING_GLOBAL_MAX + 1)] = value;
            Storage.setValue(profileId as Number, profileData);
        }

        // check if the profile is changed
        if(settingId == SETTING_SPORT){
            var profileIdNew = getProfileSection(value as Sport);
            if(profileIdNew != profileId){
                // profile is changed
                profileId = profileIdNew;
                profileData = getProfileData(profileId);
            }
        }

        // convert raw track data to Track
        if(settingId == SETTING_TRACK && value instanceof Array){
            value = new Track(value as Array);
        }

        // inform listeners
        notifyListeners(settingId, value);
    }

    function clear() as Void{
        globalData = new Array<PropertyValueType>[SETTING_GLOBAL_MAX+1];
        profileData = new Array<PropertyValueType>[SETTING_PROFILE_MAX - SETTING_GLOBAL_MAX];
        Storage.clearValues();
    }

    // hidden helper functions:
    hidden function getProfileSection(sport as Sport) as ProfileSection{
        switch(sport){
            case Activity.SPORT_WALKING:
                return SECTION_PROFILE_WALKING;
            case Activity.SPORT_HIKING:
                return SECTION_PROFILE_HIKING;
            case Activity.SPORT_RUNNING:
                return SECTION_PROFILE_RUNNING;
            case Activity.SPORT_CYCLING:
                return SECTION_PROFILE_CYCLING;
            default:
                return SECTION_PROFILE_WALKING;
        }
    }

    // Listeners
    function addListener(listener as Object) as Void{
        if((listener as IListener) has :onSetting){
            listeners.add(listener.weak());
        }
    }
    function removeListener(listener as Object) as Void{
        // loop through array to look for listener
        for(var i=listeners.size()-1; i>=0; i--){
            var ref = listeners[i];
            var l = ref.get();
            if(l == null || l.equals(listener)){
                listeners.remove(ref);
            }
        }
    }
    hidden function notifyListeners(id as SettingId, value as ValueType) as Void{
        for(var i=listeners.size()-1; i>=0; i--){
            var ref = listeners[i];
            var l = ref.get();
            if(l != null){
                (l as IListener).onSetting(id, value);
            }else{
                listeners.remove(ref);
            }
        }
    }
}