import Toybox.Position;
import Toybox.Lang;


class PositionManager
{
   	const EARTH_RADIUS = 6371000f;
    typedef XyPoint as Array<Float>;

    hidden var loggingEnabled as Boolean;
    hidden var indexFirst as Number?;
    hidden var indexLast as Number?;
    hidden var xyCurrent as XyPoint|Null;
    hidden var buffer as Array<XyPoint|Null>;

    hidden var latlonCenter as Array<Decimal>|Null;
    hidden var minDistance as Number;

    // Collector of historical position data in a register
    function initialize(options as {
        :loggingEnabled as Boolean,
        :size as Number,
        :minDistance as Number, // minimal distance [m] between 2 archived points
        :latCenter as Decimal,
        :lonCenter as Decimal,
    }){
        var size = options.hasKey(:size) ? options.get(:size) as Number : 100;
        minDistance = options.hasKey(:minDistance) ? options.get(:minDistance) as Number : 20;
        loggingEnabled = options.hasKey(:loggingEnabled) ? options.get(:loggingEnabled) as Boolean : true;

        // create the buffer
        buffer = new Array< XyPoint|Null >[size];
    }

    function setSize(size as Number) as Void{
        if(size == buffer.size()){
            return;
        }

        // create the new array
        var bufferNew = new Array< XyPoint|Null >[size];

        // copy data (newest first until new buffer is full or old buffer reached limit)
        if(self.indexFirst != null && self.indexLast != null){
            var indexFirst = self.indexFirst as Number;
            var indexLast = self.indexLast as Number;
            var sizeOld = getSize();

            if(size < sizeOld){
                // not all history points will be transfered to the new buffer
                var diff = sizeOld - size;
                indexFirst += diff;
                if(indexFirst >= buffer.size()){
                    indexFirst -= buffer.size();
                }
            }
            //copy points from old buffer in new buffer
            var indexNew = 0;
            if(indexLast >= indexFirst){
                // indexFirst -> indexLast
                for(var i=indexFirst; i<=indexLast; i++){
                    bufferNew[indexNew] = buffer[i];
                    indexNew++;
                }
            }else{
                // indexFirst -> last array item
                for(var i=indexFirst; i<buffer.size(); i++){
                    bufferNew[indexNew] = buffer[i];
                    indexNew++;
                }
                // first array item -> indexLast
                for(var i=0; i<=indexLast; i++){
                    bufferNew[indexNew] = buffer[i];
                    indexNew++;
                }
            }

            // update new indexes
            self.indexFirst = 0;
            self.indexLast = indexNew-1;
            self.buffer = bufferNew;
        }


        // reset index pointers
    }

    function getSize() as Number{
        // returns the number of xy points in the buffer
        if(indexFirst != null && indexLast != null){
            var iFirst = indexFirst as Number;
            var iLast = indexLast as Number;

            return (iFirst<=iLast)
                ? (iLast + 1) - iFirst
                : (buffer.size() - iFirst) + (iLast + 1);
        }else{
            return 0;
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

                // only loop through array if there are already some points added
                if(indexFirst != null && indexLast != null){
                    for(var i=0; i<buffer.size(); i++){
                        var xy = buffer[i];
                        if(xy != null){
                            buffer[i] = [xy[0]-dx, xy[1]-dy] as XyPoint;
                        }
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

        // get distance between points (the easy way)
        if(indexLast != null){
            var xyPrev = buffer[indexLast] as XyPoint?;
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
        if(buffer.size() > 0){
            // prepare next index
            if(indexLast != null && indexFirst != null){
                indexLast = (indexLast as Number < buffer.size()-1)
                    ? indexLast as Number + 1
                    : 0;
                    
                if(indexFirst == indexLast){
                    indexFirst = (indexFirst as Number < buffer.size()-1)
                        ? indexFirst as Number + 1
                        : 0;
                }
            }else{
                indexLast = 0;
                indexFirst = 0;
            }

            buffer[indexLast] = xy;
        }
    }

    function getXyValues() as Array<XyPoint|Null>{
        if(self.indexFirst != null && self.indexLast != null){
            var indexFirst = self.indexFirst as Number;
            var indexLast = self.indexLast as Number;

            if(indexFirst <= indexLast){
                return buffer.slice(indexFirst, indexLast+1) as Array<XyPoint>;
            }else{
                var values = buffer.slice(indexFirst, buffer.size());
                return values.addAll(buffer.slice(0, indexLast+1)) as Array<XyPoint|Null>;
            }
        }else{
            return [] as Array<XyPoint|Null>;
        }
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