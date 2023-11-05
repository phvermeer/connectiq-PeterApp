import Toybox.Position;
import Toybox.Lang;


class PositionManager
{
   	const EARTH_RADIUS = 6371000f;
    typedef XyPoint as Array<Float>;

    hidden var loggingEnabled as Boolean;
    hidden var xyCurrent as XyPoint|Null;
    hidden var buffer as Array<XyPoint|Null> = [] as Array<XyPoint|Null>;

    hidden var latlonCenter as Array<Decimal>|Null;
    hidden var minDistance as Number;
    hidden var sizeMax as Number;

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

    function addPosition(latlon as Array<Decimal>|Null) as XyPoint|Null{
        var xy = null;
        if(latlon != null){
            xy = getXY(latlon);
        }

        // get distance between new point and last recorded point
        var sizeCurrent = buffer.size();
        if(sizeCurrent > 0){
            var xyPrev = buffer[sizeCurrent-1] as XyPoint?;
            if(xyPrev != null){
                if(xy != null){
                    // calculate distance from previous point
                    var dx = xy[0] - xyPrev[0];
                    var dy = xy[1] - xyPrev[1];
                    var distance = Math.sqrt(dx*dx + dy*dy);            
                    if(distance >= minDistance){
                        add(xy);
                    }
                }else{
                    // position lost
                   if(xyPrev != xyCurrent){
                        add(xyCurrent);
                        add(null);
                    }
                }
            }else{
                if(xy != null){
                    // position recovered
                    add(xy);
                }
            }
        }else{
            // first position
            add(xy);
        }

        // keep last position
        xyCurrent = xy;
        return xy;
    }

    hidden function add(xy as XyPoint|Null) as Void{
        buffer.add(xy);
        updateSize();
    }

    function getXyValues() as Array<XyPoint|Null>{
        return buffer;
    }

    function getXY(latlon as Array<Decimal>) as XyPoint{
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
}