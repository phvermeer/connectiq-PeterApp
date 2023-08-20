import Toybox.Lang;
import Toybox.Graphics;
import Toybox.Position;
using Toybox.Timer;
using Toybox.Math;
import MyGraph;
import MyLayoutHelper;
using MyTools;

class TrackProfileField extends MyDataField{
	var track as Track?;
	var serie as MyGraph.Serie;
	var data as MyGraph.FilteredData?;
	var trend as MyGraph.Trend;
	var bitmap as BufferedBitmap|Null;
	
	function initialize(
		options as {
			:track as Track,
			:xyCurrent as Array<Float>,
		}
	){
		MyDataField.initialize(options);
		serie = new MyGraph.Serie({
			:color => Graphics.COLOR_LT_GRAY,
		});
		trend = new MyGraph.Trend({
			:series => [serie] as Array<Serie>,
			:width => 3,
			:height => 1,
		});
		if(options.hasKey(:track)){
			setTrack(options.get(:track));
		}
		
		setBackgroundColor(backgroundColor);
	}

	function onLayout(dc as Graphics.Dc){
		// init graph sizes
		var margin = 3;
		var helper = new RoundScreenHelper({
			:xMin => locX,
			:xMax => locX + width,
			:yMin => locY,
			:yMax => locY + height,
		});

		helper.resizeToMax(trend, true, margin);
		bitmap = new Graphics.BufferedBitmap({
			:width as Numeric => trend.width,
			:height as Numeric => trend.height
		});
		updateBitmap();
	}

	function onPosition(xy as Array<Float>|Null, heading as Float?, quality as Position.Quality) as Void{
		doUpdate = true;
	}

	function onUpdate(dc as Graphics.Dc){
		// draw the graph
		MyDataField.onUpdate(dc);
		
		if(self.track != null){
			var track = self.track as Track;
			if(track.zValues != null){
				
				if(bitmap != null){
					dc.drawBitmap(trend.locX, trend.locY, bitmap);
				}

				if(track.iCurrent != null && track.lambdaCurrent != null && track.distanceElapsed != null && track.isOnTrack()){
					// mark current position
					var i = track.iCurrent as Number;
					var lambda = track.lambdaCurrent as Float;
					var altitudes = track.zValues as Array<Float>;

					var distance = track.distanceElapsed as Float;
					var altitude = altitudes[i];
					if(lambda > 0f){
						var altitudeNext = altitudes[i+1];
						altitude += lambda * (altitudeNext-altitude);
					}
					trend.drawCurrentXY(dc, distance, altitude);
				}
			}
		}
	}
	
	function setTrack(track as Track?) as Void{
		// update profile with set track
		self.track = track;
		if(track != null){
			if(track.zValues != null){			
				var altitudes = track.zValues as Array<Float>;
				var updateMethod = method(:updateBitmap);

				// fill elevation data
				var data = new MyGraph.FilteredData({
					:maxCount => 50,
					:reducedCount => 30,
					:onUpdated => updateMethod,
				});
				self.data = data;
				serie.data = data;
				for(var i=0; i<altitudes.size(); i++){
					data.addDataPoint(new DataPoint(track.distances[i], altitudes[i]));
				}

				// draw profile (when data is loaded) in buffered bitmap
				if(!data.isLoading()){
					updateBitmap();
				}
			}
		}else{
			data = null;
		}
		doUpdate = true;
	}

	function setBackgroundColor(color as Graphics.ColorType) as Void{
		MyDataField.setBackgroundColor(color);
		var intensity = Math.mean(MyTools.colorToRGB(color));
		var isDarkMode = (intensity < 100);
		
		serie.color = isDarkMode ? Graphics.COLOR_DK_GRAY : Graphics.COLOR_LT_GRAY;
		trend.setDarkMode(isDarkMode);

		// redraw buffered trend
		updateBitmap();
	}

	function updateBitmap() as Void{
		if(bitmap != null){
			// temporarily adjust location in trend
			// , because drawing is on bitmap instead of on screen
			var dc = bitmap.getDc();
			var x = trend.locX;
			var y = trend.locY;
			trend.setLocation(0, 0);
			dc.clear();
			trend.draw(dc);
			trend.setLocation(x, y);
		}
		self.doUpdate = true;
	}
}