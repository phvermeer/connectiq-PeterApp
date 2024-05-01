import Toybox.Lang;

class WaypointDistanceField extends NumericField{
    hidden var trackManager as TrackManager;
    hidden var waypoint as Waypoint?;
    hidden var refreshLabel as Boolean = false;
    hidden var distancePrevWP as Float?;
    const NEXT_WAYPOINT_OFFSET = 100f; // distance after passing WP to switch to next WP

    function initialize(options as { :darkMode as Boolean }){
        self.trackManager = $.getApp().trackManager;

        NumericField.initialize(options);
        refreshWaypoint();
    }


    hidden function refreshWaypoint() as Void{
        var track = trackManager.track;

        if(track != null){
            var waypoints = track.waypoints;
            var currentDistance = (trackManager.elapsedDistance != null) ? trackManager.elapsedDistance as Float : 0f;
            distancePrevWP = null;

            // determine the next waypoint
            for(var i=0; i<waypoints.size(); i++){
                var wp = waypoints[i];
                if(wp.distance + NEXT_WAYPOINT_OFFSET >= currentDistance){
                    setWaypoint(wp);
                    return;
                }
                distancePrevWP = wp.distance;
            }

            // if no waypoints ahead, create finish as next waypoint
            var i = track.xyValues.size()-1;
            var wp = new Waypoint([
                WatchUi.loadResource(Rez.Strings.finish),
                track.xyValues[i] as XY,
                track.distance
            ]);
            setWaypoint(wp);
        }
    }

    hidden function setWaypoint(waypoint as Waypoint) as Void{
        self.waypoint = waypoint;

        // Update Label
        labelText = waypoint.name.toUpper();
        if(label != null){
            label.text = labelText;
        }
    }

    function onSetting(sender as Object, id as Settings.Id, value as Settings.ValueType) as Void{
        if(id == Settings.ID_TRACK){
            refreshWaypoint();
        }
    }

    function onPosition(trackManager as TrackManager, xy as XY?) as Void{
        // update distance to waypoint
        var distanceCurrent = trackManager.elapsedDistance;
        if(distanceCurrent != null && waypoint != null){
            if(distanceCurrent > waypoint.distance + NEXT_WAYPOINT_OFFSET || (distancePrevWP != null && distanceCurrent < distancePrevWP + NEXT_WAYPOINT_OFFSET)){
                refreshWaypoint();
            }
            if(waypoint != null){
                var distance = waypoint.distance - distanceCurrent;
                setValue(distance/1000);
            }else{
                setValue(null);
            }
        }else{
            setValue(null);
        }
    }
}