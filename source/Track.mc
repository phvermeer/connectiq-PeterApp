import Toybox.Lang;
import Toybox.Math;
import Toybox.Position;
import Toybox.Attention;
import MyBarrel.Math2;

(:replacement)
typedef XY as Array<Float>; // [x, y]

(:replacement)
class TrackManager{
	static const EARTH_RADIUS = 6371000f;
	static const DISTANCE_ONTRACK = 50f; // distance in meters from track to define as on-track

	private enum SearchDirection{
		SEARCH_FORWARD = 0x1,
		SEARCH_BACKWARD = 0x2,
	}

	hidden var track as Track?;
	hidden var latlonCenter as Array<Decimal>|Null;

	// current position on the track
	hidden var i as Float|Null;
	hidden var xy as XY|Null;
	hidden var heading as Float|Null;
	hidden var elapsedDistance as Float|Null;
    hidden var onTrack as Boolean = false;
    hidden var offTrackDistance as Float?;

	// states
	hidden var started as Boolean = false;
	hidden var accuracy as Position.Quality = Position.QUALITY_NOT_AVAILABLE;

	// position events
	function start() as Void{'
		if(!started){
			Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition) as Method(info as Position.Info) as Void);
			started = true;
		}
	}
	function stop() as Void{
		if(started){
			Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition) as Method(info as Position.Info) as Void);
			accuracy = Position.QUALITY_LAST_KNOWN;
			heading = null;
			started = false;
		}
	}

	function onPosition(info as Position.Info) as Void{
		var position = info.position;
		if(info.accuracy >= Position.QUALITY_POOR && position != null){
			// signal available
			accuracy = info.accuracy;
			heading = info.heading;
			var latlon = position.toRadians();

			if(latlonCenter == null){
				latlonCenter = latlon;
				xy = [0f, 0f] as XY;
			}else{
				xy = calculateXY(latlonCenter, latlon);
				if(xy != null && track != null){
					updateTrackPosition(track, xy);
				}
			}

		}else{
			// no signal
			if(accuracy > Position.QUALITY_LAST_KNOWN){
				accuracy = Position.QUALITY_LAST_KNOWN;
				heading = null;
			}
		}

	}

	// public functions
	function getTrackPoints() as Array<XY>{
		if(track!= null){
			return track.xyValues;
		}else{
			return [] as Array<XY>;
		}		
	}

	// helper functions
	hidden function calculateXY(latlon1 as Array<Decimal>, latlon2 as Array<Double>) as XY{
        var lat1 = latlon1[0];
        var lon1 = latlon1[1];
        var lat2 = latlon2[0];
        var lon2 = latlon2[1];
        var x = EARTH_RADIUS * (Math.cos(lat2)*Math.sin(lon2-lon1)).toFloat();
        var y = -EARTH_RADIUS * (Math.cos(lat1)*Math.sin(lat2) - Math.sin(lat1)*Math.cos(lat2)*Math.cos(lon2-lon1)).toFloat();
        return [x, y] as XY;
    }

	static function calculateDistanceSquared(x1 as Float, y1 as Float, x2 as Float, y2 as Float) as Float{
		var dx = x2-x1;
		var dy = y2-y1;
		return dx*dx + dy*dy as Float;
	}	

	static function calculateDistance(x1 as Float, y1 as Float, x2 as Float, y2 as Float) as Float{
		var dx = x2-x1;
		var dy = y2-y1;
		return Math.sqrt(dx*dx + dy*dy) as Float;
	}	


	//	update the track position for current [x,y]
	// 	input:
	//		xyCurrent
	//	output:
	//		iCurrent
	//		onTrack
	//		offTrackDistance
	hidden function updateTrackPosition(track as Track, xy as XY) as Void{
		// start on last known position and find new position on the track
		var x = xy[0] as Float;
		var y = xy[1] as Float;
		var xyValues = track.xyValues;

		// initial values
		var startIndex = ((self.i == null) ? 0 : self.i) as Number;
		var distance = null;
		var DISTANCE_OFFTRACK = DISTANCE_ONTRACK * 2;
		var onTrack = false;
		var foundIndex = 0; // the new interpolated index
		var foundLambda = 0f;
		var foundDistance = EARTH_RADIUS;

		// Check the distance of current position compared to track segments

		// forwards and backwards direction from previous nearest point (startIndex)
		var directions = [SEARCH_FORWARD, SEARCH_BACKWARD] as Array<SearchDirection>;
        var size = xyValues.size();

		for(var d=0; d<directions.size(); d++){
			if(onTrack){ break; }
			var dir =  directions[d];

			var first = (dir == SEARCH_FORWARD) ? (startIndex + 1) : (startIndex - 1);
			var stop = (dir == SEARCH_FORWARD) ? size : -1;
			var step = (dir == SEARCH_BACKWARD) ? -1: 1;

			var xy1 = xyValues[startIndex];
			var x1 = xy1[0] as Float;
			var y1 = xy1[1] as Float;

			for(var i=first; i!=stop; i+=step){
				var xy2 = xyValues[i];
                var x2 = xy2[0] as Float;
                var y2 = xy2[1] as Float;
				var lambda;

				// Now start with calculating the distance from the point to the line segment
				var lineLength2 = calculateDistanceSquared(x1,y1, x2,y2);
				if(lineLength2 == 0){
					// p1 are p2 are the same => distance to point
					distance = calculateDistance(x,y, x1,y1);
					lambda = 0f;
				}else{
					var t = ((x-x1)*(x2-x1)+(y-y1)*(y2-y1))/lineLength2; 

					//t is very important. t is a number that essentially compares the individual coordinates
					//distances between the point and each point on the line.

					if(t<0){	//if t is less than 0, the point is closest to p1.
						distance = calculateDistance(x,y, x1,y1);
						lambda=0f;
					}else if(t>1){

						//if greater than 1, it's closest to p2.
						distance = calculateDistance(x,y, x2,y2);
						lambda = 1f;
					}else{
						distance = calculateDistance(x,y, x1+t*(x2-x1),y1+t*(y2-y1));
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

		self.offTrackDistance = foundDistance;
		if(onTrack){
			// calculate elapsed distance by interpolating distance at index and index+1 with lambda
			distance = track.distances[foundIndex];
			var diff = track.distances[foundIndex+1] - distance;
			self.elapsedDistance = distance + foundLambda * diff;
			self.i = foundLambda + foundIndex;
		}		

		// update on-track state
		if(self.onTrack != onTrack){
			self.onTrack = onTrack;
			if(!onTrack){
				// Send warning for moving from the track
				if(Attention has :vibrate){
					Attention.vibrate([new VibeProfile(60, 1000)] as Array<VibeProfile>);
				}
			}
		}
	}
}

(:replacement)
class Track{
	// static track data
    var name as String;
    var distanceTotal as Float;
    var xyValues as Array<XY>;
	var zValues as Array<Float|Null>|Null;
	var latlonCenter as Array<Float>;

	// limits
	var xMin as Float;
	var xMax as Float;
	var yMin as Float;
	var yMax as Float;
	var zMin as Float?;
	var zMax as Float?;

	// calculated track data
    var distances as Array<Float>; // distance at index

	function initialize(rawData as Array){
		// import data from phone or settings]
        if(rawData.size() < 3 || rawData.size() > 4){
            throw new MyException("Wrong Track data format received from phone");
        }
        var info = rawData[0] as Array;

        name = info[0] as String;
        distanceTotal = info[1] as Float;
        var count = info[2] as Number;
		xMin = (info[3] * TrackManager.EARTH_RADIUS) as Float;
		yMin = -(info[4] * TrackManager.EARTH_RADIUS) as Float;
		xMax = (info[5] * TrackManager.EARTH_RADIUS) as Float;
		yMax = -(info[6] * TrackManager.EARTH_RADIUS) as Float;
        latlonCenter = [info[7], info[8]] as Array<Float>;

		var xValuesRaw = rawData[1] as Array<Float>;
		var yValuesRaw = rawData[2] as Array<Float>;

        xyValues = new [count] as Array<XY>;
		for(var i=0; i<count; i++){
			 xyValues[i] = [
				xValuesRaw[i] * TrackManager.EARTH_RADIUS,
				yValuesRaw[i] * -TrackManager.EARTH_RADIUS
			] as XY;
		}
        if(rawData.size()>=4){
			zMin = info[11] as Float?;
			zMax = info[14] as Float?;
            var zValues = rawData[3] as Array<Float>;
			// replace 0.0 values with interpolated altitude
			for(var i=0; i<zValues.size(); i++){
				if(zValues[i] == 0f){
					// get interpolated value
					var i0 = i-1;
					var z0 = 0f;
					while(i0>0){
						z0 = zValues[i0];
						if(z0 != 0f){
							break;
						}else{
							i0--;
						}
					}
					var i1 = i+1;
					var z1 = 0f;;
					while(i1<zValues.size()){
						z1 = zValues[i1];
						if(z1 != 0f){
							break;
						}else{
							i1++;
						}
					}
					var z = z0 + (z1-z0) * (i-i0)/(i1-i0);
					zValues[i] = z;
				}
			}
            self.zValues = zValues;
        }

	    self.distances = calculateDistances(xyValues, distanceTotal);
	}

	hidden function calculateDistances(xyTracks as Array<XY>, distanceTotal as Float) as Array<Float>{
		var count = xyTracks.size();
		var distances = new [count] as Array<Float>;
		if(count>0){
			var distance = 0f;
			distances[0] = distance;
			var xy1 = xyTracks[0];
			for(var i=1; i<count; i++){
				var xy2 = xyTracks[i];
				distance += TrackManager.calculateDistance(xy1[0], xy1[1], xy2[0], xy2[1]);
				distances[i] = distance;
				// prepare next
				xy1 = xy2;
			}
			if(distance > 0f){
				// distance correction
				var correctionFactor = distanceTotal / distance;
				for(var i=0; i<count; i++){
					distances[i] *= correctionFactor;
				}
			}
		}

		return distances;
	}
}


(:original)
class Track{
	typedef TrackPoint as Array<Float>; // [x, y, elapsedDistance]
	typedef TrackPoints as Array<TrackPoint>;

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
	var iCurrent as Number?;
	var lambdaCurrent as Float?;
	var xMin as Float;
	var xMax as Float;
	var yMin as Float;
	var yMax as Float;
	var zMin as Float?;
	var zMax as Float?;
    var latlonCenter as Array<Float>;
    var distances as Array<Float>;
    hidden var distanceCorrectionFactor as Float;
    hidden var nearestPointIndex as Float?;
    hidden var onTrack as Boolean = false;
    var distanceOffTrack as Float?;


    function initialize(rawData as Array){
        if(rawData.size() < 3 || rawData.size() > 4){
            throw new MyException("Wrong Track data format received from phone");
        }
        var info = rawData[0] as Array;

        name = info[0] as String;
        distanceTotal = info[1] as Float;
        count = info[2] as Number;
		xMin = (info[3] * EARTH_RADIUS) as Float;
		yMin = -(info[4] * EARTH_RADIUS) as Float;
		xMax = (info[5] * EARTH_RADIUS) as Float;
		yMax = -(info[6] * EARTH_RADIUS) as Float;
        latlonCenter = [info[7], info[8]] as Array<Float>;

		var xValuesRaw = rawData[1] as Array<Float>;
		var yValuesRaw = rawData[2] as Array<Float>;

        xValues = [] as Array<Float>;
        yValues = [] as Array<Float>;
		for(var i=0; i<count; i++){
			xValues.add((xValuesRaw[i] * EARTH_RADIUS) as Float);
			yValues.add((yValuesRaw[i] * -EARTH_RADIUS) as Float);
		}
        if(rawData.size()>=4){
			zMin = info[11] as Float?;
			zMax = info[14] as Float?;
            var zValues = rawData[3] as Array<Float>;
			// replace 0.0 values with interpolated altitude
			for(var i=0; i<zValues.size(); i++){
				if(zValues[i] == 0f){
					// get interpolated value
					var i0 = i-1;
					var z0 = 0f;
					while(i0>0){
						z0 = zValues[i0];
						if(z0 != 0f){
							break;
						}else{
							i0--;
						}
					}
					var i1 = i+1;
					var z1 = 0f;;
					while(i1<zValues.size()){
						z1 = zValues[i1];
						if(z1 != 0f){
							break;
						}else{
							i1++;
						}
					}
					var z = z0 + (z1-z0) * (i-i0)/(i1-i0);
					zValues[i] = z;
				}
			}
            self.zValues = zValues;
        }

        distances = [] as Array<Float>;
        var distance = 0f;
		if(count <= 0){
			throw new MyException("Track contains no points");
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

	function setCurrentXY(x as Float, y as Float) as Void{
		if(xCurrent != x || yCurrent != y){
			xCurrent = x;
			yCurrent = y;
			searchNearestPoint(xCurrent, yCurrent);
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

		setOnTrack(onTrack);
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
		self.iCurrent = index;
		self.lambdaCurrent = lambda;
	}

   	hidden function pointDistance(x1 as Float, y1 as Float, x2 as Float, y2 as Float) as Float{
		return Math.sqrt(pointDistanceSquared(x1, y1, x2, y2)) as Float;
	}
	hidden function pointDistanceSquared(x1 as Float, y1 as Float, x2 as Float, y2 as Float) as Float{
		return (Math2.sqr(x2-x1) + Math2.sqr(y2-y1)) as Float;
	}

	function isOnTrack() as Boolean{
		return onTrack;
	}
	hidden function setOnTrack(value as Boolean) as Void{
		if(onTrack && !value){
			// Send warning for moving from the track
			if(Attention has :vibrate){
				Attention.vibrate([new VibeProfile(50, 2000)] as Array<VibeProfile>);
			}
		}
		onTrack = value;
	}
}