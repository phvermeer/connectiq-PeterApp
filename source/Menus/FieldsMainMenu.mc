import Toybox.Lang;
import Toybox.WatchUi;
using Toybox.Graphics;

class FieldsMainMenu extends MyMenu{
	hidden var fieldsSections as Dictionary;
	hidden var dataView as DataView;
	hidden var screenIndex as Number;
	hidden var screensSettings as DataScreensSettings;
	hidden var fieldIndex as Number;

	function initialize(dataView as DataView, screenIndex as Number, screensSettings as DataScreensSettings, fieldIndex as Number){
		self.dataView = dataView;
		self.screenIndex = screenIndex;
		self.screensSettings = screensSettings;
		self.fieldIndex = fieldIndex;

		MyMenu.initialize({
		  :title => WatchUi.loadResource(Rez.Strings.dataFields) as String
		});
		
		fieldsSections = {

			"timeFields" => {
				:title => WatchUi.loadResource(Rez.Strings.timeFields),
				:items => {
					DATAFIELD_ELAPSED_TIME => WatchUi.loadResource(Rez.Strings.time),
				},
			},

			"positioningFields" => {
				:title => WatchUi.loadResource(Rez.Strings.positioningFields),
				:items => {
					DATAFIELD_TRACK_MAP => WatchUi.loadResource(Rez.Strings.navigation),
					DATAFIELD_TRACK_OVERVIEW => WatchUi.loadResource(Rez.Strings.map),
//					DATAFIELD_"trackProfile" => WatchUi.loadResource(Rez.Strings.profile),
//					DATAFIELD_"compass" => WatchUi.loadResource(Rez.Strings.compass),
				},
			},
	
			"speedFields" => {
				:title => WatchUi.loadResource(Rez.Strings.speedFields),
				:items => {
					DATAFIELD_CURRENT_SPEED => WatchUi.loadResource(Rez.Strings.speed),
					DATAFIELD_AVG_SPEED => WatchUi.loadResource(Rez.Strings.avgSpeed),
					DATAFIELD_MAX_SPEED => WatchUi.loadResource(Rez.Strings.maxSpeed),
				},
			},

			"distanceFields" => {
				:title => WatchUi.loadResource(Rez.Strings.distanceFields),
				:items => {
					DATAFIELD_ELAPSED_DISTANCE => WatchUi.loadResource(Rez.Strings.distance),
					DATAFIELD_REMAINING_DISTANCE => WatchUi.loadResource(Rez.Strings.remainingDistance),
				},
			},

			"altitudeFields" => {
				:title => WatchUi.loadResource(Rez.Strings.altitudeFields),
				:items => {
					DATAFIELD_ALTITUDE => WatchUi.loadResource(Rez.Strings.altitude),
//					DATAFIELD_ELEVATION_SPEED => WatchUi.loadResource(Rez.Strings.elevationSpeed),
					DATAFIELD_TOTAL_ASCENT => WatchUi.loadResource(Rez.Strings.totalAscent),
					DATAFIELD_TOTAL_DESCENT => WatchUi.loadResource(Rez.Strings.totalDescent),
				},
			},

/*
			"lapFields" => {
				:title => WatchUi.loadResource(Rez.Strings.lapFields),
				:items => {
					"lapTime" => WatchUi.loadResource(Rez.Strings.time),
					"lapDistance" => WatchUi.loadResource(Rez.Strings.distance),
					"lapSpeed" => WatchUi.loadResource(Rez.Strings.speed),
				},
			},
*/

			"healthFields" => {
				:title => WatchUi.loadResource(Rez.Strings.healthFields),
				:items => {
					DATAFIELD_HEART_RATE => WatchUi.loadResource(Rez.Strings.heartRate),
					DATAFIELD_AVG_HEARTRATE => WatchUi.loadResource(Rez.Strings.avgHeartRate),
					DATAFIELD_MAX_HEARTRATE => WatchUi.loadResource(Rez.Strings.maxHeartRate),
					DATAFIELD_OXYGEN_SATURATION => WatchUi.loadResource(Rez.Strings.oxygenSaturation),
					DATAFIELD_ENERGY_RATE => WatchUi.loadResource(Rez.Strings.energyRate),
				},
			},

			"pressureFields" => {
				:title => WatchUi.loadResource(Rez.Strings.pressureFields),
				:items => {
					DATAFIELD_PRESSURE => WatchUi.loadResource(Rez.Strings.airPressure),
					DATAFIELD_SEALEVEL_PRESSURE => WatchUi.loadResource(Rez.Strings.seaLevelPressure),
				},
			},


/*			"systemFields" => {
				:title => WatchUi.loadResource(Rez.Strings.systemFields),
				:items => {
					"clock" => WatchUi.loadResource(Rez.Strings.clock),
					"memory" => WatchUi.loadResource(Rez.Strings.memory),
					"battery" => WatchUi.loadResource(Rez.Strings.battery),
					"counter" => WatchUi.loadResource(Rez.Strings.counter),
					"batteryConsumption" => WatchUi.loadResource(Rez.Strings.batteryConsumption),
				},
			},
*/			
			"testFields" => {
				:title => "Tests",
				:items => {
					DATAFIELD_TEST => "Test",
				},
			},
		};

		var keys = fieldsSections.keys();
		for(var i=0; i<keys.size(); i++){
			var id = keys[i] as String;
			var fieldsSection = fieldsSections.get(id) as Dictionary;
			addItem(
				new WatchUi.MenuItem(
					fieldsSection.get(:title) as String,
					null,
					id,
					{}
				)
			);
		}
	}

 	function onSelect(item as WatchUi.MenuItem) as Boolean {
		var id = item.getId() as String;
		var fieldsSection = fieldsSections.get(id) as Dictionary;
		
		// Go to submenu
		var subMenu = new FieldsSubMenu(
			fieldsSection as { :title  as String, :items as Dictionary } , 
			dataView, 
			screenIndex,
			screensSettings,
			fieldIndex
		);
		WatchUi.pushView(subMenu, subMenu.getDelegate(), WatchUi.SLIDE_IMMEDIATE);
		return true;
	}
}