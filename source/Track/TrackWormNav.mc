import Toybox.Lang;

(:track)
class TrackWormNav extends Track{
	function initialize(rawData as Array){
		var trackData = {};

		// import data from phone or settings]
        if(rawData.size() < 3 || rawData.size() > 4){
            throw new MyException("Wrong Track data format received from phone");
        }
        var info = rawData[0] as Array;
		var name = info[0] as String;
		var distance = info[1] as Float;
		var latlonCenter = [info[7], info[8]] as Array<Float>;

		var boundaries = new [6] as Array<Float?>;
		boundaries[0] = (info[3] * TrackManager.EARTH_RADIUS) as Float; // xMin
		boundaries[2] = -(info[4] * TrackManager.EARTH_RADIUS) as Float; // yMin
		boundaries[1] = (info[5] * TrackManager.EARTH_RADIUS) as Float; // xMax
		boundaries[3] = -(info[6] * TrackManager.EARTH_RADIUS) as Float; // yMax

		var xValuesRaw = rawData[1] as Array<Float>;
		var yValuesRaw = rawData[2] as Array<Float>;

        var count = info[2] as Number;
        var xyValues = new [count] as Array<XY>;
		for(var i=0; i<count; i++){
			 xyValues[i] = [
				xValuesRaw[i] * TrackManager.EARTH_RADIUS,
				yValuesRaw[i] * -TrackManager.EARTH_RADIUS
			] as XY;
		}
        if(rawData.size()>=4){
			var zMin = info[11] as Float?;
			var zMax = info[14] as Float?;
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
			trackData.put("ALTITUDES", zValues);
			boundaries[4] = zMin;
			boundaries[5] = zMax;
        }

	    var distances = calculateDistances(xyValues, distance);

		// fill the dictionary for final creating the Track

        trackData.put("NAME", name as String);
        trackData.put("DISTANCE", distance as Float);
		trackData.put("CENTER", latlonCenter);
		trackData.put("BOUNDARIES", boundaries);
		trackData.put("POINTS", xyValues);
		trackData.put("DISTANCES", distances);

		var data = {
			"TRACK" => trackData,
			"WAYPOINTS" => [] as Array<Waypoint>,
		};

		Track.initialize(data);
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