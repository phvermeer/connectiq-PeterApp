import Toybox.Lang;
import Toybox.Math;
import Toybox.Position;
import Toybox.Attention;
import MyBarrel.Math2;

(:track)
typedef XY as Array<Float>; // [x, y]

(:track)
class TrackManager{
	static const EARTH_RADIUS = 6371000f;
	static const DISTANCE_ONTRACK = 50f; // distance in meters from track to define as on-track

	private enum SearchDirection{
		SEARCH_FORWARD = 0x1,
		SEARCH_BACKWARD = 0x2,
	}

	var track as Track?;
	hidden var latlonCenter as Array<Decimal>|Null;
	hidden var offsetListeners as Listeners = new Listeners(:onPositionOffset);
	hidden var positionListeners as Listeners = new Listeners(:onPosition);


	// current position on the track
	var index as Number|Null;
	var lambda as Float|Null;
	var xy as XY|Null;
	var heading as Float|Null;
	var elapsedDistance as Float|Null;
    var onTrack as Boolean = false;
    var offTrackDistance as Float?;

	// states
	hidden var started as Boolean = false;
	hidden var accuracy as Position.Quality = Position.QUALITY_NOT_AVAILABLE;

    function onSetting(sender as Object, id as Settings.Id, value as Settings.ValueType) as Void{
		if(id == Settings.ID_TRACK){
	        track = value as Track|Null;
			if(track != null){
				setCenter(track.latlonCenter);
			}
		}
    }

	// position events
	function start() as Void{'
		if(!started){
			Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onRawPosition) as Method(info as Position.Info) as Void);
			started = true;
		}
	}
	function stop() as Void{
		if(started){
			Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onRawPosition) as Method(info as Position.Info) as Void);
			accuracy = Position.QUALITY_LAST_KNOWN;
			heading = null;
			started = false;
		}
	}

	function onRawPosition(info as Position.Info) as Void{
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
			positionListeners.notify(self, xy);
		}else{
			// no signal
			if(accuracy > Position.QUALITY_LAST_KNOWN){
				accuracy = Position.QUALITY_LAST_KNOWN;
				heading = null;
			}
		}
	}

    function onSessionState(sender as Object, state as SessionState) as Void {
        // start/stop positioning events
        switch(state){
            case SESSION_STATE_IDLE:
            case SESSION_STATE_STOPPED:
                // stop events
	            stop();
                break;
            case SESSION_STATE_BUSY:
                // start events
                start();
                break;
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

	// public information
	public function isOnTrack() as Boolean{
		return onTrack;
	}

	// helper functions
    hidden function setCenter(latlon as Array<Decimal>) as Void{
        if(latlonCenter != null){
            if(latlonCenter[0] != latlon[0] || latlonCenter[1] != latlon[1]){
                // update current xy points with new center position
                // determine the xyOffset between old and new lat lon positions
                var xyOffset = calculateXY(latlonCenter, latlon);
                var dx = xyOffset[0];
                var dy = xyOffset[1];

                // update breadcrump points
				offsetListeners.notify(self, xyOffset);

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

	hidden function calculateXY(latlon1 as Array<Decimal>, latlon2 as Array<Decimal>) as XY{
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
		var startIndex = ((self.index == null) ? 0 : self.index) as Number;
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
			self.index = foundIndex;
			self.lambda = foundLambda;
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

	// Listeners
	function addListener(listener as Object) as Void{
		offsetListeners.add(self, listener, null);
		positionListeners.add(self, listener, xy);
	}
}
