import Toybox.Lang;
import Toybox.Graphics;
import Toybox.Position;
import MyBarrel.Math2;
import MyBarrel.Layout;

class TrackOverviewField extends MyDataField{
    hidden var track as Track?;
    hidden var bitmap as BufferedBitmap?;
    hidden var xOffset as Numeric = 0;
    hidden var yOffset as Numeric = 0;

    hidden var zoomFactor as Float = 0.1f;
    hidden var markerSize as Number = 0;
    hidden var xyCurrent as Array<Float>|Null;

    function initialize(options as {
        :track as Track
    }){
        MyDataField.initialize(options);
        track = options.get(:track);

        if(track != null && track.xCurrent != null && track.yCurrent != null){
            xyCurrent = [track.xCurrent, track.yCurrent] as Array<Float>;;
        }
    }

    function onLayout(dc as Dc){
        // determine marker size
        var deviceSettings = System.getDeviceSettings();
        var screenSize = (deviceSettings.screenWidth > deviceSettings.screenHeight) ? deviceSettings.screenHeight : deviceSettings.screenWidth;
        var fieldSize = (width > height) ? height : width;
        markerSize = Math2.max([screenSize/40, fieldSize/20] as Array<Numeric>).toNumber();

        // update the bitmap
        updateBitmap(track);
    }

    function onUpdate(dc as Dc){
        if(track != null && bitmap != null){
            var track = self.track as Track;
            var bitmap = self.bitmap as BufferedBitmap;

            // Draw the track
            dc.drawBitmap(locX as Numeric, locY as Numeric, bitmap);

            // Draw the finish marker
            var i = track.count-1;
            if(i>0){
                var x = xOffset + zoomFactor * track.xValues[i];
                var y = yOffset + zoomFactor * track.yValues[i];
                var color = darkMode ? Graphics.COLOR_GREEN : Graphics.COLOR_DK_GREEN;
                dc.setColor(color, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(x, y, markerSize);
            }

            // Draw current position marker
            if(xyCurrent != null){
                var x = xOffset + zoomFactor * xyCurrent[0];
                var y = yOffset + zoomFactor * xyCurrent[1];
                var color = darkMode ? Graphics.COLOR_BLUE : Graphics.COLOR_BLUE;
                dc.setColor(color, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(x as Float, y as Float, markerSize);
            }
        }
    }
    hidden function updateBitmap(track as Track?) as Void{
        if(track != null){
            var helper = Layout.getLayoutHelper({
                :xMin => locX,
                :xMax => locX + width,
                :yMin => locY,
                :yMax => locY + height,
                :margin => markerSize,
            });

            var dummy = new Drawable({
                :width => track.xMax - track.xMin,
                :height => track.yMax - track.yMin,
            });

            helper.resizeToMax(dummy, false);

            xOffset = dummy.locX + dummy.width/2;
            yOffset = dummy.locY + dummy.height/2;

            // create the bitmap
            var trackColor = getTrackColor();
            var backgroundColor = getBackgroundColor();
            var breadcrumpColor = getBreadcrumpColor();
            var colorPalette = [Graphics.COLOR_TRANSPARENT, trackColor, backgroundColor, breadcrumpColor] as Array<ColorValue>;
            var bitmap = new Graphics.BufferedBitmap({
                :width => width.toNumber(),
                :height => height.toNumber(),
                :palette => colorPalette,
            });
            self.bitmap = bitmap;

            // calculate the zoom factor to show the whole track
            var factorHor = (dummy.width.toFloat()) / (track.xMax - track.xMin);
            var factorVert = (dummy.height.toFloat()) / (track.yMax - track.yMin);
            zoomFactor = factorHor < factorVert ? factorHor : factorVert;

            // draw the track and buffered breadcrumps
            var dc = bitmap.getDc();

            if(dc != null){
                var count = track.count;

                var penWidth = getTrackThickness(zoomFactor);
                dc.setPenWidth(penWidth);
                dc.setColor(trackColor, backgroundColor);

                var x1 = xOffset + zoomFactor * track.xValues[0];
                var y1 = yOffset + zoomFactor * track.yValues[0];
                var x2;
                var y2;

                for(var i=1; i<count; i++){
                    x2 = xOffset + zoomFactor * track.xValues[i];
                    y2 = yOffset + zoomFactor * track.yValues[i];

                    dc.drawLine(x1, y1, x2, y2);

                    x1 = x2;
                    y1 = y2;
                }

                // breadcrumps
                var breadcrumps = $.getApp().data.getBreadcrumps();
                count = breadcrumps.size();
                if(count>=2){
                    var xMin = locX;
                    var xMax = locX + width;
                    var yMin = locY;
                    var yMax = locY + height;

                    dc.setColor(breadcrumpColor, backgroundColor);
                    var p1 = breadcrumps[0];
                    var skip1 = true;
                    if(p1 != null){
                        x1 = xOffset + zoomFactor * p1[0];
                        y1 = yOffset + zoomFactor * p1[1];
                        skip1 = (x1 < xMin || x1 > xMax || y1 < yMin || y1 > yMax);
                    }
                    for(var i=1; i<breadcrumps.size(); i++){
                        var p2 = breadcrumps[i];
                        if(p2 != null){
                            x2 = xOffset + zoomFactor * p2[0];
                            y2 = yOffset + zoomFactor * p2[1];
                            var skip2 = (x2 < xMin || x2 > xMax || y2 < yMin || y2 > yMax);

                            // interpolate with points outside field area
                            if(skip1 && !skip2){
                                var xy = Math2.interpolateXY(x1, y1, x2, y2, xMin, xMax, yMin, yMax);
                                x1 = xy[0];
                                y1 = xy[1];
                            }else if(!skip1 && skip2){
                                var xy = Math2.interpolateXY(x2, y2, x1, y1, xMin, xMax, yMin, yMax);
                                x2 = xy[0];
                                y2 = xy[1];
                            }

                            if(p1 != null && (!skip1 || !skip2)){
                                dc.drawLine(x1, y1, x2, y2);
                            }
                            x1 = x2;
                            y1 = y2;
                            skip1 = skip2;
                        }
                        p1 = p2;
                    }
                }
            }
        }else{
            // clear bitmap
            self.bitmap = null;
        }
    }

    function onSetting(id, value){
        MyDataField.onSetting(id, value);
        if(id == SETTING_TRACK){
            // update the track bitmap
            track = value as Track?;
            updateBitmap(track);
            refresh();
        }
    }

    hidden function getTrackColor() as ColorType{
        return darkMode ? Graphics.COLOR_LT_GRAY : Graphics.COLOR_DK_GRAY;
    }
    hidden function getBreadcrumpColor() as ColorType{
        return Graphics.COLOR_PINK;
    }
    hidden function getTrackThickness(zoomFactor as Float) as Number{
		var size = (width < height) ? width : height;
        var trackThickness = 1;
		if(size > 0 && zoomFactor > 0){
            var ds = System.getDeviceSettings();
			var thicknessMax = (size > 10) ? size / 10 : 1;
			var thicknessMin = Math.ceil(0.01f * ds.screenWidth);

			var range = size / zoomFactor; // [m]
			// 0 → 50m:		 	maxPenWidth
			// 50m → 10km: 		scaled between maxPenWidth and minPenWidth
			// 10km → ∞:			minPenWidth
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

    function setDarkMode(darkMode as Boolean) as Void{
        MyDataField.setDarkMode(darkMode);

        // update track bitmap with updated colors
        var track = $.getApp().track;
        if(track != null && bitmap != null){
            updateBitmap(track);
        }
    }

    function onData(data as Data) as Void{
        var xy = data.xy;
        if(xy != null){
            if(xyCurrent != null){
                if(xy[0] != xyCurrent[0] && xy[1] != xyCurrent[1]){
                    if(bitmap != null){
                        // add to breadcrump path
                        var x1 = xOffset + zoomFactor * xyCurrent[0];
                        var y1 = yOffset + zoomFactor * xyCurrent[1];
                        var x2 = xOffset + zoomFactor * xy[0];
                        var y2 = yOffset + zoomFactor * xy[1];

                        var dc = bitmap.getDc();
                        var penWidth = getTrackThickness(zoomFactor);
                        dc.setPenWidth(penWidth);
                        dc.setColor(Graphics.COLOR_PINK, Graphics.COLOR_TRANSPARENT);
                        dc.drawLine(x1, y1, x2, y2);
                    }

                    // save and show new position
                    xyCurrent = xy;
                    refresh();
                }
            }else{
                xyCurrent = xy;
                refresh();
            }
        }
    }
}