import Toybox.Position;
import Toybox.Activity;
import Toybox.System;
import Toybox.Lang;
import Toybox.Timer;

(:basic)
class Data
{
    public var activityInfo as Activity.Info|Null;
    public var stats as System.Stats;
    hidden var timerStarted as Boolean = false;
    hidden var timer as Timer.Timer = new Timer.Timer();

    function initialize(options as Dictionary){
        activityInfo = Activity.getActivityInfo();
        stats = System.getSystemStats();
    }
    function startTimer() as Void{
        if(!timerStarted){
            // start timer events
            timer.start(method(:onTimer), 1000, true);
            timerStarted = true;
        }
    }
    function stopTimer() as Void{
        if(timerStarted){
            // stop timer events
            timer.stop();
            timerStarted = false;
        }
    }
    function onTimer() as Void{
        var info = Activity.getActivityInfo();
        if(info != null){
            // process info
            self.stats = System.getSystemStats();
            self.activityInfo = info;
        }
    }
}    

(:advanced)
class Data
{
   	static const EARTH_RADIUS = 6371000f;
    typedef XyPoint as Array<Float>;
    typedef IListener as interface{
        function onData(data as Data) as Void;
    };
    class Listener{
        function onData(data as Data) as Void{}
    }

    public var positionInfo as Position.Info;
    public var activityInfo as Activity.Info|Null;
    public var stats as System.Stats;

    hidden var track as Track?;
    public var xy as XyPoint|Null;

    hidden var listeners as Array<WeakReference> = [] as Array<WeakReference>;
    hidden var timerStarted as Boolean = false;
    hidden var positioningStarted as Boolean = false;
    hidden var eventReceived as Boolean = false;

    // settings
    hidden var interval as Number;
    hidden var breadcrumpsEnabled as Boolean;
    hidden var breadcrumps as Array<XyPoint|Null> = [] as Array<XyPoint|Null>;
    hidden var breadcrumpsDistance as Number;
    hidden var breadcrumpsMax as Number;

    hidden var latlonCenter as Array<Decimal>|Null;
    hidden var timer as Timer.Timer = new Timer.Timer();

    // Collector of historical position data in a register
    function initialize(options as {
        :breadcrumpsEnabled as Boolean,
        :breadcrumpsMax as Number, // max number of breadcrumps
        :breadcrumpsDistance as Number, // minimal distance [m] between 2 archived points
        :latCenter as Decimal,
        :lonCenter as Decimal,
    }){
        breadcrumpsMax = options.hasKey(:breadcrumpsMax) ? options.get(:breadcrumpsMax) as Number : 50;
        breadcrumpsDistance = options.hasKey(:breadcrumpsDistance) ? options.get(:breadcrumpsDistance) as Number : 50;
        breadcrumpsEnabled = options.hasKey(:breadcrumpsEnabled) ? options.get(:breadcrumpsEnabled) as Boolean : true;
        interval = options.hasKey(:interval) ? options.get(:interval) as Number : 5000;
        track = options.get(:track) as Track|Null;

        activityInfo = Activity.getActivityInfo();
        positionInfo = Position.getInfo();
        stats = System.getSystemStats();
    }

    function startTimer() as Void{
        if(!timerStarted){
            // start timer events
            timer.start(method(:onTimer), interval, true);
            timerStarted = true;
            eventReceived = false;
        }
    }
    function stopTimer() as Void{
        if(timerStarted){
            // stop timer events
            timer.stop();
            timerStarted = false;
        }
    }

    function startPositioning() as Void{
        if(!positioningStarted){
            // start positioning events
            Position.enableLocationEvents(
                { :acquisitionType => Position.LOCATION_CONTINUOUS },
                method(:onPosition)
            );
            positioningStarted = true;
        }
    }

    function stopPositioning() as Void{
        if(positioningStarted){
            // stop positioning events
            Position.enableLocationEvents({
                :acquisitionType => Position.LOCATION_DISABLE,
            }, method(:onPosition));
            positioningStarted = false;
        }
    }

    // Settings
    function onSetting(id as Settings.Id, value as Settings.ValueType) as Void{
        if(id == Settings.ID_BREADCRUMPS){
            setBreadcrumpsEnabled(value as Boolean);
        }else if(id == Settings.ID_BREADCRUMPS_MAX_COUNT){
            setBreadcrumpsMax(value as Number);
        }else if(id == Settings.ID_BREADCRUMPS_MIN_DISTANCE){
            setBreadcrumpsDistance(value as Number);
        }else if(id == Settings.ID_TRACK){
            setTrack(value as Track|Null);
        }
    }

    function setInterval(interval as Number) as Void{
        var doRestart = (timerStarted && interval != self.interval);
        self.interval = interval;
        if(doRestart){
            // restart timer with new interval
            stopTimer();
            startTimer();
        }
    }

    function setBreadcrumpsMax(max as Number) as Void{
        self.breadcrumpsMax = max;
        checkBreadcrumpsMax();
    }

    function setTrack(track as Track|Null) as Void{
        self.track = track;

        // update xy center
        if(track != null){
            setCenter(track.latlonCenter);
        }else{
            var position = self.positionInfo.position;
            if(position != null){
                var latlon = position.toRadians();
                setCenter(latlon);
            }
        }
    }

    hidden function checkBreadcrumpsMax() as Void{
        var size = breadcrumps.size();
        if(size > breadcrumpsMax){
            breadcrumps = breadcrumps.slice(size-breadcrumpsMax, null);
        }
    }

    hidden function setBreadcrumpsDistance(distance as Number) as Void{
        breadcrumpsDistance = distance;
    }

    hidden function setBreadcrumpsEnabled(enabled as Boolean) as Void{
        breadcrumpsEnabled = enabled;
        if(!enabled){
            breadcrumps = [] as Array<XyPoint>;
        }else{
            if(xy != null){
                breadcrumps.add(xy);
            }
        }
    }

    hidden function setCenter(latlon as Array<Decimal>) as Void{
        if(latlonCenter != null){
            if(latlonCenter[0] != latlon[0] || latlonCenter[1] != latlon[1]){
                // update current xy points with new center position
                // determine the xyOffset between old and new lat lon positions
                var xyOffset = getXYbetweenPoints(latlonCenter, latlon);
                var dx = xyOffset[0];
                var dy = xyOffset[1];

                // breadcrump points
                for(var i=0; i<breadcrumps.size(); i++){
                    var xy = breadcrumps[i];
                    if(xy != null){
                        breadcrumps[i] = [xy[0]-dx, xy[1]-dy] as XyPoint;
                    }
                }

                // current position
                if(xy != null){
                    xy[0] -= dx;
                    xy[1] -= dy;
                }
            }
        }
        // save new center position
        latlonCenter = latlon;
    }

    hidden function updateBreadcrumps(xyPrev as XyPoint|Null, xyNew as XyPoint|Null) as Void{
        if(breadcrumpsEnabled){
            // get distance between new point and last recorded point
            var count = breadcrumps.size();
            if(count > 0){
                var breadcrump = breadcrumps[count-1] as XyPoint?;
                if(breadcrump != null){
                    if(xyNew != null){
                        // calculate distance from previous point
                        var dx = xyNew[0] - breadcrump[0];
                        var dy = xyNew[1] - breadcrump[1];
                        var distance = Math.sqrt(dx*dx + dy*dy);            
                        if(distance >= breadcrumpsDistance){
                            addBreadcrump(xyNew);
                        }
                    }else{
                        // position lost
                        if(breadcrump != xyPrev){
                            addBreadcrump(xyPrev);
                            addBreadcrump(null);
                        }
                    }
                }else{
                    if(xyNew != null){
                        // position recovered
                        addBreadcrump(xyNew);
                    }
                }
            }else{
                if(xyNew != null){
                    // first position
                    addBreadcrump(xyNew);
                }
            }
        }
    }
    
    function onTimer() as Void{
        if(!eventReceived){
            // slow update when no position events are received within timer
            var info = Activity.getActivityInfo();
            if(info != null){
                // process info
                var stats = System.getSystemStats();
                setInfo(null, info, stats);
            }
        }else{
            eventReceived = false;
        }
    }

    function onPosition(info as Position.Info) as Void{
        // transform to xy
        var position = info.position;
        if(info.accuracy >= Position.QUALITY_POOR && position != null){
            eventReceived = true;
            setInfo(info, Activity.getActivityInfo(), System.getSystemStats());
            notifyListeners();
        }
    }

    hidden function setInfo(positionInfo as Position.Info|Null, activityInfo as Activity.Info|Null, stats as Stats) as Void{
        // position info
        var xy = null;
        if(positionInfo != null){
            self.positionInfo = positionInfo;

            // position => xy
            var position = positionInfo.position;
            if(positionInfo.accuracy >= Position.QUALITY_POOR && position != null){
                var latlon = position.toRadians();
                xy = calculateXY(latlon);

                // update track (do not wait for listeners events to update position on track)
                if(track != null){
                    track.setCurrentXY(xy[0], xy[1]);
                }
            }
        }
        updateBreadcrumps(self.xy, xy);

        // keep last point
        self.xy = xy;

        // activity info
        if(activityInfo != null){
            // update altitude
            self.activityInfo = activityInfo;
        }

        // system stats
        self.stats = stats;

        // notify listeners
        notifyListeners();
    }

    hidden function addBreadcrump(xy as XyPoint|Null) as Void{
        breadcrumps.add(xy);
        checkBreadcrumpsMax();
    }

    function getBreadcrumps() as Array<XyPoint|Null>{
        return breadcrumps;
    }

    hidden function calculateXY(latlon as Array<Decimal>) as XyPoint{
        if(latlonCenter != null){
            return getXYbetweenPoints(latlonCenter, latlon);
        }else{
            latlonCenter = latlon;
            return [0f, 0f] as XyPoint;
        }
    }

    hidden function getXYbetweenPoints(latlon1 as Array<Decimal>, latlon2 as Array<Decimal>) as XyPoint{
        var lat1 = latlon1[0];
        var lon1 = latlon1[1];
        var lat2 = latlon2[0];
        var lon2 = latlon2[1];
        var x = EARTH_RADIUS * (Math.cos(lat2)*Math.sin(lon2-lon1)).toFloat();
        var y = -EARTH_RADIUS * (Math.cos(lat1)*Math.sin(lat2) - Math.sin(lat1)*Math.cos(lat2)*Math.cos(lon2-lon1)).toFloat();
        return [x, y] as XyPoint;
    }

    // Listeners
    function addListener(listener as Object) as Void{
        if((listener as IListener) has :onData){
            listeners.add(listener.weak());

            // initial trigger
            (listener as IListener).onData(self);
        }
    }
    function removeListener(listener as Object) as Void{
        // loop through array to look for listener
        for(var i=listeners.size()-1; i>=0; i--){
            var ref = listeners[i];
            var l = ref.get();
            if(l == null || l.equals(listener)){
                listeners.remove(ref);
            }
        }
    }
    hidden function notifyListeners() as Void{
        for(var i=listeners.size()-1; i>=0; i--){
            var ref = listeners[i];
            var l = ref.get();
            if(l != null){
                (l as IListener).onData(self);
            }else{
                listeners.remove(ref);
            }
        }
    }
}