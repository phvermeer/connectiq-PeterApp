import Toybox.Lang;
import Toybox.WatchUi;
using Toybox.Graphics;

(:basic)
class FieldsMainMenu extends MyMenu{
	hidden var settings as Settings;
	hidden var screenIndex as Number;
	hidden var fieldIndex as Number;

	function initialize(delegate as MyMenuDelegate, settings as Settings, screenIndex as Number, fieldIndex as Number){
		self.settings = settings;
		self.screenIndex = screenIndex;
		self.fieldIndex = fieldIndex;

		MyMenu.initialize(
			delegate, 
			{
				:title => WatchUi.loadResource(Rez.Strings.dataFields) as String
			}
		);

		var itemNames = [
			WatchUi.loadResource(Rez.Strings.distanceFields),
			WatchUi.loadResource(Rez.Strings.speedFields),
			WatchUi.loadResource(Rez.Strings.altitudeFields),
			WatchUi.loadResource(Rez.Strings.timeFields),
			WatchUi.loadResource(Rez.Strings.systemFields),
			WatchUi.loadResource(Rez.Strings.positioningFields),
			WatchUi.loadResource(Rez.Strings.healthFields),
			WatchUi.loadResource(Rez.Strings.pressureFields),
			WatchUi.loadResource(Rez.Strings.test)
		] as Array<String>;

		for(var id=0; id<itemNames.size(); id++){
			// add menu items
			addItem(
				new WatchUi.MenuItem(
					itemNames[id] as String,
					null,
					id,
					{}
				)
			);
		}
	}

 	function onSelect(sender as MyMenuDelegate, item as WatchUi.MenuItem) as Boolean {
		var id = item.getId() as String;
		var menu = null;
		if(id == 0){
			menu = new FieldsSubMenu(
				sender, settings, screenIndex, fieldIndex,
				WatchUi.loadResource(Rez.Strings.distanceFields) as String,
				{
					DATAFIELD_ELAPSED_DISTANCE => WatchUi.loadResource(Rez.Strings.distance),
					DATAFIELD_REMAINING_DISTANCE => WatchUi.loadResource(Rez.Strings.remainingDistance),
				}
			);
		}else if(id == 1){
			menu = new FieldsSubMenu(
				sender, settings, screenIndex, fieldIndex,
				WatchUi.loadResource(Rez.Strings.speedFields) as String,
				{
					DATAFIELD_CURRENT_SPEED => WatchUi.loadResource(Rez.Strings.speed),
					DATAFIELD_AVG_SPEED => WatchUi.loadResource(Rez.Strings.avgSpeed),
					DATAFIELD_MAX_SPEED => WatchUi.loadResource(Rez.Strings.maxSpeed),
				}
			);
		}else if(id == 2){
			menu = new FieldsSubMenu(
				sender, settings, screenIndex, fieldIndex,
				WatchUi.loadResource(Rez.Strings.altitudeFields) as String,
				{
					DATAFIELD_ALTITUDE => WatchUi.loadResource(Rez.Strings.altitude),
//					DATAFIELD_ELEVATION_SPEED => WatchUi.loadResource(Rez.Strings.elevationSpeed),
					DATAFIELD_TOTAL_ASCENT => WatchUi.loadResource(Rez.Strings.totalAscent),
					DATAFIELD_TOTAL_DESCENT => WatchUi.loadResource(Rez.Strings.totalDescent),
				}
			);
		}else if(id == 3){
			menu = new FieldsSubMenu(
				sender, settings, screenIndex, fieldIndex,
				WatchUi.loadResource(Rez.Strings.timeFields) as String,
				{
					DATAFIELD_ELAPSED_TIME => WatchUi.loadResource(Rez.Strings.time),
				}
			);
		}else if(id == 4){
			menu = new FieldsSubMenu(
				sender, settings, screenIndex, fieldIndex,
				WatchUi.loadResource(Rez.Strings.systemFields) as String,
				{
					DATAFIELD_CLOCK => WatchUi.loadResource(Rez.Strings.clock),
					DATAFIELD_MEMORY => WatchUi.loadResource(Rez.Strings.memory),
					DATAFIELD_BATTERY => WatchUi.loadResource(Rez.Strings.battery),
					DATAFIELD_STATUS => WatchUi.loadResource(Rez.Strings.status),
				}
			);
		}else if(id == 5){
			menu = new FieldsSubMenu(
				sender, settings, screenIndex, fieldIndex,
				WatchUi.loadResource(Rez.Strings.positioningFields) as String,
				{
					DATAFIELD_TRACK_MAP => WatchUi.loadResource(Rez.Strings.navigation),
					DATAFIELD_TRACK_OVERVIEW => WatchUi.loadResource(Rez.Strings.map),
					DATAFIELD_TRACK_PROFILE => WatchUi.loadResource(Rez.Strings.profile),
					DATAFIELD_COMPASS => WatchUi.loadResource(Rez.Strings.compass),
				}
			);
		}else if(id == 6){
			menu = new FieldsSubMenu(
				sender, settings, screenIndex, fieldIndex,
				WatchUi.loadResource(Rez.Strings.healthFields) as String,
				{
					DATAFIELD_HEART_RATE => WatchUi.loadResource(Rez.Strings.heartRate),
					DATAFIELD_AVG_HEARTRATE => WatchUi.loadResource(Rez.Strings.avgHeartRate),
					DATAFIELD_MAX_HEARTRATE => WatchUi.loadResource(Rez.Strings.maxHeartRate),
					DATAFIELD_OXYGEN_SATURATION => WatchUi.loadResource(Rez.Strings.oxygenSaturation),
					DATAFIELD_ENERGY_RATE => WatchUi.loadResource(Rez.Strings.energyRate),
				}
			);
		}else if(id == 7){
			menu = new FieldsSubMenu(
				sender, settings, screenIndex, fieldIndex,
				WatchUi.loadResource(Rez.Strings.pressureFields) as String,
				{
					DATAFIELD_PRESSURE => WatchUi.loadResource(Rez.Strings.airPressure),
					DATAFIELD_SEALEVEL_PRESSURE => WatchUi.loadResource(Rez.Strings.seaLevelPressure),
				}
			);
		}else if(id == 8){
			menu = new FieldsSubMenu(
				sender, settings, screenIndex, fieldIndex,
				WatchUi.loadResource(Rez.Strings.test) as String,
				{
					DATAFIELD_TEST => WatchUi.loadResource(Rez.Strings.test),
					DATAFIELD_EMPTY => WatchUi.loadResource(Rez.Strings.empty),
				}
			);
		}

		if(menu != null){
			WatchUi.pushView(menu, sender, WatchUi.SLIDE_IMMEDIATE);
			return true;
		}else{
			return false;
		}
	}
}