import Toybox.Lang;
import Toybox.Math;
import Toybox.Position;
import Toybox.Attention;
import Toybox.Graphics;
import MyBarrel.Math2;

(:noTrack)
function convertToTrack(rawData as Array|Dictionary) as Null{
	return null;
}

(:track)
function convertToTrack(rawData as Array|Dictionary) as Track|Null{
	try{
		// get version from data
		if(rawData instanceof Dictionary) {
			// ToDo
			return new Track(rawData as Dictionary);
		}else if(rawData instanceof Array){
			// old wormnav format
			return new TrackWormNav(rawData as Array);

		}else{
			throw new MyException("The Track data format is not recognized");
		}
	}catch(ex instanceof Lang.Exception){
		ex.printStackTrace();
		return null;
	}	

}

(:track)
class Track{
	// static track data
    var name as String;
    var distance as Float;
    var xyValues as Array<XY>;
	var zValues as Array<Float|Null>|Null;

	// boundaries and reference
	var latlonCenter as Array<Float>;
	var xMin as Float;
	var xMax as Float;
	var yMin as Float;
	var yMax as Float;
	var zMin as Float?;
	var zMax as Float?;

	// elapsed distances on track for each track point
    var distances as Array<Float>; // distance at index

	// waypoints
	var waypoints as Array<Waypoint> = [] as Array<Waypoint>;


	function initialize(data as Dictionary){
		// track data
		var trackData = data.get("TRACK") as Dictionary;

		name = 		   trackData.get("NAME") as String;
		distance =	   trackData.get("DISTANCE") as Float;
		latlonCenter = trackData.get("CENTER") as Array<Float>;
		xyValues = 	   trackData.get("POINTS") as Array<XY>;
		zValues = 	   trackData.get("ALTITUDES") as Array<Float|Null>|Null;
		distances =	   trackData.get("DISTANCES") as Array<Float>;
		var boundaries = trackData.get("BOUNDARIES") as Array<Float>;

		xMin = boundaries[0] as Float;
		xMax = boundaries[1] as Float;
		yMin = boundaries[2] as Float;
		yMax = boundaries[3] as Float;
		zMin = boundaries[4] as Float|Null;
		zMax = boundaries[5] as Float|Null;

		// waypoints
		var waypointsData = data.get("WAYPOINTS") as Array<Dictionary>;
		for(var i=0; i<waypointsData.size(); i++){
			var waypointData = waypointsData[i];
			waypoints.add(new Waypoint(waypointData));
		}

	}

	static function getColorAhead(darkMode as Boolean) as ColorType{
		return Graphics.COLOR_PINK;
	}
	static function getColorBehind(darkMode as Boolean) as ColorType{
		return Graphics.COLOR_GREEN;
	}
	static function getColor(darkMode as Boolean) as ColorType{
		return darkMode ? Graphics.COLOR_DK_GRAY : Graphics.COLOR_LT_GRAY;
	}
}