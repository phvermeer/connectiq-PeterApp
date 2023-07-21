import Toybox.Lang;
import Toybox.Graphics;
import Toybox.Position;

class TrackOverviewField extends MyDataField{
    hidden var bitmap as BufferedBitmap?;
    hidden var xBitmap as Numeric = 0;
    hidden var yBitmap as Numeric = 0;
    hidden var wBitmap as Numeric = 1;
    hidden var hBitmap as Numeric = 1;
    hidden var track as Track?;
    hidden var zoomFactor as Float = 1f;
    hidden var markerSize as Number = 0;
    hidden var darkMode as Boolean = false;
    hidden var xCurrent as Float?;
    hidden var yCurrent as Float?;

    function initialize(options as {
        :track as Track
    }){
        MyDataField.initialize(options);
        track = options.get(:track);

        // update darkmode
        setBackgroundColor(backgroundColor);
    }

    function onLayout(dc as Dc){
        // determine the drawing area
        if(track != null){
            var helper = new MyLayoutHelper.RoundScreenHelper({
                :xMin => locX,
                :xMax => locX + width,
                :yMin => locY,
                :yMax => locY + height,
            });
            var dummy = new Drawable({
                :width => track.xMax - track.xMin,
                :height => track.yMax - track.yMin,
            });
            helper.resizeToMax(dummy, false);

            // create the bitmap
            var color = getTrackColor();
            bitmap = new Graphics.BufferedBitmap({
                :width => dummy.width.toNumber(),
                :height => dummy.height.toNumber(),
                :palette => [color, Graphics.COLOR_TRANSPARENT] as Array<ColorValue>,
            });
            xBitmap = dummy.locX;
            yBitmap = dummy.locY;
            wBitmap = dummy.width;
            hBitmap = dummy.height;
        }

        // determine marker size
        var deviceSettings = System.getDeviceSettings();
        var screenSize = (deviceSettings.screenWidth > deviceSettings.screenHeight) ? deviceSettings.screenHeight : deviceSettings.screenWidth;
        var fieldSize = (width > height) ? height : width;
        markerSize = MyMath.max([screenSize/40, fieldSize/20] as Array<Numeric>).toNumber();

        // draw the bitmap
        if(track != null && bitmap != null){
            drawTrack(bitmap, track as Track, markerSize);
        }

    }

    function onUpdate(dc as Dc){
        // show bitmap
        dc.setColor(Graphics.COLOR_TRANSPARENT, backgroundColor);
        dc.clear();

        // draw markers
        var xOffset = xBitmap + wBitmap/2;
        var yOffset = yBitmap + hBitmap/2;
        if(track != null){
            var track = self.track as Track;
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
            if(xCurrent != null && yCurrent != null){
                var x = xOffset + zoomFactor * xCurrent;
                var y = yOffset + zoomFactor * yCurrent;
                var color = darkMode ? Graphics.COLOR_BLUE : Graphics.COLOR_BLUE;
                dc.setColor(color, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(x as Float, y as Float, markerSize);
            }

            // Draw the track
            if(bitmap != null){
                dc.drawBitmap(xBitmap as Numeric, yBitmap as Numeric, bitmap);
            }
        }
    }

    function updateTrack() as Void{
        var track = $.getApp().track;
        setTrack(track);
    }

    function setTrack(track as Track?) as Void{
        self.track = track;
        if(bitmap != null){
            if(track != null){
                drawTrack(bitmap, track, markerSize);
            }else{
                bitmap.getDc().clear();
            }
        }
    }

    function drawTrack(bitmap as BufferedBitmap, track as Track, margin as Number) as Void{
        var dc = bitmap.getDc();
        if(dc != null){
            var w = dc.getWidth() - 2*margin;
            var h = dc.getHeight() - 2*margin;
            var colorPalette = bitmap.getPalette();
            dc.setColor(colorPalette[0], colorPalette[1]);
            dc.clear();
            var factorHor = w / (track.xMax - track.xMin);
            var factorVert = h / (track.yMax - track.yMin);
            zoomFactor = factorHor<factorVert ? factorHor : factorVert;
            var count = track.count;
            dc.setPenWidth(getTrackThickness(zoomFactor));

            var x1 = margin + zoomFactor * track.xValues[0] + w/2;
            var y1 = margin + zoomFactor * track.yValues[0] + h/2;
            for(var i=1; i<count; i++){
                var x2 = margin + zoomFactor * track.xValues[i] + w/2;
                var y2 = margin + zoomFactor * track.yValues[i] + h/2;

                dc.drawLine(x1, y1, x2, y2);

                x1 = x2;
                y1 = y2;
            }
        }
    }

    function getTrackColor() as ColorType{
        return darkMode ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
    }
    hidden function getTrackThickness(zoomFactor as Float) as Number{
		var size = (width < height) ? width : height;
        var trackThickness = 1;
		if(size > 0){
			var thicknessMax = (size > 10) ? size / 10 : 1;
			var thicknessMin = 1;
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
    function setBackgroundColor(color as ColorType) as Void{
        MyDataField.setBackgroundColor(color);
        var rgb = MyTools.colorToRGB(backgroundColor);
        var intensity = Math.mean(rgb);
        darkMode = (intensity < 100);

        // update color palette of bitmap
        var trackColor = getTrackColor();
        if(bitmap != null){
            bitmap.setPalette([trackColor, Graphics.COLOR_TRANSPARENT] as Array<ColorValue>);
        }
    }

    function onPosition(x as Float?, y as Float?, quality as Position.Quality) as Void{
        if(x != xCurrent || y != yCurrent){
            xCurrent = x;
            yCurrent = y;
            doUpdate = true;
        }
    }
}