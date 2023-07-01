import Toybox.Lang;
import Toybox.Activity;
import Toybox.Application;
import MyTools;

enum SettingId{
    // global settings
    SETTING_SPORT = 0,
    SETTING_TRACK = 1,
    SETTING_ZOOMLEVEL = 2,
    SETTING_GLOBAL_MAX = 2,
    // profile settings
    SETTING_BACKGROUND_COLOR = 3,
    SETTING_AUTOPAUSE = 4,
    SETTING_AUTOLAP = 5,
    SETTING_AUTOLAP_DISTANCE = 6,
    SETTING_DATASCREENS = 7,
    SETTING_BREADCRUMPS_ENABLED = 8,
    SETTING_BREADCRUMPS_MIN_DISTANCE = 9,
    SETTING_BREADCRUMPS_MAX_COUNT = 10,
    SETTING_PROFILE_MAX = 10,
}



class Settings{
    hidden enum ProfileSection{
        SECTION_GLOBAL = 0,
        SECTION_PROFILE_WALKING = 1,
        SECTION_PROFILE_HIKING = 2,
        SECTION_PROFILE_RUNNING = 3,
        SECTION_PROFILE_CYCLING = 4
    }

    // default values
	hidden const DEFAULT_VALUES = {
        SETTING_SPORT => Activity.SPORT_WALKING,
        SETTING_TRACK => null,
        SETTING_ZOOMLEVEL => 1.0f,
        SETTING_BACKGROUND_COLOR => Graphics.COLOR_WHITE,
        SETTING_AUTOPAUSE => true,
        SETTING_AUTOLAP => false,
        SETTING_AUTOLAP_DISTANCE => 1000,
        SETTING_DATASCREENS => [[LAYOUT_ONE_FIELD, [DATAFIELD_TEST]]],
        SETTING_BREADCRUMPS_ENABLED => true,
	    SETTING_BREADCRUMPS_MIN_DISTANCE => 50,
	    SETTING_BREADCRUMPS_MAX_COUNT => 50,
	};    

    hidden var globalData as Array<PropertyValueType>;
    hidden var profileData as Array<PropertyValueType>;
    hidden var onValueChange as Null|Method(settingId as SettingId, value as PropertyValueType) as Void;
    hidden var onDefaultRequest as Null|Method(settingId as SettingId) as PropertyValueType;

    function initialize(options as {
        :onValueChange as Method(settingId as SettingId, value as PropertyValueType) as Void
    }){
        onValueChange = options.get(:onValueChange);

        // load data
        var app = $.getApp();
        app.loadProperties();

        // load global data
        var size = SETTING_GLOBAL_MAX+1;
        var data = app.getProperty(SECTION_GLOBAL);
        globalData = (data == null || (data as Array).size() != size)
            ? new Array<PropertyValueType>[size]
            : data;

        // load profile data
        var sectionId = getProfileSection();
        size = SETTING_PROFILE_MAX - SETTING_GLOBAL_MAX;
        data = app.getProperty(SECTION_GLOBAL);
        profileData = (data == null || (data as Array).size() != size)
            ? new Array<PropertyValueType>[size]
            : data;
    }

    function get(settingId as SettingId) as PropertyValueType{
        var id = settingId as Number;
        var value = (id <= SETTING_GLOBAL_MAX)
            ? globalData[id]
            : (id <= SETTING_PROFILE_MAX)
                ? profileData[id - SETTING_GLOBAL_MAX]
                : null;
        if(value == null){
            // get default value
            value = DEFAULT_VALUES.get(id) as PropertyValueType?;
            if(value == null){
                throw new MyTools.MyException(Lang.format("No default value available for setting $1$", [settingId]));
            }
            self.set(settingId, value);
        }
        return value;
    }

    function set(settingId as SettingId, value as PropertyValueType) as Void{
        // update instance and app data
        var id = settingId as Number;
        var app = getApp();
        if (id <= SETTING_GLOBAL_MAX){
            globalData[id] = value;
            app.setProperty(SECTION_GLOBAL, globalData);
        }else if(id <= SETTING_PROFILE_MAX){
            profileData[id - SETTING_GLOBAL_MAX] = value;
            app.setProperty(getProfileSection() as Number, profileData);
        }
        // inform listeners
        if(onValueChange != null){
            onValueChange.invoke(settingId, value);
        }
    }

    // hidden helper functions:
    hidden function getProfileSection() as ProfileSection{
        var sport = get(SETTING_SPORT) as Activity.Sport;
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
}