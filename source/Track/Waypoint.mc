import Toybox.Lang;

(:track)
class Waypoint{
    enum Type{
        TYPE_DEFAULT = 0,
        TYPE_PEAK = 1,
//        TYPE_FINISH = 2,
//        TYPE_PARKING = 3,
//        TYPE_CATERING = 4,
    }

    var name as String;
    var xy as XY;
    var z as Float?;
    var distance as Float; // referenced elapsed distance on track
    var type as Type;

    function initialize(waypointData as Array){
        name = waypointData[0] as String;
        xy = waypointData[1] as XY;
        z = waypointData[2] as Float?;
        distance = waypointData[3] as Float;
        type = waypointData[4] as Type;
    }
}