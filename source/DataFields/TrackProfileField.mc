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
	hidden var waypoints as Array<Graph.Point> = [] as Array<Graph.Point>;
	hidden var serieElapsed as Graph.Serie;
	hidden var serieAhead as Graph.Serie;
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

		serieAhead = new Graph.Serie({
			:pts => pts,
			:style => Graph.DRAW_STYLE_FILLED,
			:color => Graphics.COLOR_LT_GRAY,
		});
		serieElapsed = new Graph.Serie({
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
			:series => [serieAhead, serieElapsed, serieLine] as Array<Graph.Serie>,
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

	function onPosition(trackManager as TrackManager, xy as XY?) as Void{
		xCurrent = trackManager.elapsedDistance;

		// split graph in two: before and after current position
		serieAhead.pts = [] as Array<Graph.Point>;
		if(pts.size() > 0){
			if(xCurrent != null){
				var index = serieLine.getIndexForX(xCurrent);
				if(index != null){
					var i = index.toNumber();
					if(index instanceof Number){
						// exact at track point
						serieElapsed.pts = pts.slice(null, i+1);
						serieAhead.pts = pts.slice(i, null);
					}else{
						// interpolated
						var yCurrent = serieLine.getYforIndex(index);
						var pt = [xCurrent, yCurrent] as Graph.Point;

						serieElapsed.pts = pts.slice(null, i+1);
						serieElapsed.pts.add(pt);

						serieAhead.pts = [pt] as Array<Graph.Point>;
						serieAhead.pts.addAll(pts.slice(i+1, null));
					}
				}else{
					// out of range
					serieElapsed.pts = [] as Array<Graph.Point>;
					serieAhead.pts = pts;
				}
			}
			refresh();
		}
	}

	function onUpdate(dc as Graphics.Dc){
		MyDataField.onUpdate(dc);

		// draw background
		dc.setColor(darkMode ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
		dc.fillRectangle(trend.locX, trend.locY, trend.width, trend.height);

		// draw the graph
		trend.draw(dc);

		// draw waypoints
		var size = (width > height ? width : height) / 10;
		var wp = new WaypointMarker({ 
			:size => size.toNumber(),
		});
		dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
		for(var i=0; i<waypoints.size(); i++){
			var pt = waypoints[i];
			var xy = serieLine.getScreenPosition(pt);
			if(xy != null){
				wp.locX = xy[0];
				wp.locY = xy[1];
				wp.draw(dc);
			}
		}
	}

	function onSetting(sender as Object, id as Settings.Id, value as Settings.ValueType) as Void{
        // internal background updates
		MyDataField.onSetting(sender, id, value);

		if(id == Settings.ID_TRACK){
			setTrack(value as Track|Null);
		}
	}

	hidden function setTrack(track as Track?) as Void{

		// update graph data and waypoints
		if(track != null){
			pts = getPoints(track);
			distance = track.distance;
		}else{
			pts = new Array<Graph.Point>[0];
			distance = 0f;
		}

		serieAhead.pts = pts;
		serieElapsed.pts = new Array<Graph.Point>[0];
		serieLine.pts = pts;

		// update waypoints
		waypoints = [] as Array<Graph.Point>;
		if(track != null){
			for(var i=0; i<track.waypoints.size(); i++){
				var wp = track.waypoints[i];
				var x = wp.distance;
				var y = wp.z != null ? wp.z : serieLine.getYforX(x);
				waypoints.add([x, y] as Graph.Point);
			}
		}

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
				var pts = [] as Array<Graph.Point>;
				for(var i=0; i<distances.size(); i++){
					var x = distances[i];
					var y = altitudes[i];
					if(x != null && y != null){
						pts.add([x, y] as Graph.Point);
					}
				}
				return pts;
			}
		}
		return [] as Array<Graph.Point>;
	}

	function setDarkMode(darkMode as Boolean) as Void{
		MyDataField.setDarkMode(darkMode);
		
		serieAhead.color= TrackDrawer.getColor(darkMode);
		serieElapsed.color= TrackDrawer.getColorAhead(darkMode);
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