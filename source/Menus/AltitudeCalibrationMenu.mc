import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Activity;
import Toybox.Timer;
import MyBarrel.Views;

class AltitudePickerDelegate extends Views.NumberPicker2Delegate{
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
	const ITEM_CALIBRATE_ENABLE = 0;
	const ITEM_CALIBRATE_MANUAL = 1;
	const ITEM_CALIBRATE_AUTO = 2;

	hidden var options as Lang.Dictionary;
	hidden var calibration as Altitude.Calibration;
	hidden var altitude as Numeric?;
	var updateTimer as Timer.Timer = new Timer.Timer();

	function initialize(options as Dictionary){
		var settings = $.getApp().settings;
		var p0 = settings.get(SETTING_ALTITUDE_P0) as Float;
		var t0 = settings.get(SETTING_ALTITUDE_T0) as Float;

		calibration = new Altitude.Calibration({
			:p0 => p0,
			:t0 => t0,
			:listener => self,
		});

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
				ITEM_CALIBRATE_ENABLE,
				getApp().settings.get(SETTING_ALTITUDE_CALIBRATED) as Boolean,
				null
			)
		);

		addItem(
			new WatchUi.MenuItem(
				WatchUi.loadResource(Rez.Strings.manual) as String,
				"---",
				ITEM_CALIBRATE_MANUAL,
				{}
			)
		);

		addItem(
			new WatchUi.MenuItem(
					WatchUi.loadResource(Rez.Strings.auto) as String,
				"---",
				ITEM_CALIBRATE_AUTO,
				{}
			)
		);
	}

	function onShow(){
		// Update status of settings changed in sub menus
		var settings = $.getApp().settings;

		// Altitude calibration state
		var i = findItemById(ITEM_CALIBRATE_ENABLE);
		var item = getItem(i);
		if(item != null){
			var id = SETTING_ALTITUDE_CALIBRATED;
			var value = settings.get(id) as Lang.Boolean;
			var valueName = (options.get(id) as Dictionary).get(value) as String;
			item.setSubLabel(valueName);
		}

		// start getting current position to retrieve the sealevel temperature and altitude for current location
		calibration.start();

		// start timer to update altitude values
		onTimer();
		updateTimer.start(method(:onTimer), 2000, true);
	}

	function onHide(){
		calibration.stop();
		updateTimer.stop();
	}

	// this could be modified or overridden for customization
	function onSelect(item as MenuItem) as Boolean{
		var info = Activity.getActivityInfo();
		var settings = $.getApp().settings;

		switch(item.getId() as Number){
		
		// Option menus (auto/manual)
		case ITEM_CALIBRATE_ENABLE:
			// save toggled value
			var enabled = (item as ToggleMenuItem).isEnabled();
			settings.set(SETTING_ALTITUDE_CALIBRATED, enabled);

			// update displayed altitude value
			if(info != null){
				var p = info.ambientPressure;
				if(p != null){
					altitude = calibration.calculateAltitude(p).toNumber();
				}
			}
			break;

		// Select Number menu
		case ITEM_CALIBRATE_MANUAL:
			var numberPicker = new Views.NumberPicker2(altitude != null ? altitude.toNumber() : 0);
			var delegate = new AltitudePickerDelegate(numberPicker, self);
			WatchUi.pushView(numberPicker, delegate, WatchUi.SLIDE_IMMEDIATE);
			break;
		case ITEM_CALIBRATE_AUTO:
			if(info != null){
				var p = info.ambientPressure;
				var h = calibration.altitude;
				if(p != null && h != null){
					calibration.calibrate(p, h);
					settings.set(SETTING_ALTITUDE_P0, calibration.p0 as Float);
					settings.set(SETTING_ALTITUDE_T0, calibration.t0 as Float);
				}
			}
			break;
		default:
			return false;
		}
		return true;
	}

	function onBack() as Boolean{
		return false;
	}

	function calibrate(altitude as Numeric) as Void{
		var info = Activity.getActivityInfo();
		if(info != null){
			var p = info.ambientPressure;
			if(p != null){
				self.altitude = altitude;
				calibration.calibrate(p, altitude.toFloat());

				var settings = $.getApp().settings;
				settings.set(SETTING_ALTITUDE_P0, calibration.p0);
				settings.set(SETTING_ALTITUDE_T0, calibration.t0);
			}
		}
	}

	function onAltitude(altitude as Float, accuracy as Altitude.Calibration.Quality) as Void{
		var i = findItemById(ITEM_CALIBRATE_AUTO);
		if(i >= 0){
			var menuItem = getItem(i);
			if(menuItem != null){
				menuItem.setSubLabel(altitude.format("%i"));
				WatchUi.requestUpdate();
			}
		}
	}

	function updateSubLabel(itemId as Number, value as String|Numeric|Null) as Void{
		var i = findItemById(itemId);
		if(i>=0){
			var menuItem = getItem(i);
			var str = (value != null) ? value.toString() : "---";
			if(menuItem != null){
				menuItem.setSubLabel(str);
				WatchUi.requestUpdate();
			}
		}
	}
	function updateAltitudeManual(info as Activity.Info) as Void{
		// update altitude from pressure (Manual calibration)
		var newValue = null;
		var p = info.ambientPressure;
		if(p != null){
			newValue = calibration.calculateAltitude(p).toNumber();
		}

		// update menu item
		if(newValue != null && newValue != altitude){
			altitude = newValue;
			updateSubLabel(ITEM_CALIBRATE_MANUAL, altitude);
		}
	}

	function updateAltitudeAuto(altitude as Float, accuracy as Altitude.Calibration.Quality) as Void{
		updateSubLabel(ITEM_CALIBRATE_AUTO, altitude.toNumber());
	}

	function onTimer() as Void{
		var info = Activity.getActivityInfo();
		if(info != null){
			updateAltitudeManual(info);
		}
	}
}