import Toybox.Lang;
import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Position;
import Toybox.Application;
import MyBarrel.Layout;
import MyBarrel.Math2;

class TrackField extends MyDataField{
    hidden var track as Track?;
    hidden var xyCurrent as Array<Float>|Null;
    hidden var legend as TrackScaleLegend;
    hidden var positionMarker as TrackPositionMarker;
    hidden var zoomFactor as Float;
    hidden var trackThickness as Number = 1;
    hidden var markerSize as Number = 3;

    function initialize(options as {
        :track as Track,
        :xyCurrent as Array<Float>,
    }){
        MyDataField.initialize(options);
        track = options.get(:track);

        zoomFactor = $.getApp().settings.get(SETTING_ZOOMFACTOR) as Float;

        legend = new TrackScaleLegend({
            :zoomFactor => zoomFactor,
            :font => Graphics.FONT_XTINY,
        });
        positionMarker = new TrackPositionMarker({
            :darkMode => darkMode,
        });
    }

    function onLayout(dc as Dc){
        trackThickness = getTrackThickness(zoomFactor);
        legend.updateSize(dc);
        
        // determine marker size
        var deviceSettings = System.getDeviceSettings();
        var screenSize = (deviceSettings.screenWidth > deviceSettings.screenHeight) ? deviceSettings.screenHeight : deviceSettings.screenWidth;
        var fieldSize = (width > height) ? height : width;
        markerSize = Math2.max([screenSize/40, fieldSize/20] as Array<Numeric>).toNumber();


        // determine the drawing area's
        var helper = Layout.getLayoutHelper({
            :xMin => locX,
            :xMax => locX + width,
            :yMin => locY,
            :yMax => locY + height,
        });

        // positioning legend (scale indicator)
        helper.align(legend, Layout.ALIGN_BOTTOM);

        positionMarker.locX = locX + width/2;
        positionMarker.locY = locY + height/2;
    }
    function onUpdate(dc as Dc){
        // draw the legend
        var color = darkMode ? Graphics.COLOR_LT_GRAY : Graphics.COLOR_DK_GRAY;
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        legend.draw(dc);

        // draw the map
        var xOffset = locX + width/2;
        var yOffset = locY + height/2;
        if(xyCurrent != null ){
            xOffset -= zoomFactor * xyCurrent[0];
            yOffset -= zoomFactor * xyCurrent[1];
        }
        dc.setPenWidth(trackThickness);

        var x1 = 0f;
        var y1 = 0f;
        var x2 = 0f;
        var y2 = 0f;
        var xMin = locX;
        var xMax = locX + width;
        var yMin = locY;
        var yMax = locY + height;

        if(self.track != null){
            var track = self.track as Track;
            color = darkMode ? Graphics.COLOR_DK_GRAY : Graphics.COLOR_LT_GRAY;
            var colorToDo = darkMode ? Graphics.COLOR_BLUE : Graphics.COLOR_DK_BLUE;
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);

            x1 = xOffset + zoomFactor * track.xValues[0];
            y1 = yOffset + zoomFactor * track.yValues[0];
            var skip1 = (x1 < xMin || x1 > xMax || y1 < yMin || y1 > yMax);
            var sectionDone = true;
            for(var i=1; i<track.count; i++){
                x2 = xOffset + zoomFactor * track.xValues[i];
                y2 = yOffset + zoomFactor * track.yValues[i];

                if(i-1==track.iCurrent){
                    // extra interpolated point to switch color done => todo
                    if(sectionDone){
                        var l = track.lambdaCurrent;
                        if(l != null){
                            x2 = x1 + (x2-x1)*l;
                            y2 = y1 + (y2-y1)*l;
                            sectionDone = false;
                            i--;
                        }
                    }else{
                        dc.setColor(colorToDo, Graphics.COLOR_TRANSPARENT);
                    }
                }

                var skip2 = (x2 < xMin || x2 > xMax || y2 < yMin || y2 > yMax);
                if(!skip1 || !skip2){
                    dc.drawLine(x1, y1, x2, y2);
                }

                skip1 = skip2;
                x1 = x2;
                y1 = y2;
            }
        }

        // draw bread crumps (with interpolation of points outside viewers range)
        color = darkMode ? Graphics.COLOR_PURPLE : Graphics.COLOR_PINK;
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);

        var points = $.getApp().data.getBreadcrumps();
        var count = points.size();
        if(count >= 1){
            var p1 = points[0];
            var skip1 = true;
            if(p1 != null){
                x1 = xOffset + zoomFactor * p1[0];
                y1 = yOffset + zoomFactor * p1[1];
                skip1 = (x1 < xMin || x1 > xMax || y1 < yMin || y1 > yMax);
            }

            for(var i=1; i<count; i++){
                var p2 = points[i];
                var skip2 = true;
                if(p2 != null){
                    x2 = xOffset + zoomFactor * p2[0];
                    y2 = yOffset + zoomFactor * p2[1];

                    skip2 = (x2 < xMin || x2 > xMax || y2 < yMin || y2 > yMax);

                    if(p1 != null){

                        // interpolate
                        if(skip1 && !skip2){
                            var xy = Math2.interpolateXY(x1, y1, x2, y2, xMin, xMax, yMin, yMax);
                            x1 = xy[0];
                            y1 = xy[1];
                        }else if(!skip1 && skip2){
                            var xy = Math2.interpolateXY(x2, y2, x1, y1, xMin, xMax, yMin, yMax);
                            x2 = xy[0];
                            y2 = xy[1];
                        }
                        
                        // draw
                        if(!skip1 || !skip2){
                            dc.drawLine(x1, y1, x2, y2);
                        }
                    }
                    x1 = x2;
                    y1 = y2;
                }
                p1 = p2;
                skip1 = skip2;
            }

            if(xyCurrent != null){
                // draw from last breadcrump to current xy
                x2 = xOffset + zoomFactor * xyCurrent[0];
                y2 = yOffset + zoomFactor * xyCurrent[1];

                if(skip1){
                    var xy = Math2.interpolateXY(x1, y1, x2, y2, xMin, xMax, yMin, yMax);
                    x1 = xy[0];
                    y1 = xy[1];
                }

                dc.drawLine(x1, y1, x2, y2);
            }
        }

        if(track != null){
            var i = track.count - 1;
            var x = xOffset + zoomFactor * track.xValues[i];
            var y = yOffset + zoomFactor * track.yValues[i];

            // draw finish marker
   	        color = darkMode ? Graphics.COLOR_GREEN : Graphics.COLOR_DK_GREEN;
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(x, y, markerSize);
        }

        // draw current position marker
        if(xyCurrent != null){
            positionMarker.draw(dc);
        }
    }

    hidden function setZoomFactor(value as Float) as Void{
        if(value != zoomFactor){
            zoomFactor = value;
            trackThickness = getTrackThickness(zoomFactor);
            legend.setZoomFactor(zoomFactor);
            refresh();
        }
    }

    hidden function setTrack(track as Track?) as Void{
        self.track = track;
        refresh();
    }

    function onTap(clickEvent as ClickEvent) as Boolean{
        // zoom in/out
        // |   40%    |  20%  |   40%   |
        // | zoom out |       | zoom in |
        var area = 0.4 * width;
        var x = clickEvent.getCoordinates()[0];
        var settings = $.getApp().settings;
        if(x <= locX + area){
            // zoom out
            settings.set(SETTING_ZOOMFACTOR, zoomFactor / 1.3);
        }else if(x >= locX + width - area){
            // zoom in
            settings.set(SETTING_ZOOMFACTOR, zoomFactor * 1.3);
        }else{
            return false;
        }
        return true;
    }

    function onSetting(id as SettingId, value as Settings.ValueType) as Void{
        // internal background updates
        MyDataField.onSetting(id, value);

        if(id == SETTING_ZOOMFACTOR){
            // update zoomfactor
            setZoomFactor(value as Float);
        }else if(id == SETTING_TRACK){
            setTrack(value as Track?);
        }
    }

    hidden function getTrackThickness(zoomFactor as Float) as Number{
		var size = (width < height) ? width : height;
        var trackThickness = 1;
		if(size > 0){
            var ds = System.getDeviceSettings();
			var thicknessMax = (size > 10) ? size / 10 : 1;
			var thicknessMin = Math.ceil(0.01f * ds.screenWidth);

			var range = size / zoomFactor; // [m]
			// 0 → 50m:		 	maxPenWidth
			// 50m → 5km: 		scaled between maxPenWidth and minPenWidth
			// 5km → ∞:			minPenWidth
			var rangeMin = 50;
			var rangeMax = 10000;

			if(range <= rangeMin){
				trackThickness = thicknessMax.toNumber();
			} else if(range >= rangeMax){
				trackThickness = thicknessMin.toNumber();
			}else{
				// The penWidth between rangeMin and rangeMax:
				var rangeFactor = rangeMax / rangeMin;  
				var thicknessFactor = thicknessMax / thicknessMin;
				// use the log value to convert range to penWidth
				var log = Math.log(thicknessFactor, rangeFactor); 

				// the scaling from range between rangemin and rangeMax will result in 
				// the equalvalent of the penWIdth between penWidthMax end penWIdthMin using a logaritmic correction
				trackThickness = Math.round(thicknessMax / Math.pow(range/rangeMin, log)).toNumber();			
			}
		}
        return trackThickness;
    }

    function onData(data as Data) as Void{
        var xy = data.xy;
        var info = data.positionInfo;
        var quality = info.accuracy;
        if(xy != null && quality >= Position.QUALITY_USABLE && xy != xyCurrent){
            var heading = info.heading;
            xyCurrent = xy;
            positionMarker.setHeading(heading);
            refresh();
        }
    }

    function setDarkMode(darkMode as Boolean) as Void{
        MyDataField.setDarkMode(darkMode);
        positionMarker.setDarkMode(darkMode);
    }
}
