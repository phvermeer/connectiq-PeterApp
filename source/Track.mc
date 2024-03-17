import Toybox.Lang;
import Toybox.Math;
import Toybox.Position;
import Toybox.Attention;
import MyBarrel.Math2;

(:noTrack)
function convertToTrack(rawData as Array) as Array{
	return rawData;
}

(:track)
function convertToTrack(rawData as Array) as Track|Null{
	// get version from data
	var item0 = rawData[0];
	if(item0 instanceof Float) {
		var version = item0;
		if(version == 1.0){
			// version 1.0
			var trackData = {
				:name => rawData[1] as String,
				:latlonCenter => rawData[2] as Array<Float>,
				:xyValues => rawData[3] as Array<XY>,
				:distance => rawData[5] as Float,
				:distances => rawData[6] as Array<Float>,
				:xMin => rawData[7] as Float,
				:xMax => rawData[8] as Float,
				:yMin => rawData[9] as Float,
				:yMax => rawData[10] as Float,
			};
			return new Track(trackData);
		}
	}else if(item0 instanceof Array){
		// old wormnav format
		return new TrackWormNav(rawData);

	}
	return null;
}

(:track)
class Track{
	// static track data
    var name as String;
    var distance as Float;
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

	function initialize(trackData as {
		:name as String,
		:xyValues as Array<XY>,
		:zValues as Array<Float|Null>,
		:distance as Float,
		:distances as Array<Float>,
		:latlonCenter as Array<Float>,
		:xMin as Float,
		:xMax as Float,
		:yMin as Float,
		:yMax as Float,
		:zMin as Float,
		:zMax as Float,
	}){
		name = 		(trackData.hasKey(:name) ? trackData.get(:name) : "No Name") as String;
		xyValues = 	(trackData.hasKey(:xyValues) ? trackData.get(:xyValues) : []) as Array<XY>;
		zValues = 	(trackData.get(:zValues)) as Array<Float>;
		distance =	(trackData.hasKey(:distance) ? trackData.get(:distance) : 0f) as Float;
		distances =	(trackData.hasKey(:distances) ? trackData.get(:distances) : []) as Array<Float>;

		latlonCenter = (trackData.hasKey(:latlonCenter) ? trackData.get(:latlonCenter) : []) as Array<Float>;

		xMin = (trackData.hasKey(:xMin) ? trackData.get(:xMin) : 0f) as Float;
		xMax = (trackData.hasKey(:xMax) ? trackData.get(:xMax) : 0f) as Float;
		yMin = (trackData.hasKey(:yMin) ? trackData.get(:yMin) : 0f) as Float;
		yMax = (trackData.hasKey(:yMax) ? trackData.get(:yMax) : 0f) as Float;
		zMin = (trackData.get(:zMin)) as Float?;
		zMax = (trackData.get(:zMax)) as Float?;

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

(:track)
class TrackWormNav extends Track{
	function initialize(rawData as Array){
		var trackData = {};
		Track.initialize(trackData);

		// import data from phone or settings]
        if(rawData.size() < 3 || rawData.size() > 4){
            throw new MyException("Wrong Track data format received from phone");
        }
        var info = rawData[0] as Array;

        name = info[0] as String;
        distance = info[1] as Float;
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

	    self.distances = calculateDistances(xyValues, distance);
	}
}