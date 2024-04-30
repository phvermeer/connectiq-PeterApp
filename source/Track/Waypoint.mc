import Toybox.Lang;

(:track)
class Waypoint{
    var name as String;
    var xy as XY;
    var z as Float?;
    var distance as Float; // referenced elapsed distance on track

    function initialize(waypointData as Dictionary){
        name = waypointData.get("NAME") as String;
        xy = waypointData.get("POINT") as XY;
        z = waypointData.get("ALTITUDE") as Float?;
        distance = waypointData.get("DISTANCE") as Float;
    }
}