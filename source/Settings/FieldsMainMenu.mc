import Toybox.Lang;
import Toybox.WatchUi;
using Toybox.Graphics;

(:basic)
class FieldsMainMenu extends ListMenu{
	hidden var settings as Settings;
	hidden var screenIndex as Number;
	hidden var fieldIndex as Number;

	function initialize(delegate as MyMenuDelegate, settings as Settings, screenIndex as Number, fieldIndex as Number){
		self.settings = settings;
		self.screenIndex = screenIndex;
		self.fieldIndex = fieldIndex;

		ListMenu.initialize(
			delegate,
			WatchUi.loadResource(Rez.Strings.dataFields) as String, // title
			[
				WatchUi.loadResource(Rez.Strings.distanceFields),
				WatchUi.loadResource(Rez.Strings.speedFields),
				WatchUi.loadResource(Rez.Strings.altitudeFields),
				WatchUi.loadResource(Rez.Strings.timeFields),
				WatchUi.loadResource(Rez.Strings.systemFields),
				WatchUi.loadResource(Rez.Strings.positioningFields),
				WatchUi.loadResource(Rez.Strings.healthFields),
				WatchUi.loadResource(Rez.Strings.pressureFields),
				WatchUi.loadResource(Rez.Strings.test)
			] as Array<String> // menuitems
		);

/*		
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
					DATAFIELD_TRACK_PROFILE => WatchUi.loadResource(Rez.Strings.profile),
					DATAFIELD_COMPASS => WatchUi.loadResource(Rez.Strings.compass),
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

			"systemFields" => {
				:title => WatchUi.loadResource(Rez.Strings.systemFields),
				:items => {
					DATAFIELD_CLOCK => WatchUi.loadResource(Rez.Strings.clock),
					DATAFIELD_MEMORY => WatchUi.loadResource(Rez.Strings.memory),
					DATAFIELD_BATTERY => WatchUi.loadResource(Rez.Strings.battery),
					DATAFIELD_STATUS => WatchUi.loadResource(Rez.Strings.status),
				},
			},

			"testFields" => {
				:title => WatchUi.loadResource(Rez.Strings.test),
				:items => {
					DATAFIELD_TEST => WatchUi.loadResource(Rez.Strings.test),
					DATAFIELD_EMPTY => WatchUi.loadResource(Rez.Strings.empty),
				},
			},
		};
*/
	}

 	function onSelect(sender as MyMenuDelegate, item as WatchUi.MenuItem) as Boolean {
		var id = item.getId() as String;

		if(id == 0){
			// distance field selection
			var menu = new DistanceFieldsMenu(sender, settings, screenIndex, fieldIndex);
			WatchUi.pushView(menu, sender, WatchUi.SLIDE_IMMEDIATE);
		}else if(id == 1){


		}
		return true;
	}
}