import Toybox.Position;
import Toybox.Activity;
import Toybox.System;
import Toybox.Lang;
import Toybox.Timer;

class Data
{
    (:advanced)
   	static const EARTH_RADIUS = 6371000f;
    (:advanced)
    typedef XyPoint as Array<Float>;

//    (:advanced)
//    public var positionInfo as Position.Info;
//    public var activityInfo as Activity.Info|Null;
//    public var stats as System.Stats;

    (:advanced)
    hidden var track as Track?;
    (:advanced)
    public var xy as XyPoint|Null;

    // listeners
    hidden var infoListeners as Listeners = new Listeners(:onActivityInfo);
    hidden var statsListeners as Listeners = new Listeners(:onSystemStats);

    hidden var timerStarted as Boolean = false;
    (:advanced)
    hidden var positioningStarted as Boolean = false;
    (:advanced)
    hidden var eventReceived as Boolean = false;

    // settings
    (:advanced)
    hidden var interval as Number;
    (:advanced)
    hidden var breadcrumpsEnabled as Boolean;
    (:advanced)
    hidden var breadcrumps as Array<XyPoint|Null> = [] as Array<XyPoint|Null>;
    (:advanced)
    hidden var breadcrumpsDistance as Number;
    (:advanced)
    hidden var breadcrumpsMax as Number;

    (:advanced)
    hidden var latlonCenter as Array<Decimal>|Null;
    hidden var timer as Timer.Timer = new Timer.Timer();
    hidden var info as Activity.Info?;
    hidden var stats as System.Stats?;

    // Collector of historical position data in a register
    (:basic)
    function initialize(options as {
        :breadcrumpsEnabled as Boolean,
        :breadcrumpsMax as Number, // max number of breadcrumps
        :breadcrumpsDistance as Number, // minimal distance [m] between 2 archived points
        :latCenter as Decimal,
        :lonCenter as Decimal,
    }){
//        activityInfo = Activity.getActivityInfo();
//        stats = System.getSystemStats();
    }

    (:advanced)
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
    }

    (:basic)
    function startTimer() as Void{
        if(!timerStarted){
            // start timer events
            timer.start(method(:onTimer), 1000, true);
            timerStarted = true;
        }
    }
    (:advanced)
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
    (:advanced)
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
    (:advanced)
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
    (:advanced)
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

    (:advanced)
    function setInterval(interval as Number) as Void{
        var doRestart = (timerStarted && interval != self.interval);
        self.interval = interval;
        if(doRestart){
            // restart timer with new interval
            stopTimer();
            startTimer();
        }
    }

    (:advanced)
    function setBreadcrumpsMax(max as Number) as Void{
        self.breadcrumpsMax = max;
        checkBreadcrumpsMax();
    }

    (:advanced)
    function setTrack(track as Track|Null) as Void{
        self.track = track;

        // update xy center
        if(track != null){
            setCenter(track.latlonCenter);
        }else{
            var posInfo = Position.getInfo();
            var position = posInfo.position;
            if(position != null){
                var latlon = position.toRadians();
                setCenter(latlon);
            }
        }
    }

    (:advanced)
    hidden function checkBreadcrumpsMax() as Void{
        var size = breadcrumps.size();
        if(size > breadcrumpsMax){
            breadcrumps = breadcrumps.slice(size-breadcrumpsMax, null);
        }
    }

    (:advanced)
    hidden function setBreadcrumpsDistance(distance as Number) as Void{
        breadcrumpsDistance = distance;
    }

    (:advanced)
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

    (:advanced)
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

    (:advanced)
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

    (:basic)    
    function onTimer() as Void{
        var info = Activity.getActivityInfo();
        if(info != null){
            self.info = info;
            infoListeners.notify(info);
        }
        self.stats = System.getSystemStats();
        statsListeners.notify(stats);
    }

    (:advanced)
    function onTimer() as Void{
        if(!eventReceived){
            // slow update when no position events are received within timer
            var info = Activity.getActivityInfo();
            var stats = System.getSystemStats();
            self.stats = stats;
            if(info != null){
                self.info = info;

                // process info
                processInfo(info, stats);

                infoListeners.notify(info);
            }
            statsListeners.notify(stats);            
        }else{
            eventReceived = false;
        }
    }

    (:advanced)
    function onPosition(posInfo as Position.Info) as Void{
        // transform to xy
        var position = posInfo.position;
        if(posInfo.accuracy >= Position.QUALITY_POOR && position != null){
            eventReceived = true;
            var info = Activity.getActivityInfo();
            var stats = System.getSystemStats();
            self.stats = stats;

            if(info != null){
                self.info = info;
                processInfo(info, stats);
                infoListeners.notify(info);
            }
            statsListeners.notify(stats);
        }
    }

    (:advanced)
    hidden function processInfo(info as Activity.Info, stats as Stats) as Void{
        // position => xy
        var xy = null;
        var position = info.currentLocation;
        var accuracy = info.currentLocationAccuracy;
        if(position != null && accuracy != null && accuracy >= Position.QUALITY_POOR && position != null){
            var latlon = position.toRadians();
            xy = calculateXY(latlon);

            // update track (do not wait for listeners events to update position on track)
            if(track != null){
                track.setCurrentXY(xy[0], xy[1]);
            }
        }
        updateBreadcrumps(self.xy, xy);

        // keep last point
        self.xy = xy;
    }

    (:advanced)
    hidden function addBreadcrump(xy as XyPoint|Null) as Void{
        breadcrumps.add(xy);
        checkBreadcrumpsMax();
    }

    (:advanced)
    function getBreadcrumps() as Array<XyPoint|Null>{
        return breadcrumps;
    }

    (:advanced)
    hidden function calculateXY(latlon as Array<Decimal>) as XyPoint{
        if(latlonCenter != null){
            return getXYbetweenPoints(latlonCenter, latlon);
        }else{
            latlonCenter = latlon;
            return [0f, 0f] as XyPoint;
        }
    }

    (:advanced)
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

    // additional listener function for different info from data
    // - activityInfo
    // - stats
    // - positionInfo

    function addListener(listener as Object) as Void{
        infoListeners.add(listener, info);
        statsListeners.add(listener, stats);
    }
}