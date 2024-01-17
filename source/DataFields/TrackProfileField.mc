import Toybox.Lang;
import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Position;
import Toybox.Application;
import Toybox.Activity;
import Toybox.Time;
using Toybox.Timer;
using Toybox.Math;
import MyBarrel.Lists;
import MyBarrel.Graph;
import MyBarrel.Layout;

(:advanced)
class TrackProfileField extends MyDataField{
	var zoomFactor as Float = 1f; // xRange = zoomFactor*(xMax-xMin)
	var track as Track?;
	var xAxis as Axis;
	var yAxis as Axis;

	hidden var data as BufferedList;
	hidden var serie as Serie;
	hidden var trend as Trend;

	var xCurrent as Float|Null = null;
	
	function initialize(
		options as {
			:track as Track,
			:darkMode as Boolean,
		}
	){
		MyDataField.initialize(options);

		xAxis = new Axis(0, 500); // distance 0..500m
		yAxis = new Axis(0, 50); // altitude 0..50m
		data = new BufferedList({
			:maxCount => 50,
			:listener => self,
		});
		serie = new Graph.Serie({
			:data => data,
			:style => Graph.DRAW_STYLE_FILLED,
		});
		trend = new Graph.Trend({
			:series => [serie] as Array<Serie>,
			:xAxis => xAxis,
			:yAxis => yAxis,
		});
		if(options.hasKey(:track)){
			setTrack(options.get(:track) as Track);
		}
		if(options.hasKey(:darkMode)){
			setDarkMode(options.get(:darkMode) as Boolean);
		}
	}

	function onHide(){
		data.cancel();
	}

	function onLayout(dc as Graphics.Dc){
		// init graph sizes
		var helper = Layout.getLayoutHelper({
			:xMin => locX,
			:xMax => locX + width,
			:yMin => locY,
			:yMax => locY + height,
			:margin => 1,
		});
		trend.setSize(3, 1); // set aspect ratio 3:1
		helper.resizeToMax(trend, true);
	}

	function onActivityInfo(info as Activity.Info) as Void{
		var x = (track != null) ? track.distanceElapsed : null;
		serie.xCurrent = x;
	}

	function onUpdate(dc as Graphics.Dc){
		MyDataField.onUpdate(dc);

		// draw the graph
		if(!data.isLoading()){
			trend.draw(dc);
		}else{
			dc.drawText(locX + width/2, locY + height/2, Graphics.FONT_SMALL, "loading", Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
		}
	}

	function onSetting(id as Settings.Id, value as Settings.ValueType) as Void{
		if(id == Settings.ID_TRACK){
			setTrack(value as Track|Null);
		}else if(id == Settings.ID_DARK_MODE){
			setDarkMode(value as Boolean);
		}
	}

	hidden function setTrack(track as Track?) as Void{
		// update profile with set track
		self.track = track;
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
		// do not refresh yet, wait for onReady event
	}

	function setDarkMode(darkMode as Boolean) as Void{
		MyDataField.setDarkMode(darkMode);
		
		serie.color = darkMode ? Graphics.COLOR_DK_GRAY : Graphics.COLOR_LT_GRAY;
		serie.color2 = darkMode ? Graphics.COLOR_BLUE : Graphics.COLOR_DK_BLUE;
		trend.setDarkMode(darkMode);
	}

	function onReady(sender as Object) as Void{
		if(sender.equals(data)){
			serie.updateStatistics();
			updateAxisLimits(trend.series);
			refresh();
		}
	}

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
		var xMin = 0; // always start at distance 0
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
			var x = xCurrent != null ? xCurrent : 0;
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
			zoomFactor *= 1.3f;
        }else if(x >= locX + width - area){
            // zoom in
			zoomFactor /= 1.3f;
        }else{
            return false;
        }
		if(zoomFactor > 1f){
			zoomFactor = 1f;
		}
		updateAxisLimits(trend.series);
		refresh();
        return true;
	}
}