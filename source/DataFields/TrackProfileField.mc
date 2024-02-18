import Toybox.Lang;
import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Application;
import Toybox.Activity;
using Toybox.Timer;
using Toybox.Math;
import MyBarrel;

(:advanced)
class TrackProfileField extends MyDataField{
	var zoomFactor as Float = 1f; // xRange = zoomFactor*(xMax-xMin)
	var xAxis as Graph.Axis;
	var yAxis as Graph.Axis;

	hidden var distance as Float = 0f;
	hidden var pts as Array<Graph.Point> = new Array<Graph.Point>[0];
	hidden var serie as Graph.Serie;
	hidden var serieColored as Graph.Serie;
	hidden var serieLine as Graph.Serie;
	hidden var trend as Graph.Trend;
	hidden var xCurrent as Float|Null = null;
	
	function initialize(
		options as {
			:track as Track,
			:darkMode as Boolean,
		}
	){
		MyDataField.initialize(options);

		xAxis = new Graph.Axis(0, 500); // distance 0..500m
		yAxis = new Graph.Axis(0, 50); // altitude 0..50m

		serie = new Graph.Serie({
			:pts => pts,
			:style => Graph.DRAW_STYLE_FILLED,
			:color => Graphics.COLOR_LT_GRAY,
		});
		serieColored = new Graph.Serie({
			:pts => pts,
			:style => Graph.DRAW_STYLE_FILLED,
			:color => Graphics.COLOR_DK_BLUE,
		});
		serieLine = new Graph.Serie({
			:penWidth => 1,
			:pts => pts,
			:style => Graph.DRAW_STYLE_LINE,
			:color => Graphics.COLOR_BLACK,
		});
		trend = new Graph.Trend({
			:series => [serie, serieColored, serieLine] as Array<Graph.Serie>,
			:xAxis => xAxis,
			:yAxis => yAxis,
		});

		setTrack(options.get(:track) as Track?);

		if(options.hasKey(:darkMode)){
			setDarkMode(options.get(:darkMode) as Boolean);
		}
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
		var trackManager = $.getApp().trackManager;
		// split graph in two: before and after current position
		if(pts.size() > 0){
			var index = trackManager.index;
			var lambda = trackManager.lambda;

			if(index != null && lambda != null){
				// interpolated point between point before and after
				var pt0 = pts[index];
				var pt1 = pts[index+1];
				var x0 = pt0[0];
				var y0 = pt0[1];
				var x1 = pt1[0];
				var y1 = pt1[1];
				var x = x0 + lambda * (x1-x0);
				var y = y0 + lambda * (y1-y0);
				var pt = [x, y] as Graph.Point;

				var pts1 = pts.slice(null, index+1);
				pts1.add(pt);
				var pts2 = [pt] as Array<Graph.Point>;
				pts2.addAll(pts.slice(index+1, null));
				
				serie.pts = pts1;
				serieColored.pts = pts2;
			}
		}
	}

	function onUpdate(dc as Graphics.Dc){
		MyDataField.onUpdate(dc);

		// draw background
		dc.setColor(darkMode ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
		dc.fillRectangle(trend.locX, trend.locY, trend.width, trend.height);

		// draw the graph
		trend.draw(dc);
	}

	function onSetting(id as Settings.Id, value as Settings.ValueType) as Void{
		if(id == Settings.ID_TRACK){
			setTrack(value as Track|Null);
		}else if(id == Settings.ID_DARK_MODE){
			setDarkMode(value as Boolean);
		}
	}

	hidden function setTrack(track as Track?) as Void{

		// update graph data
		if(track != null){
			pts = getPoints(track);
			distance = track.distance;
		}else{
			pts = new Array<Graph.Point>[0];
			distance = 0f;
		}

		serie.pts = pts;
		serieColored.pts = new Array<Graph.Point>[0];
		serieLine.pts = pts;

		// update axis ranges
		updateXAxisLimits();
		updateYAxisLimits();
		
		refresh();
	}

	// retrieve graph data from track
	hidden function getPoints(track as Track) as Array<Graph.Point>{
		var altitudes = track.zValues;
		if(altitudes != null){
			var distances = track.distances;
			if(distances.size() == altitudes.size()){
				var pts = new[distances.size()] as Array<Graph.Point>;
				for(var i=0; i<distances.size(); i++){
					var x = distances[i];
					var y = altitudes[i];
					pts[i] = [x, y] as Graph.Point;
				}
				return pts;
			}
		}
		return [] as Array<Graph.Point>;
	}

	function setDarkMode(darkMode as Boolean) as Void{
		MyDataField.setDarkMode(darkMode);
		
		serie.color = darkMode ? Graphics.COLOR_DK_GRAY : Graphics.COLOR_LT_GRAY;
		serieColored.color = darkMode ? Graphics.COLOR_BLUE : Graphics.COLOR_DK_BLUE;
		serieLine.color = darkMode ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
		trend.setDarkMode(darkMode);
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
	hidden function updateYAxisLimits() as Void{
		// y-axis
		var yMin = null as Numeric|Null;
		var yMax = null as Numeric|Null;

		for(var i=0; i<pts.size(); i++){
			var pt = pts[i] as Graph.Point|Null;
			if(pt != null){
				var y = pt[1] as Numeric;
				if(yMin != null && yMax != null){
					if(y < yMin){
						yMin = y;
					}
					if(y > yMax){
						yMax = y;
					}
				}else{
					yMin = y;
					yMax = y;
				}
			}
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

	hidden function updateXAxisLimits() as Void{
		// x-axis
		var xMin = 0; // always start at distance 0
		var xMax = self.distance;

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
		updateXAxisLimits();
		refresh();
        return true;
	}
}