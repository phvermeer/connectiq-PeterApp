import Toybox.Lang;
import Toybox.Application;
import Toybox.Activity;

enum SettingDefinition{
	// Current Profile / Sport
	SETTING_SPORT = "Sp",
	
	// Global settings
	SETTING_TRACK_DATA = "trackData",
	SETTING_TRACK_ZOOM = "Zl",

	// Profile settings for each sport INPUT: Activity.Sport OUTPUT EXAMPLE: "P11Bg"
	SETTING_AUTO_LAP_ENABLED = "AlEn",
	SETTING_AUTO_LAP_DISTANCE = "AlDi",
	SETTING_AUTO_PAUSE_ENABLED = "ApEn",
	SETTING_BACKGROUND_COLOR = "BgCl",
	SETTING_SCREEN_COUNT = "Sc",
	SETTING_BREADCRUMPS_ENABLED = "BcEn",
	SETTING_BREADCRUMPS_MIN_DISTANCE = "BcDi",
	SETTING_BREADCRUMPS_MAX_COUNT = "BcCn",
	
	// screen settings uses PREFIX_SCREEN
	SETTING_SCREEN_ENABLED = "En",
	SETTING_SCREEN_LAYOUT = "Sl",
	SETTING_SCREEN_FIELDS = "Sf",
}

class Settings{
	private enum SettingsPrefix{
		PREFIX_PROFILE = "$1$_",		// INPUT: [sport as Number]
		PREFIX_SCREEN = "$1$_S$2$_", 	// INPUT: [sport as Number, ScreenIndex as Number]
	}
	
	const DEFAULT_VALUES = {
		SETTING_SPORT => Activity.SPORT_WALKING,
		SETTING_TRACK_ZOOM => 1.0,
		SETTING_BACKGROUND_COLOR => Graphics.COLOR_WHITE,
		SETTING_AUTO_LAP_ENABLED => true,
		SETTING_AUTO_LAP_DISTANCE => 1000,
		SETTING_AUTO_PAUSE_ENABLED => true,
		SETTING_BREADCRUMPS_ENABLED => true,
		SETTING_BREADCRUMPS_MIN_DISTANCE => 50,
		SETTING_BREADCRUMPS_MAX_COUNT => 50,
		SETTING_SCREEN_COUNT => 1,
		SETTING_SCREEN_ENABLED => true,
		SETTING_SCREEN_LAYOUT => LAYOUT_ONE_FIELD,
		SETTING_SCREEN_FIELDS => ["clock"],
	};

	hidden var onChange as Null | Method(screenIndex as Number?, id as String, value as PropertyValueType) as Void;
	hidden var sport as Sport = Activity.SPORT_WALKING;

	function initialize(options as {
		:onChange as Method(screenId as Number?, paramId as String, value as PropertyValueType) as Void,
	}){
		// load the properties
		$.getApp().loadProperties();
		
		// set the profile / sport
		var sport = getValue("", SETTING_SPORT) as Sport;
		setProfile(sport);

		// assign listeners
		if(options.hasKey(:onChange)){
			onChange = options.get(:onChange) as Method(screenId as Number?, paramId as String, value as PropertyValueType) as Void;
		}
	}
	
	function clear() as Void{
		$.getApp().clearProperties();
	}

	// raw values
	hidden function getValue(prefix as String, key as String) as PropertyValueType{
		var value = $.getApp().getProperty(prefix + key);
		if(value != null){
			return value;
		}else{
			return DEFAULT_VALUES.get(key as String);
		}		
	}
	hidden function setValue(prefix as String, key as String, value as PropertyValueType) as Void{
		var app = $.getApp();
		app.setProperty(prefix + key, value);
	}
	
	// listeners
	function setListener(callback as Method(screenId as Number?, paramId as String, value as PropertyValueType) as Void) as Void{
		self.onChange = callback;
	}
	
	// functions to access the settings
	hidden function save() as Void{
		$.getApp().saveProperties();
	}
	
	function getSetting(id as String) as PropertyValueType {
		if(id == SETTING_SPORT){
			return sport;
		}

		var prefix = 
			id.equals(SETTING_TRACK_ZOOM) || id.equals(SETTING_TRACK_DATA)
			? ""
			: Lang.format(PREFIX_PROFILE, [sport]);

		return getValue(prefix, id);
	}
	function setSetting(id as String, value as PropertyValueType) as Void {
		var prefix;
		if(id == SETTING_SPORT){
			if(value == sport){
				return;
			}
			setProfile(value as Sport);
			prefix = "";
		}else{
			prefix = id.equals(SETTING_TRACK_ZOOM) || id.equals(SETTING_TRACK_DATA) ?
				 "" :
				Lang.format(PREFIX_PROFILE, [sport]);
		}
		setValue(prefix, id, value);
		save();
		
		if(onChange != null) {
			onChange.invoke(null, id, value);
		}
	}
	
	function getScreenSetting(screenIndex as Number, id as String) as PropertyValueType {
		var prefix = Lang.format(PREFIX_SCREEN, [sport, screenIndex]);
		return getValue(prefix, id);
	}	
	function setScreenSetting(screenIndex as Number, id as String, value as PropertyValueType) as Void {
		var prefix = Lang.format(PREFIX_SCREEN, [sport, screenIndex]);
		setValue(prefix, id, value);
		save();
		
		if(onChange != null) {
			onChange.invoke(screenIndex, id, value); 
		}
	}
	function deleteScreen(screenIndex as Lang.Number) as Void{
		// shift settings of screens with a higher index to fill the gap
		var count = getSetting(SETTING_SCREEN_COUNT) as Number;
		var ids = [
			SETTING_SCREEN_ENABLED,
			SETTING_SCREEN_LAYOUT,
		] as Array<String>;
		
		var id;
		var prefixOld = Lang.format(PREFIX_SCREEN, [sport, screenIndex]);
		var prefixNew;
		
		for(var si=screenIndex; si<count; si++){
			prefixNew = prefixOld;
			prefixOld = Lang.format(PREFIX_SCREEN, [sport, si+1]);
			for(var i=0; i<ids.size(); i++){
				id = ids[i];
				setValue(prefixNew, id, getValue(prefixOld, id));
			}
		}
		// remove absolete settings
		var app = $.getApp();
		for(var i=0; i<ids.size(); i++){
			id = ids[i];
			app.deleteProperty(prefixOld + id);
		}
		
		//decrease the screen counter
		var prefix = Lang.format(PREFIX_PROFILE, [sport]);
		setValue(prefix, SETTING_SCREEN_COUNT, count-1);
		save();
	}
	
	// special setter for the sport to change profile
	protected function setProfile(sport as Activity.Sport) as Void{
		if(self.sport != sport){
			self.sport = sport;
			setValue("", SETTING_SPORT, sport as Number);
			
			// notify listeners with all new settings
			if(onChange != null){
				// normal settings (for each profile/sport)
				var notifier = onChange as Method;
				notifier.invoke({ :id => SETTING_SPORT, :value => sport });
				var prefix = Lang.format(PREFIX_PROFILE, [sport]);
				var ids = [
					SETTING_AUTO_LAP_ENABLED,
					SETTING_AUTO_LAP_DISTANCE,
					SETTING_AUTO_PAUSE_ENABLED,
					SETTING_BREADCRUMPS_ENABLED,
					SETTING_BREADCRUMPS_MIN_DISTANCE,
					SETTING_BREADCRUMPS_MAX_COUNT,					
					SETTING_BACKGROUND_COLOR,
					SETTING_SCREEN_COUNT,
				] as Array<String>;
				for(var i=0; i<ids.size(); i++){
					var id = ids[i];
					notifier.invoke({ :id => id, :value => getValue(prefix, id) });
				}
				
				// screen settings (foreach profile/sport and screen)
				prefix = Lang.format(PREFIX_PROFILE, [sport]);
				ids = [
					SETTING_SCREEN_ENABLED,
					SETTING_SCREEN_LAYOUT,
				] as Array<String>;
				var count = getValue(prefix, SETTING_SCREEN_COUNT) as Number;
				for(var si=0; si<count; si++){
					prefix = Lang.format(PREFIX_SCREEN, [sport, si]);
					for(var i=0; i<ids.size(); i++){
						var id = ids[i];
						notifier.invoke({ :screenIndex => si, :id => id, :value => getValue(prefix, id) });
					}
				}
			}
		}
	}
}
