import Toybox.Position;
import Toybox.Activity;
import Toybox.System;
import Toybox.Lang;
import Toybox.Timer;

class Data
{
    // listeners
    hidden var infoListeners as Listeners = new Listeners(:onActivityInfo);
    hidden var statsListeners as Listeners = new Listeners(:onSystemStats);

    hidden var timerStarted as Boolean = false;
    (:advanced)
    hidden var eventReceived as Boolean = false;

    // settings
    (:advanced)
    hidden var interval as Number;
    (:advanced)
    hidden var breadcrumpsEnabled as Boolean;
    (:advanced)
    hidden var breadcrumps as Array<XY|Null> = [] as Array<XY|Null>;
    (:advanced)
    hidden var breadcrumpsDistance as Number;
    (:advanced)
    hidden var breadcrumpsMax as Number;

    (:advanced)
    hidden var latlonCenter as Array<Decimal>|Null;
    hidden var timer as Timer.Timer = new Timer.Timer();
    hidden var info as Activity.Info?;
    hidden var stats as System.Stats?;
    hidden var xy as XY?;

    // Collector of historical position data in a register
    (:basic)
    function initialize(options as {
        :breadcrumpsEnabled as Boolean,
        :breadcrumpsMax as Number, // max number of breadcrumps
        :breadcrumpsDistance as Number, // minimal distance [m] between 2 archived points
    }){
//        activityInfo = Activity.getActivityInfo();
//        stats = System.getSystemStats();
    }

    (:advanced)
    function initialize(options as {
        :breadcrumpsEnabled as Boolean,
        :breadcrumpsMax as Number, // max number of breadcrumps
        :breadcrumpsDistance as Number, // minimal distance [m] between 2 archived points
    }){
        breadcrumpsMax = options.hasKey(:breadcrumpsMax) ? options.get(:breadcrumpsMax) as Number : 50;
        breadcrumpsDistance = options.hasKey(:breadcrumpsDistance) ? options.get(:breadcrumpsDistance) as Number : 50;
        breadcrumpsEnabled = options.hasKey(:breadcrumpsEnabled) ? options.get(:breadcrumpsEnabled) as Boolean : true;
        interval = options.hasKey(:interval) ? options.get(:interval) as Number : 5000;
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

    // Settings
    (:advanced)
    function onSetting(id as Settings.Id, value as Settings.ValueType) as Void{
        if(id == Settings.ID_BREADCRUMPS){
            setBreadcrumpsEnabled(value as Boolean);
        }else if(id == Settings.ID_BREADCRUMPS_MAX_COUNT){
            setBreadcrumpsMax(value as Number);
        }else if(id == Settings.ID_BREADCRUMPS_MIN_DISTANCE){
            setBreadcrumpsDistance(value as Number);
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
            breadcrumps = [] as Array<XY>;
        }
    }

    (:advanced)
    hidden function updateBreadcrumps(xyPrev as XY|Null, xyNew as XY|Null) as Void{
        if(breadcrumpsEnabled){
            // get distance between new point and last recorded point
            var count = breadcrumps.size();
            if(count > 0){
                var breadcrump = breadcrumps[count-1] as XY?;
                if(breadcrump != null){
                    if(xyNew != null){
                        // calculate distance from previous point
                        var dx = xyNew[0] - breadcrump[0];
                        var dy = xyNew[1] - breadcrump[1];
                        var distanceSqrt = dx*dx + dy*dy;            
                        if(distanceSqrt >= breadcrumpsDistance * breadcrumpsDistance){
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
    (:advanced)
    public function onPositionOffset(dxy as XY) as Void{
        var dx = dxy[0] as Float;
        var dy = dxy[1] as Float;
        // breadcrump points
        for(var i=0; i<breadcrumps.size(); i++){
            var xy = breadcrumps[i];
            if(xy != null){
                breadcrumps[i] = [xy[0]-dx, xy[1]-dy] as XY;
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
                infoListeners.notify(info);
            }
            statsListeners.notify(stats);            
        }else{
            eventReceived = false;
        }
    }

    (:advanced)
    function onPosition(xy as XY) as Void{
        // process xy for breadcrump
        updateBreadcrumps(self.xy, xy);
        self.xy = xy;

        // get latest info after position event
        eventReceived = true;
        
        var info = Activity.getActivityInfo();
        var stats = System.getSystemStats();
        self.stats = stats;

        if(info != null){
            self.info = info;
            infoListeners.notify(info);
        }
        statsListeners.notify(stats);
    }

    (:advanced)
    hidden function addBreadcrump(xy as XY|Null) as Void{
        breadcrumps.add(xy);
        checkBreadcrumpsMax();
    }

    (:advanced)
    function getBreadcrumps() as Array<XY|Null>{
        return breadcrumps;
    }

     // Listeners

    // additional listener function for different info from data
    // - activityInfo
    // - stats
 
    function addListener(listener as Object) as Void{
        infoListeners.add(listener, info);
        statsListeners.add(listener, stats);
    }
}