import Toybox.Lang;
import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Position;
import Toybox.Application;
import Toybox.Activity;
import Toybox.Time;
using Toybox.Timer;
using Toybox.Math;
import MyList;
import MyGraph;
import MyLayoutHelper;
using MyTools;

class TrackProfileField extends MyDataField{
	var zoomFactor as Float = 1f; // xRange = zoomFactor*(xMax-xMin)
	var track as Track?;
	var xAxis as Axis;
	var yAxis as Axis;
	var dataTrack as BufferedList;
	var dataLive as BufferedList;
	var serieTrack as Serie;
	var serieLive as Serie;
	var marker as Marker;
	var trend as Trend;
	
	function initialize(
		options as {
			:track as Track,
			:xyCurrent as Array<Float>,
		}
	){
		MyDataField.initialize(options);

		xAxis = new Axis(0, 500); // distance 0..500m
		yAxis = new Axis(0, 50); // altitude 0..50m
		dataTrack = new BufferedList({
			:maxCount => 50,
			:onReady => method(:onTrackLoaded),
		});
		dataLive = new BufferedList({
			:maxCount => 50,
		});
		serieTrack = new MyGraph.Serie({
			:pts => dataTrack,
			:color => Graphics.COLOR_LT_GRAY,
			:style => MyGraph.DRAW_STYLE_FILLED,
		});
		serieLive = new MyGraph.Serie({
			:pts => dataLive,
			:color => Graphics.COLOR_PINK,
			:style => MyGraph.DRAW_STYLE_LINE,
		});
		trend = new MyGraph.Trend({
			:series => [serieTrack, serieLive] as Array<Serie>,
			:series => [serieTrack, serieLive] as Array<Serie>,
			:xAxis => xAxis,
			:yAxis => yAxis,
			:width => 3,
			:height => 1,
		});
		marker = new MyGraph.Marker({
			:color => Graphics.COLOR_PINK,
			:font => Graphics.FONT_TINY,
			:serie => serieTrack,
		});
		if(options.hasKey(:track)){
			setTrack(options.get(:track) as Track);
		}

		// Load historical altitude data
		//initElevationHistory();
	}

	function onShow(){
		dataTrack.onReady = method(:onTrackLoaded);
		dataLive.onReady = method(:onNewAltitudeLoaded);
	}

	function onHide(){
		// unlink to methods for the garbage collector
		dataTrack.onReady = null;
		dataLive.onReady = null;
	}

	function onLayout(dc as Graphics.Dc){
		// init graph sizes
		var helper = MyLayoutHelper.getLayoutHelper({
			:xMin => locX,
			:xMax => locX + width,
			:yMin => locY,
			:yMax => locY + height,
			:margin => 1,
		});

		helper.resizeToMax(trend, true);
	}

	function onData(data as Data) as Void{
		updateMarker();
		var info = data.activityInfo;
		if(info != null){
			onActivityInfo(info);
		}
	}

	hidden function updateMarker() as Void{
		if(track != null){
			// get track elapsed distance
			var distance = track.distanceElapsed;
			var altitudes = track.zValues;

			// get correct altitude using interpolation
			var i = track.iCurrent;
			var lambda = track.lambdaCurrent;
			if(altitudes != null && distance != null && i != null && lambda != null){
				var altitude = altitudes[i];
				if(lambda > 0){
					var altitudeNext = altitudes[i+1];
					altitude += (altitudeNext-altitude) * lambda;
				}

				// update point
				marker.pt = new DataPoint(distance, altitude);
				refresh();
			}
		}
	}

	hidden function onActivityInfo(info as Activity.Info) as Void{
		// add altitude to dataLive
		var distance = 
			(track != null)
				? track.distanceElapsed
				: info.elapsedDistance;
		if(distance != null){
			var altitude = (track != null && !track.isOnTrack())
				? null : info.altitude;
			var xy = new MyGraph.DataPoint(distance, altitude);
			dataLive.add(xy);

			// update statistics
			var xMin = serieLive.getXmin();
			var xMax = serieLive.getXmax();
			if(xMin != null && xMin > distance){ serieLive.ptFirst = xy; }
			if(xMax != null && xMax < distance){ serieLive.ptLast = xy; }

			if(altitude != null){
				altitude = altitude as Numeric;
				var yMin = serieLive.getYmin();
				if(yMin != null && yMin < altitude){
					serieLive.ptMin = xy;
				}
				var yMax = serieLive.getYmax();
				if(yMax != null && yMax > altitude){
					serieLive.ptMax = xy;
				}
			}

			updateAxisLimits(trend.series);
		}
	}

	function onUpdate(dc as Graphics.Dc){
		MyDataField.onUpdate(dc);

		// draw the graph
		trend.draw(dc);
		marker.draw(dc);

	}
	
	function onSetting(id as SettingId, value as Settings.ValueType) as Void{
		if(id == SETTING_TRACK){
			setTrack(value as Track|Null);
		}
	}

	hidden function setTrack(track as Track?) as Void{

		// update profile with set track
		self.track = track;
		var data = self.dataTrack;
		data.clear();
		if(track != null){
			if(track.zValues != null){			
				var altitudes = track.zValues as Array<Float>;

				// fill elevation data
				for(var i=0; i<altitudes.size(); i++){
					data.add(new DataPoint(track.distances[i], altitudes[i]));
				}
			}
		}
		refresh();
	}

	function setDarkMode(darkMode as Boolean) as Void{
		MyDataField.setDarkMode(darkMode);
		
		serieTrack.color = darkMode ? Graphics.COLOR_DK_GRAY : Graphics.COLOR_LT_GRAY;
		trend.setDarkMode(darkMode);
	}

	function onTrackLoaded() as Void{
		serieTrack.updateStatistics();
		updateAxisLimits(trend.series);
		refresh();
	}
	function onNewAltitudeLoaded() as Void{
		refresh();
	}
/*
	// get altitude history
	function initElevationHistory() as Void{
		var distanceHist = $.getApp().history;
		var start = distanceHist.getOldestSampleTime();

		if(start != null){
			var end = Time.now();
			var period = end.subtract(start) as Duration;
			var elevationHist = SensorHistory.getPressureHistory({
				:period => period,
			});

			// loop through elevation data
			var xSample = distanceHist.next();
			var ySample;
			
			while(xSample != null){
				var t0 = xSample.when;
				// get y-sample after previous x-sample
				var t = null;
				do{
					ySample = elevationHist.next();
					t = (ySample != null) ? ySample.when : null;
				}while(t != null && t.lessThan(t0));
				if(t != null && ySample != null){
					var y = ySample.data;

					// get x-values before and after found y
					var x0;
					do{
						x0 = xSample.data;
						t0 = xSample.when;
						xSample = distanceHist.next();
					}while(xSample != null && xSample.when.lessThan(t));

					// Check data available
					if(xSample != null){
						var x1 = xSample.data;
						var t1 = xSample.when;

						if(t != null && t0 != null && t1 != null && x0 != null && x1 != null){
							// now we can interpolate x for y
							var x = x0 + (x1-x0) * (t.value()-t0.value())/(t1.value()-t0.value());
							var xy = new DataPoint(x, y);
							dataLive.add(xy);
						}
					}
				}else{
					break;
				}
			}
		}
	}
*/
	hidden static function min(value1 as Numeric?, value2 as Numeric?) as Numeric?{
		return (value1 != null)
			? (value2 != null)
				? (value1 <= value2)
					? value1
					: value2
				: value1
			: value2;
	}
	hidden static function max(value1 as Numeric?, value2 as Numeric?) as Numeric?{
		return (value1 != null)
			? (value2 != null)
				? (value1 >= value2)
					? value1
					: value2
				: value1
			: value2;
	}

	// adjust axis limits
	hidden function updateAxisLimits(series as Array<Serie>) as Void{
		var xMin = 0;
		var xMax = null;
		var yMin = null;
		var yMax = null;

		for(var i=0; i<series.size(); i++){
			var serie = series[i];
			xMin = min(xMin, serie.getXmin());
			xMax = max(xMax, serie.getXmax());
			yMin = min(yMin, serie.getYmin());
			yMax = max(yMax, serie.getYmax());
		}

		if(xMin != null && xMax != null){
			// minimal distance range = 500m
			if(xMax - xMin < 500){
				xMax = xMin + 500;
			}
			// update xRange with zoomFactor with current X within the range
			var xRange = zoomFactor * (xMax-xMin);
			var pt = marker.pt;
			var x = pt != null ? pt.x : 0;
			var xRange2 = xRange/2;
			if(x <= xRange2){
				xMax = xMin + xRange;
			}else if(x >= xMax-xRange2){
				xMin = xMax - xRange;
			}else{
				xMin = x - xRange2;
				xMax = x + xRange2;
			}

			xAxis.min = xMin;
			xAxis.max = xMax;
		}

		if(yMin != null && yMax != null) {
			// minimal altitude range = 50m
			// prefered yMin = 0
			if(yMin > 0){
				if(yMax <= 50){
					yMin = 0;
				}
			}
			if(yMax - yMin < 50){
				yMax = yMin + 50;
			}

			yAxis.min = yMin;
			yAxis.max = yMax;
		}
	}

	// change zoomFactor from click event
    function onTap(clickEvent as ClickEvent) as Boolean{
        // zoom in/out
        // |   40%    |  20%  |   40%   |
        // | zoom out |       | zoom in |
        var area = 0.4 * width;
        var x = clickEvent.getCoordinates()[0];
        if(x <= locX + area){
            // zoom out
			zoomFactor *= 1.3;
        }else if(x >= locX + width - area){
            // zoom in
			zoomFactor /= 1.3;
        }else{
            return false;
        }
		if(zoomFactor > 1f){
			zoomFactor = 1f;
		}
		updateAxisLimits(trend.series);
		refresh();
        WatchUi.requestUpdate();		
        return true;
	}
}