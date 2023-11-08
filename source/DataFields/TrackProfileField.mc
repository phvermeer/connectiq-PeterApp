import Toybox.Lang;
import Toybox.Graphics;
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

		xAxis = new Axis(0, 10000); // distance 0..1km
		yAxis = new Axis(0, 100); // altitude 0..100m
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
//			:series => [serieTrack, serieLive] as Array<Serie>,
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
		
		setBackgroundColor(backgroundColor);

		// Load historical altitude data
		initElevationHistory();
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
		var margin = 1;
		var helper = new RoundScreenHelper({
			:xMin => locX,
			:xMax => locX + width,
			:yMin => locY,
			:yMax => locY + height,
		});

		helper.resizeToMax(trend, true, margin);
	}

	function onPosition(xy as PositionManager.XyPoint, info as Position.Info) as Void{
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

	function onActivityInfo(info as Activity.Info) as Void{
		// add altitude to dataLive
		var distance = 
			(track != null)
				? track.distanceElapsed
				: info.elapsedDistance;
		if(distance != null){
			var altitude = info.altitude;
			if(track != null && !track.isOnTrack()){
				altitude = null;
			}

/*			// debug
			if(altitude != null){
				var range = yAxis.max - yAxis.min;
				while(altitude > yAxis.max){
					altitude -= range;
				}
				while(altitude < yAxis.min){
					altitude += range;
				}
			}
*/
			var xy = new MyGraph.DataPoint(distance, altitude);
			dataLive.add(xy);
			updateAxisLimits(distance, altitude);
		}
	}

	function onUpdate(dc as Graphics.Dc){
		MyDataField.onUpdate(dc);

		// draw the graph
		trend.draw(dc);
		marker.draw(dc);

	}
	
	function onSetting(id as SettingId, value as PropertyValueType) as Void{
		if(id == SETTING_TRACK){
			var track = $.getApp().track;
			if(track != null){
				setTrack(track);
			}
		}
	}

	function setTrack(track as Track) as Void{

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

	function setBackgroundColor(color as Graphics.ColorType) as Void{
		MyDataField.setBackgroundColor(color);
		var intensity = Math.mean(MyTools.colorToRGB(color));
		var isDarkMode = (intensity < 100);
		
		serieTrack.color = isDarkMode ? Graphics.COLOR_DK_GRAY : Graphics.COLOR_LT_GRAY;
		trend.setDarkMode(isDarkMode);
	}

	function onTrackLoaded() as Void{
		serieTrack.updateStatistics();
		xAxis.min = serieTrack.getXmin() as Numeric;
		xAxis.max = serieTrack.getXmax() as Numeric;
		yAxis.min = serieTrack.getYmin() as Numeric;
		yAxis.max = serieTrack.getYmax() as Numeric;
		refresh();
	}
	function onNewAltitudeLoaded() as Void{
		refresh();
	}

	// get altitude history
	function initElevationHistory() as Void{
		var distanceHist = $.getApp().history;
		var start = distanceHist.getOldestSampleTime();

		if(start != null){
			var end = Time.now();
			var period = end.subtract(start) as Duration;
			var elevationHist = SensorHistory.getPressureHistory({
				:period => period,
				:order => SensorHistory.ORDER_OLDEST_FIRST,
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

	// adjust axis limits
	function updateAxisLimits(x as Numeric?, y as Numeric?) as Void{
		if(x != null){
			if(x < xAxis.min){
				xAxis.min = x;
			}else if(x > xAxis.max){
				xAxis.max = x;
			}
		}
		if(y != null){
			if(y < yAxis.min){
				yAxis.min = y;
			}else if(y > yAxis.max){
				yAxis.max = y;
			}
		}
	}
}