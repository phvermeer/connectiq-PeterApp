import Toybox.Lang;
import Toybox.Graphics;
import Toybox.Activity;
import MyBarrel.Math2;
import MyBarrel.Layout;
using TrackDrawing;

(:advanced)
class TrackOverviewField extends MyDataField{
    hidden var trackManager as TrackManager;
    hidden var bitmap as BufferedBitmap?;
    hidden var xOffset as Numeric = 0;
    hidden var yOffset as Numeric = 0;

    hidden var zoomFactor as Float = 0.1f;
    hidden var markerSize as Number = 0;
    hidden var xyCurrent as Array<Float>|Null;

    function initialize(options as {
        :darkMode as Boolean
    }){
        MyDataField.initialize(options);
        trackManager = $.getApp().trackManager;

        if(trackManager.xy != null){
            xyCurrent = trackManager.xy;
        }
    }

    function onLayout(dc as Dc){
        // update the bitmap
        updateBitmap(trackManager.track);
    }

    function onUpdate(dc as Dc){
        var track = trackManager.track;
        if(track != null && bitmap != null){
            var bitmap = self.bitmap as BufferedBitmap;

            // Draw the buffered track bitmap (includes start/finish markers and breadcrumps)
            dc.drawBitmap(locX, locY, bitmap);

            // Draw current position marker
            if(xyCurrent != null){
                var x = xOffset + zoomFactor * xyCurrent[0];
                var y = yOffset + zoomFactor * xyCurrent[1];
                var color = darkMode ? Graphics.COLOR_YELLOW : Graphics.COLOR_ORANGE;
                dc.setColor(color, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(x as Float, y as Float, markerSize);
            }
        }
    }
    hidden function updateBitmap(track as Track?) as Void{
        if(track != null){
            var trackThickness = getTrackThickness(zoomFactor);
            markerSize = 2 * trackThickness;

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

            self.xOffset = dummy.locX + dummy.width/2;
            self.yOffset = dummy.locY + dummy.height/2;
            var xOffset = self.xOffset - locX;
            var yOffset = self.yOffset - locY;

            // create the bitmap
            var trackColor = Track.getColor(darkMode);
            var backgroundColor = getBackgroundColor();
            var breadcrumpColor = Track.getColorBehind(darkMode);
            var aheadColor = Track.getColorAhead(darkMode);
            var colorPalette = [backgroundColor, trackColor, breadcrumpColor, aheadColor] as Array<ColorValue>;
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
                dc.setPenWidth(trackThickness);

                // draw track in bitmap
                dc.setColor(trackColor, backgroundColor);
                TrackDrawing.drawPoints(dc, track.xyValues, {
                    :xOffset => xOffset, 
                    :yOffset => yOffset,
                    :xMin => 0,
                    :xMax => width,
                    :yMin => 0,
                    :yMax => height,
                    :zoomFactor => zoomFactor,
                });

                // draw the start marker
                var count = track.xyValues.size();
                var i = 0;
                if(i<count){
                    var xy = track.xyValues[i];
                    var x = xOffset + zoomFactor * xy[0] as Float;
                    var y = yOffset + zoomFactor * xy[1] as Float;
                    dc.setColor(breadcrumpColor, backgroundColor);
                    dc.fillCircle(x, y, markerSize);
                }

                // draw the finish marker
                i = count-1;
                if(i>0){
                    var xy = track.xyValues[i];
                    var x = xOffset + zoomFactor * xy[0] as Float;
                    var y = yOffset + zoomFactor * xy[1] as Float;
                    dc.setColor(aheadColor, backgroundColor);
                    dc.fillCircle(x, y, markerSize);
                }

                // draw breadcrumps
                dc.setColor(breadcrumpColor, backgroundColor);
                var breadcrumps = $.getApp().data.breadcrumps;
                TrackDrawing.drawPoints(dc, breadcrumps, {
                    :xOffset => xOffset, 
                    :yOffset => yOffset,
                    :xMin => 0,
                    :xMax => width,
                    :yMin => 0,
                    :yMax => height,
                    :zoomFactor => zoomFactor,
                });
            }
        }else{
            // clear bitmap
            self.bitmap = null;
        }
    }

    function onSetting(sender as Object, id as Settings.Id, value as Settings.ValueType){
        // internal background updates
        MyDataField.onSetting(sender, id, value);

        if(id == Settings.ID_TRACK){
            // update the track bitmap
            var track = value as Track?;
            updateBitmap(track);
            refresh();
        }
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
        var track = trackManager.track;
        if(track != null && bitmap != null){
            updateBitmap(track);
        }
    }

    function onPosition(sender as Object, xy as XY?) as Void{
        if(xy != null){
            if(xyCurrent != null){
                if(xy[0] != xyCurrent[0] && xy[1] != xyCurrent[1]){
                    if(bitmap != null){
                        // add to breadcrump path
                        var x1 = xOffset - locX + zoomFactor * xyCurrent[0];
                        var y1 = yOffset - locY + zoomFactor * xyCurrent[1];
                        var x2 = xOffset - locX + zoomFactor * xy[0];
                        var y2 = yOffset - locY + zoomFactor * xy[1];

                        var dc = bitmap.getDc();
                        dc.setPenWidth(getTrackThickness(zoomFactor));
                        dc.setColor(Track.getColorBehind(darkMode), getBackgroundColor());
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