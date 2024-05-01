import Toybox.Lang;

(:track)
class Waypoint{
    var name as String;
    var xy as XY;
    var z as Float?;
    var distance as Float; // referenced elapsed distance on track

    function initialize(waypointData as Array){
        name = waypointData[0] as String;
        xy = waypointData[1] as XY;
        z = waypointData[2] as Float?;
        distance = waypointData[3] as Float;
    }
}