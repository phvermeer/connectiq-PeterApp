import Toybox.Lang;
import Toybox.Math;
import Toybox.Position;

typedef TrackPoint as Array<Float>; // [x, y, elapsedDistance]
typedef TrackPoints as Array<TrackPoint>;
typedef TrackListener as interface{
	function setTrack(track as Track?) as Void;
	function updateTrack() as Void;
};

class Track{
	private enum SearchDirection{
		SEARCH_FORWARD = 0x1,
		SEARCH_BACKWARD = 0x2,
	}

	const EARTH_RADIUS = 6371000f;
	const DISTANCE_ONTRACK = 50f; // distance in meters from track to define as on-track

    var name as String;
    var distanceTotal as Float;
    var distanceElapsed as Float?;
	var count as Number;
    var xValues as Array<Float>;
    var yValues as Array<Float>;
    var zValues as Array<Float>|Null;
    var xCurrent as Float?;
    var yCurrent as Float?;
	var xMin as Float;
	var xMax as Float;
	var yMin as Float;
	var yMax as Float;
    var xAligned as Float?;
    var yAligned as Float?;
    var latCenter as Float;
    var lonCenter as Float;
    hidden var distances as Array<Float>;
    hidden var distanceCorrectionFactor as Float;
    hidden var nearestPointIndex as Float?;
    hidden var onTrack as Boolean = false;
    hidden var distanceOffTrack as Float?;


    function initialize(rawData as Array){
        if(rawData.size() < 3 || rawData.size() > 4){
            throw new MyTools.MyException("Wrong Track data format received from phone");
        }
        var info = rawData[0] as Array;

        name = info[0] as String;
        distanceTotal = info[1] as Float;
        count = info[2] as Number;
		xMin = (info[3] * EARTH_RADIUS) as Float;
		yMin = -(info[4] * EARTH_RADIUS) as Float;
		xMax = (info[5] * EARTH_RADIUS) as Float;
		yMax = -(info[6] * EARTH_RADIUS) as Float;
        latCenter = info[7] as Float;
        lonCenter = info[8] as Float;

		var xValuesRaw = rawData[1] as Array<Float>;
		var yValuesRaw = rawData[2] as Array<Float>;

        xValues = [] as Array<Float>;
        yValues = [] as Array<Float>;
		for(var i=0; i<count; i++){
			xValues.add((xValuesRaw[i] * EARTH_RADIUS) as Float);
			yValues.add((yValuesRaw[i] * -EARTH_RADIUS) as Float);
		}
        if(rawData.size()>=4){
            zValues = rawData[3] as Array<Float>;
        }

        distances = [] as Array<Float>;
        var distance = 0f;
		if(count <= 0){
			throw new MyTools.MyException("Track contains no points");
		}
		var x = null;
		var y = null;
		var xPrev = xValues[0];
		var yPrev = yValues[0];
		distances.add(distance);

		for(var i=1; i<count; i++){
			x = xValues[i];
			y = yValues[i];
			distance += pointDistance(xPrev, yPrev, x, y);
			distances.add(distance);
			xPrev = x;
			yPrev = y;
		}

        // correctionfactor calculated distance vs actual distance        
        distanceCorrectionFactor = (distance>0) ? distanceTotal / distance : 1f;
    }

    function onPosition(lat as Decimal?, lon as Decimal?, quality as Position.Quality) as Void{
		if(quality >= Position.QUALITY_USABLE && lat != null && lon != null){
			// update the currentIndex of the track
			xCurrent = EARTH_RADIUS * (Math.cos(lat)*Math.sin(lon-lonCenter)).toFloat();
			yCurrent = EARTH_RADIUS * (Math.cos(latCenter)*Math.sin(lat) - Math.sin(latCenter)*Math.cos(lat)*Math.cos(lon-lonCenter)).toFloat();
		}
    }

    hidden function searchNearestPoint(x as Float, y as Float) as Void{

		var startIndex = ((nearestPointIndex == null) ? 0 : nearestPointIndex) as Number;
		var distance = null;
		var DISTANCE_OFFTRACK = DISTANCE_ONTRACK * 2;
		var onTrack = false;
		var foundIndex = 0; // the new interpolated index
		var foundLambda = 0f;
		var foundDistance = EARTH_RADIUS;

		// Check the distance of current position compared to track segments

		// forwards and backwards direction from previous nearest point (startIndex)
		var directions = [SEARCH_FORWARD, SEARCH_BACKWARD];
        var size = xValues.size();


		for(var d=0; d<directions.size(); d++){
			if(onTrack){ break; }
			var dir =  directions[d];

			var first = (dir == SEARCH_FORWARD) ? (startIndex + 1) : (startIndex - 1);
			var stop = (dir == SEARCH_FORWARD) ? size : -1;
			var step = (dir == SEARCH_BACKWARD) ? -1: 1;

			var x1 = xValues[startIndex];
			var y1 = yValues[startIndex];

			for(var i=first; i!=stop; i+=step){
                var x2 = xValues[i];
                var y2 = yValues[i];
				var lambda;

				// Now start with calculating the distance from the point to the line segment
				var lineLength2 = pointDistanceSquared(x1,y1, x2,y2);
				if(lineLength2 == 0){
					// p1 are p2 are the same => distance to point
					distance = pointDistance(x,y, x1,y1);
					lambda = 0f;
				}else{
					var t = ((x-x1)*(x2-x1)+(y-y1)*(y2-y1))/lineLength2; 

					//t is very important. t is a number that essentially compares the individual coordinates
					//distances between the point and each point on the line.

					if(t<0){	//if t is less than 0, the point is closest to p1.
						distance = pointDistance(x,y, x1,y1);
						lambda=0f;
					}else	if(t>1){

						//if greater than 1, it's closest to p2.
						distance = pointDistance(x,y, x2,y2);
						lambda = 1f;
					}else{
						distance = pointDistance(x,y, x1+t*(x2-x1),y1+t*(y2-y1));
						//this figure represents the point on the line that p is closest to.
						lambda = t;
					}
				}
				if(distance < foundDistance){
					foundDistance = distance;
					if(dir == SEARCH_FORWARD){
						foundIndex = i-1;
						foundLambda = lambda;
					}else{
						foundIndex = i+1;
						foundLambda = 1f-lambda;
					}
					if(!onTrack && distance < DISTANCE_ONTRACK){
						onTrack = true;
					}
				}else{
					if(onTrack && (distance > DISTANCE_OFFTRACK)){
						// stop loop when the DISTANCE_OFFTRACK is exceeded
						break;
					}
				}

				// next segment
				x1 = x2;
				y1 = y2;
			}
		}

		self.onTrack = onTrack;
		self.distanceOffTrack = foundDistance;

		if(onTrack){
			// save new track position
			setNearestPoint(foundIndex, foundLambda);
		}
	}

	hidden function setNearestPoint(index as Number, lambda as Float) as Void{
		// calculate elapsed distance by interpolating distance at index and index+1 with lambda
		var distance = distances[index];
		var diff = distances[index+1] - distance;
		self.distanceElapsed = distance + lambda * diff;

		// calculate interpolated position aligned on the track
		var x1 = xValues[index];
        var y1 = yValues[index];
		var x2 = xValues[index+1];
        var y2 = yValues[index+1];
		if(lambda == 0.0f){
			xAligned = x1;
			yAligned = y1;
		}else if(index == 1.0f){
			xAligned = x2;
			yAligned = y2;
		}else{
			xAligned = x1 + lambda * (x2-x1);
			yAligned = y1 + lambda * (y2-y1);
		}
	}

   	hidden function pointDistance(x1 as Float, y1 as Float, x2 as Float, y2 as Float) as Float{
		return Math.sqrt(pointDistanceSquared(x1, y1, x2, y2)) as Float;
	}
	hidden function pointDistanceSquared(x1 as Float, y1 as Float, x2 as Float, y2 as Float) as Float{
		return (MyMath.sqr(x2-x1) + MyMath.sqr(y2-y1)) as Float;
	}
}