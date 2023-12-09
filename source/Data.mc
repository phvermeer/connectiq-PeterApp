import Toybox.Position;
import Toybox.Activity;
import Toybox.System;
import Toybox.Lang;
import Toybox.Timer;

class Data
{
   	const EARTH_RADIUS = 6371000f;
    typedef XyPoint as Array<Float>;
    typedef IListener as interface{
        function onData(data as Data) as Void;
    };

    public var positionInfo as Position.Info = new Position.Info();
    public var activityInfo as Activity.Info = new Activity.Info();
    public var stats as System.Stats = new System.Stats();

    public var xy as XyPoint|Null;

    hidden var listeners as Array<WeakReference> = [] as Array<WeakReference>;
    hidden var started as Boolean = false;

    hidden var loggingEnabled as Boolean;
    hidden var buffer as Array<XyPoint|Null> = [] as Array<XyPoint|Null>;

    hidden var latlonCenter as Array<Decimal>|Null;
    hidden var minDistance as Number;
    hidden var sizeMax as Number;

    hidden var timer as Timer.Timer = new Timer.Timer();
    hidden var altitudeCalculator as Altitude.Calculator|Null;

    // Collector of historical position data in a register
    function initialize(options as {
        :loggingEnabled as Boolean,
        :size as Number,
        :minDistance as Number, // minimal distance [m] between 2 archived points
        :latCenter as Decimal,
        :lonCenter as Decimal,
    }){
        sizeMax = options.hasKey(:size) ? options.get(:size) as Number : 100;
        minDistance = options.hasKey(:minDistance) ? options.get(:minDistance) as Number : 20;
        loggingEnabled = options.hasKey(:loggingEnabled) ? options.get(:loggingEnabled) as Boolean : true;

        var settings = $.getApp().settings;
        if(SETTING_ALTITUDE_CALIBRATED){
            var p0 = settings.get(SETTING_ALTITUDE_P0) as Float;
            var t0 = settings.get(SETTING_ALTITUDE_T0) as Float;
            altitudeCalculator = new Altitude.Calculator(p0, t0);
        }
    }

    function start() as Void{
        // enable location events
        if(!started){
            started = true;
            timer.start(method(:onTimer), 1000, true);
        }
    }
    function stop() as Void{
        // disable location events
        if(started){
            started = false;
            timer.stop();
        }
    }

    function setSize(size as Number) as Void{
        self.sizeMax = size;
        updateSize();
    }

    hidden function updateSize() as Void{
        var sizeCurrent = buffer.size();
        if(sizeCurrent > sizeMax){
            buffer = buffer.slice(sizeCurrent-sizeMax, sizeCurrent);
        }
    }

    function setMinDistance(distance as Number) as Void{
        minDistance = distance;
    }

    function setLoggingEnabled(enabled as Boolean) as Void{
        loggingEnabled = enabled;
    }

    function setCenter(latlon as Array<Decimal>) as Void{
        if(latlonCenter != null){
            if(latlonCenter[0] != latlon[0] || latlonCenter[1] != latlon[1]){
                // update current xy points with new center position
                // determine the xyOffset between old and new lat lon positions
                var xyOffset = getXYbetweenPoints(latlonCenter, latlon);
                var dx = xyOffset[0];
                var dy = xyOffset[1];

                for(var i=0; i<buffer.size(); i++){
                    var xy = buffer[i];
                    if(xy != null){
                        buffer[i] = [xy[0]-dx, xy[1]-dy] as XyPoint;
                    }
                }
            }

        }
        // save new center position
        latlonCenter = latlon;
    }

    hidden function processPositionInfo(info as Position.Info) as Void{
        // get latitude and longtitude
        var pos = info.position;

        var xyPrev = self.xy;
        var xyNew = null;
        if(pos != null && info.accuracy >= Position.QUALITY_USABLE){
            // transform latlan to xy
            var latlon = pos.toRadians();
            if(latlon != null){
                xyNew = calculateXY(latlon);
            }
        }

        // get distance between new point and last recorded point
        var sizeCurrent = buffer.size();
        if(sizeCurrent > 0){
            var xyBuffer = buffer[sizeCurrent-1] as XyPoint?;
            if(xyBuffer != null){
                if(xyNew != null){
                    // calculate distance from previous point
                    var dx = xyNew[0] - xyBuffer[0];
                    var dy = xyNew[1] - xyBuffer[1];
                    var distance = Math.sqrt(dx*dx + dy*dy);            
                    if(distance >= minDistance){
                        add(xyNew);
                    }
                }else{
                    // position lost
                    if(xyBuffer != xyPrev){
                        add(xyPrev);
                        add(null);
                    }
                }
            }else{
                if(xy != null){
                    // position recovered
                    add(xyNew);
                }
            }
        }else{
            // first position
            add(xyNew);
        }

        // keep last position
        self.xy = xyNew;
        self.positionInfo = info;
    }

    hidden function processActivityInfo(info as Activity.Info) as Void{
        if(altitudeCalculator != null){
            // modify altitude
            var pressure = info.ambientPressure;
            if(pressure != null){
                info.altitude = altitudeCalculator.calculateAltitude(pressure);
            }
        }
        self.activityInfo = info;
    }

    function onTimer() as Void{
        processPositionInfo(Position.getInfo());

        // notify listeners
        notifyListeners();
    }

    hidden function add(xy as XyPoint|Null) as Void{
        buffer.add(xy);
        updateSize();
    }

    function getXyValues() as Array<XyPoint|Null>{
        return buffer;
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