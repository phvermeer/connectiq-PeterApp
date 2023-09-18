import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Graphics;
using Toybox.System;
using Toybox.Activity;

class MainMenu extends MyMenu {
	
	const OPTIONS = {
		SETTING_BACKGROUND_COLOR => {
			Graphics.COLOR_WHITE => WatchUi.loadResource(Rez.Strings.white) as String,
			Graphics.COLOR_BLACK => WatchUi.loadResource(Rez.Strings.black) as String,
		},
		SETTING_SPORT => {
			Activity.SPORT_WALKING => WatchUi.loadResource(Rez.Strings.walking) as String,
			Activity.SPORT_HIKING => WatchUi.loadResource(Rez.Strings.hiking) as String,
			Activity.SPORT_RUNNING => WatchUi.loadResource(Rez.Strings.running) as String,
			Activity.SPORT_CYCLING => WatchUi.loadResource(Rez.Strings.cycling) as String,
		},
		SETTING_AUTOLAP => {
			false => WatchUi.loadResource(Rez.Strings.off) as String,
			true => WatchUi.loadResource(Rez.Strings.on) as String,
		},
		SETTING_AUTOPAUSE => {
			false => WatchUi.loadResource(Rez.Strings.off) as String,
			true => WatchUi.loadResource(Rez.Strings.on) as String,
		},
        
		SETTING_AUTOLAP_DISTANCE => {
			100 => "100m",
			200 => "200m",
			500 => "500m",
			1000 => "1km",
			2000 => "2km",		
			5000 => "5km",		
			10000 => "10km",		
		},
		SETTING_BREADCRUMPS => {
			false => WatchUi.loadResource(Rez.Strings.off) as String,
			true => WatchUi.loadResource(Rez.Strings.on) as String,
		},
		SETTING_BREADCRUMPS_MIN_DISTANCE => {
			10 => "10m",
			20 => "20m",
			50 => "50m",
			100 => "100m",
			200 => "200m",
			500 => "500m",
		},
		SETTING_BREADCRUMPS_MAX_COUNT => {
			10 => "10",
			20 => "20",
			50 => "50",
			100 => "100",
			200 => "200",
		},
		SETTING_ALTITUDE_CALIBRATED => {
			false => WatchUi.loadResource(Rez.Strings.off) as String,
			true => WatchUi.loadResource(Rez.Strings.on) as String,
		}
	};
	

	function initialize(){
		MyMenu.initialize({ :title => WatchUi.loadResource(Rez.Strings.settings) as String });
		
		addItem( // index 0
			new WatchUi.MenuItem(
				WatchUi.loadResource(Rez.Strings.dataScreens) as String,
				null,
				"dataScreensMenu",
				{}
			)
		);

		var id = SETTING_SPORT;
		addItem( // index 1
			new WatchUi.MenuItem(
				WatchUi.loadResource(Rez.Strings.activity) as String,
				null,
				id,
				{}
			)
		);

		addItem(// index 2
			new WatchUi.MenuItem(
				WatchUi.loadResource(Rez.Strings.altitudeCalibration) as String,
				null,
				"altitudeCalibration",
				{}
			)
		);

		id = SETTING_BACKGROUND_COLOR;
		addItem(// index 3
			new WatchUi.MenuItem(
				WatchUi.loadResource(Rez.Strings.backgroundColor) as String,
				null,
				id,
				{}
			)
		);

		addItem(// index 4
			new WatchUi.MenuItem(
				WatchUi.loadResource(Rez.Strings.autoLap) as String,
				null,
				"autoLapSubmenu",
				{}
			)
		);
		
		addItem(// index 5
			new WatchUi.MenuItem(
				WatchUi.loadResource(Rez.Strings.breadcrumps) as String,
				null,
				"breadcrumpsSubmenu",
				{}
			)
		);

		id = SETTING_AUTOPAUSE;
		addItem(// index 6
			new WatchUi.ToggleMenuItem(
				WatchUi.loadResource(Rez.Strings.autoPause) as String,
				{
					:enabled => (OPTIONS.get(id) as Dictionary).get(true) as String,
					:disabled => (OPTIONS.get(id) as Dictionary).get(false) as String,
				} ,
				id,
				getApp().settings.get(id) as Boolean,
				{}
			)
		);
		
		addItem(// index 7
			new WatchUi.MenuItem(
				WatchUi.loadResource(Rez.Strings.clearTrack) as String,
				null,
				"clearTrack",
				{}
			)
		);
		addItem(// index 8
			new WatchUi.MenuItem(
				WatchUi.loadResource(Rez.Strings.clearSettings) as String,
				null,
				"clearSettings",
				{}
			)
		);

	}

	function getCurrentValueText(id as SettingId) as String{
		var value = getApp().settings.get(id) as String or Numeric or Boolean;
		return (OPTIONS.get(id as Number) as Dictionary).get(value) as String;
	}

	function onShow(){
		var settings = getApp().settings;
		// Update sub titles with values of settings changed in sub menus
		// Sport
		(getItem(1) as MenuItem).setSubLabel(getCurrentValueText(SETTING_SPORT));

		// Altitude Calibration
		var enabled = settings.get(SETTING_ALTITUDE_CALIBRATED) as Boolean;
		var subLabel = (OPTIONS.get(SETTING_ALTITUDE_CALIBRATED) as Dictionary).get(enabled) as String;
		(getItem(2) as MenuItem).setSubLabel(subLabel);

		// Background Color
		(getItem(3) as MenuItem).setSubLabel(getCurrentValueText(SETTING_BACKGROUND_COLOR));

		// Auto Lap
		enabled = settings.get(SETTING_AUTOLAP) as Boolean;
		var distance = settings.get(SETTING_AUTOLAP_DISTANCE) as Float;
		subLabel = enabled
			? (OPTIONS.get(SETTING_AUTOLAP_DISTANCE) as Dictionary).get(distance) as String
			: (OPTIONS.get(SETTING_AUTOLAP) as Dictionary).get(enabled) as String;
		(getItem(4) as MenuItem).setSubLabel(subLabel);

		// Breadcrump Distance
		enabled = settings.get(SETTING_BREADCRUMPS) as Boolean;
		var count = settings.get(SETTING_BREADCRUMPS_MAX_COUNT) as Number;
		distance = settings.get(SETTING_BREADCRUMPS_MIN_DISTANCE) as Number;
		subLabel = enabled
			? Lang.format("$1$ x $2$m", [count, distance])
			: (OPTIONS.get(SETTING_BREADCRUMPS) as Dictionary).get(enabled) as String;
		(getItem(5) as MenuItem).setSubLabel(subLabel);
	}
	
	// this could be modified or overridden for customization
	function onSelect(item) as Boolean{
		var id = item.getId() as SettingId;

		// Toggle menu items
		if(item instanceof ToggleMenuItem){
			var enabled = (item as ToggleMenuItem).isEnabled();
			getApp().settings.set(id, enabled); 
		}

		var result = true;
		switch(id){
	
			// DataScreens menu
			case "dataScreensMenu":
				{
					var menu = new DataScreensMenu();
					WatchUi.pushView(menu, menu.getDelegate(), WatchUi.SLIDE_IMMEDIATE);
					break;
				}
			// Option menus
			case SETTING_SPORT:
			case SETTING_BACKGROUND_COLOR:
			{
				var menu = new MyOptionsMenu(
					WatchUi.loadResource(Rez.Strings.backgroundColor) as String,
					id,
					OPTIONS.get(id as Number) as Dictionary
				);
				WatchUi.pushView(menu, menu.getDelegate(), WatchUi.SLIDE_IMMEDIATE);
				break;
			}
			
			// Sub menus
			case "altitudeCalibration":
			{
				var menu = new AltitudeCalibrationMenu(OPTIONS);
				WatchUi.pushView(menu, menu.getDelegate(), WatchUi.SLIDE_IMMEDIATE);
				break;
			}

			case "autoLapSubmenu":
			{
				var menu = new AutoLapMenu(OPTIONS);
				WatchUi.pushView(menu, menu.getDelegate(), WatchUi.SLIDE_IMMEDIATE);
				break;
			}

			case "breadcrumpsSubmenu":
			{
				var menu = new BreadcrumpsMenu(OPTIONS);
				WatchUi.pushView(menu, menu.getDelegate(), WatchUi.SLIDE_IMMEDIATE);
				break;
			}
			case "clearTrack":
				var app = getApp();
				app.track = null;
				app.settings.set(SETTING_TRACK, null);
				break;
			case "clearSettings":
				getApp().settings.clear();
				break;

			default:
				result = false;
		}
		return result;

	}
}