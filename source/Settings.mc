import Toybox.Lang;
import Toybox.Activity;
import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Graphics;

class SettingsListeners extends Listeners{
    function initialize(){
        Listeners.initialize(:onSetting);
    }

    function invoke(sender as Object, listener as Object, info as Object|Null){
        var params = info as Array; //[0] => Settings.Id, [1] => value
        listener.method(method).invoke(sender, params[0], params[1]);
    }
}

class Settings{
    enum Id{
        // global settings
        ID_SPORT = 0,
        ID_TRACK = 1,
        ID_ZOOMFACTOR = 2,
        ID_ALTITUDE_CALIBRATED = 3,
        ID_ALTITUDE_P0 = 4,
        ID_ALTITUDE_T0 = 5,
        ID_GLOBAL_MAX = 5,
        // profile settings
        ID_DARK_MODE = 6,
        ID_AUTOPAUSE = 7,
        ID_AUTOLAP = 8,
        ID_AUTOLAP_DISTANCE = 9,
        ID_DATASCREENS = 10,
        ID_BREADCRUMPS = 11,
        ID_BREADCRUMPS_MIN_DISTANCE = 12,
        ID_BREADCRUMPS_MAX_COUNT = 13,
        ID_PROFILE_MAX = 13,
    }

    (:noTrack)
    typedef ValueType as PropertyValueType;
    (:track)
    typedef ValueType as PropertyValueType|Track;

    hidden enum ProfileSection{
        SECTION_GLOBAL = 0,
        SECTION_PROFILE_WALKING = 1,
        SECTION_PROFILE_HIKING = 2,
        SECTION_PROFILE_RUNNING = 3,
        SECTION_PROFILE_CYCLING = 4
    }

    // default values
	static const DEFAULT_VALUES = {
        ID_SPORT => Activity.SPORT_WALKING,
        ID_TRACK => null,
        ID_ZOOMFACTOR=> 1.0f,
        ID_ALTITUDE_CALIBRATED => false,
        ID_ALTITUDE_P0 => 100000f,
        ID_ALTITUDE_T0 => 25f,
        ID_DARK_MODE => false,
        ID_AUTOPAUSE => true,
        ID_AUTOLAP => false,
        ID_AUTOLAP_DISTANCE => 1000,
        ID_DATASCREENS => [[LAYOUT_ONE_FIELD, [DATAFIELD_TEST], true]],
        ID_BREADCRUMPS => true,
	    ID_BREADCRUMPS_MIN_DISTANCE => 50,
	    ID_BREADCRUMPS_MAX_COUNT => 50,
	};    

    hidden var globalData as Array<PropertyValueType>;
    hidden var profileId as ProfileSection;
    hidden var profileData as Array<PropertyValueType>;

    hidden var listeners as SettingsListeners = new SettingsListeners();

    function initialize(){
        // load global data
        var size = ID_GLOBAL_MAX+1;
        var data = Storage.getValue(SECTION_GLOBAL);
        globalData = (data == null || (data as Array).size() != size)
            ? new Array<PropertyValueType>[size]
            : data as Array<PropertyValueType>;

        // load profile data
        var sport = get(ID_SPORT) as Activity.Sport;
        profileId = getProfileSection(sport);
        profileData = getProfileData(profileId);
    }

    hidden function getProfileData(profileId as ProfileSection) as Array<PropertyValueType>{
        var size = ID_PROFILE_MAX - ID_GLOBAL_MAX;
        var data = Storage.getValue(profileId as Number);

        return(data == null || (data as Array).size() != size)
            ? DEFAULT_VALUES.values().slice(ID_GLOBAL_MAX+1, null) as Array<PropertyValueType>
            : data as Array<PropertyValueType>;
    }

    function get(settingId as Id) as ValueType{
        var id = settingId as Number;
        var value = null;
        if(id <= ID_GLOBAL_MAX){
            value = globalData[id] as PropertyValueType;
        }else if(id <= ID_PROFILE_MAX){
            value =  profileData[id - (ID_GLOBAL_MAX + 1)] as PropertyValueType;
        }
        if(value == null){
            // get default value
            value = DEFAULT_VALUES.get(id) as ValueType?;
            //  if(value == null){
            //      throw new MyException(Lang.format("No default value available for setting $1$", [settingId]));
            //  }
            self.set(settingId, value);
        }
        return value;
    }

    function set(settingId as Id, value as ValueType) as Void{
        // update instance and app data
        var id = settingId as Number;
        if (id <= ID_GLOBAL_MAX){
            if(id == ID_SPORT){
                //disable changing a profile during an active session
                var session = $.getApp().session;
                if(session != null && session.getState() != SESSION_STATE_IDLE){
                    return;
                }
            }

            globalData[id] = value;
            Storage.setValue(SECTION_GLOBAL, globalData);
        }else if(id <= ID_PROFILE_MAX){
            profileData[id - (ID_GLOBAL_MAX + 1)] = value;
            Storage.setValue(profileId as Number, profileData);
        }

        // check if the profile is changed
        if(settingId == ID_SPORT){
            var profileIdNew = getProfileSection(value as Sport);
            if(profileIdNew != profileId){
                // profile is changed
                profileId = profileIdNew;
                profileData = getProfileData(profileId);
            }
        }

        // convert raw track data to Track
        if(settingId == ID_TRACK && value != null){
            try{
                value = convertToTrack(value as Array);
            }catch(e instanceof Exception){
                set(settingId, null);
                e.printStackTrace();
                return;
            }
        }

        // inform listeners
        notifyListeners(settingId, value);
    }

    function clear() as Void{
        globalData = new Array<PropertyValueType>[ID_GLOBAL_MAX+1];
        profileData = new Array<PropertyValueType>[ID_PROFILE_MAX - ID_GLOBAL_MAX];
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
        listeners.add(self, listener, null);
    }
    hidden function notifyListeners(id as Id, value as ValueType) as Void{
        listeners.notify(self, [id, value]);
    }
}