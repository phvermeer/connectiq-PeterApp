import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Activity;
import MyViews;

class AltitudePickerDelegate extends MyViews.NumberPicker2Delegate{
	var parent as AltitudeCalibrationMenu;

	function initialize(picker as NumberPicker2, parent as AltitudeCalibrationMenu){
		NumberPicker2Delegate.initialize(picker);
		self.parent = parent;
	}

	function onNumberPicked(value as Number) as Void{
		parent.calibrate(value);
	}
}

class AltitudeCalibrationMenu extends MyMenu {
	hidden var options as Lang.Dictionary;
	hidden var calibration as Altitude.Calibration;
	hidden var altitude as Number = 0;

	function initialize(options as Dictionary){
		var settings = $.getApp().settings;
		var p0 = settings.get(SETTING_ALTITUDE_P0) as Float;
		var t0 = settings.get(SETTING_ALTITUDE_T0) as Float;
		calibration = new Altitude.Calibration(p0, t0);

		var info = Activity.getActivityInfo();
		if(info != null){
			var p = info.ambientPressure;
			if(p != null){
				var h = calibration.getAltitude(p);
				altitude = h.toNumber();
			}
		}

		MyMenu.initialize({ :title => WatchUi.loadResource(Rez.Strings.altitudeCalibration) as String });
		self.options = options;

		var id = SETTING_ALTITUDE_CALIBRATED;
		addItem(
			new WatchUi.ToggleMenuItem(
				WatchUi.loadResource(Rez.Strings.calibration) as String,
				{
					:enabled => (options.get(id) as Dictionary).get(true) as String,
					:disabled => (options.get(id) as Dictionary).get(false) as String,
				},
				id,
				getApp().settings.get(id) as Boolean,
				null
			)
		);

		id = SETTING_ALTITUDE_P0;
		addItem(
			new WatchUi.MenuItem(
				WatchUi.loadResource(Rez.Strings.altitude) as String,
				null,
				id,
				{}
			)
		);

	}

	function onShow(){
		// Update status of settings changed in sub menus
		// Altitude calibration state
		var id = SETTING_ALTITUDE_CALIBRATED;
		var enabled = getApp().settings.get(id) as Lang.Boolean;
		(getItem(0) as MenuItem).setSubLabel((options.get(id) as Dictionary).get(enabled) as String);

		// Current calibrated altitude
		(getItem(1) as MenuItem).setSubLabel(altitude.toString() as String);
	}

	// this could be modified or overridden for customization
	function onSelect(item as MenuItem) as Boolean{
		var id = item.getId() as SettingId;

		switch(id){
		
		// Option menus (auto/manual)
		case SETTING_ALTITUDE_CALIBRATED:
			// save toggled value
			var enabled = (item as ToggleMenuItem).isEnabled();
			var settings = $.getApp().settings;
			settings.set(SETTING_ALTITUDE_CALIBRATED, enabled);

			// update displayed altitude value
			var info = Activity.getActivityInfo();;
			if(info != null){
				var p = info.ambientPressure;
				if(p != null){
					altitude = Math.round(calibration.getAltitude(p)).toNumber();
				}
			}
			(getItem(1) as MenuItem).setSubLabel(altitude.toString() as String);
			break;

		// Select Number menu
		case SETTING_ALTITUDE_P0:
			var numberPicker = new MyViews.NumberPicker2(altitude);
			var delegate = new AltitudePickerDelegate(numberPicker, self);
			WatchUi.pushView(numberPicker, delegate, WatchUi.SLIDE_IMMEDIATE);
			break;
		default:
			return false;
		}
		return true;
	}

	function onBack() as Boolean{
		return false;
	}

	function calibrate(altitude as Number) as Void{
		var info = Activity.getActivityInfo();
		if(info != null){
			var p = info.ambientPressure;
			if(p != null){
				self.altitude = altitude;
				var results = calibration.calibrate(p, altitude.toFloat());

				var settings = $.getApp().settings;
				settings.set(SETTING_ALTITUDE_P0, results.get(:p0) as Float);
				settings.set(SETTING_ALTITUDE_T0, results.get(:t0) as Float);
			}
		}
	}
}