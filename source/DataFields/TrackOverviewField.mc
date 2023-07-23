import Toybox.Lang;
import Toybox.Graphics;
import Toybox.Position;

class TrackOverviewField extends MyDataField{
    hidden var track as Track?;
    hidden var bitmap as BufferedBitmap?;
    hidden var xBitmap as Number = 0;
    hidden var yBitmap as Number = 0;
    hidden var wBitmap as Number = 0;
    hidden var hBitmap as Number = 0;
    hidden var xCenter as Numeric = 0;
    hidden var yCenter as Numeric = 0;

    hidden var zoomFactor as Float = 0.1f;
    hidden var markerSize as Number = 0;
    hidden var xCurrent as Float?;
    hidden var yCurrent as Float?;

    function initialize(options as {
        :track as Track
    }){
        MyDataField.initialize(options);
        track = options.get(:track);

        if(track != null){
            xCurrent = track.xCurrent;
            yCurrent = track.yCurrent;
        }

        // update darkmode
        setBackgroundColor(backgroundColor);
    }

    function onLayout(dc as Dc){
        // determine marker size
        var deviceSettings = System.getDeviceSettings();
        var screenSize = (deviceSettings.screenWidth > deviceSettings.screenHeight) ? deviceSettings.screenHeight : deviceSettings.screenWidth;
        var fieldSize = (width > height) ? height : width;
        markerSize = MyMath.max([screenSize/40, fieldSize/20] as Array<Numeric>).toNumber();

        // create bitmap
        if(track != null){
            // the following vars will be updated in initBitmap
            //  - bitmap
            //  - xBitmap
            //  - yBitmap
            updateBitmap(track);
        }
    }

    function onUpdate(dc as Dc){
        if(track != null && bitmap != null){
            var track = self.track as Track;
            var bitmap = self.bitmap as BufferedBitmap;

            // Draw the track
            dc.drawBitmap(xBitmap as Numeric, yBitmap as Numeric, bitmap);

            // Draw the finish marker
            var i = track.count-1;
            if(i>0){
                var x = xCenter + zoomFactor * track.xValues[i];
                var y = yCenter + zoomFactor * track.yValues[i];
                var color = darkMode ? Graphics.COLOR_GREEN : Graphics.COLOR_DK_GREEN;
                dc.setColor(color, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(x, y, markerSize);
            }

            // Draw current position marker
            if(xCurrent != null && yCurrent != null){
                var x = xCenter + zoomFactor * xCurrent;
                var y = yCenter + zoomFactor * yCurrent;
                var color = darkMode ? Graphics.COLOR_BLUE : Graphics.COLOR_BLUE;
                dc.setColor(color, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(x as Float, y as Float, markerSize);
            }
        }
    }
    hidden function updateBitmap(track as Track) as Void{
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

        var margin = markerSize;
        helper.resizeToMax(dummy, false, margin);
        xBitmap = dummy.locX.toNumber() - margin;
        yBitmap = dummy.locY.toNumber() - margin;
        wBitmap = dummy.width.toNumber() + 2 * margin;
        hBitmap = dummy.height.toNumber() + 2 * margin;
        xCenter = xBitmap + wBitmap/2;
        yCenter = yBitmap + hBitmap/2;

        // create the bitmap
        var trackColor = getTrackColor();
        var colorPalette = [trackColor, backgroundColor] as Array<ColorValue>;
        var bitmap = new Graphics.BufferedBitmap({
            :width => wBitmap,
            :height => hBitmap,
            :palette => colorPalette,
        });
        self.bitmap = bitmap;

        // calculate the zoom factor to show the whole track
        var factorHor = (wBitmap-2*margin) / (track.xMax - track.xMin);
        var factorVert = (hBitmap-2*margin) / (track.yMax - track.yMin);
        zoomFactor = factorHor < factorVert ? factorHor : factorVert;

        // draw the track
        var dc = bitmap.getDc();

        if(dc != null){

            var xOffset = xCenter - xBitmap;
            var yOffset = yCenter - yBitmap;

            var count = track.count;

            var penWidth = getTrackThickness(zoomFactor);
            dc.setPenWidth(penWidth);
            dc.setColor(trackColor, backgroundColor);
            dc.clear();

            var x1 = xOffset + zoomFactor * track.xValues[0];
            var y1 = yOffset + zoomFactor * track.yValues[0];
            for(var i=1; i<count; i++){
                var x2 = xOffset + zoomFactor * track.xValues[i];
                var y2 = yOffset + zoomFactor * track.yValues[i];

                dc.drawLine(x1, y1, x2, y2);

                x1 = x2;
                y1 = y2;
            }
        }
    }

    function onSetting(id, value){
        MyDataField.onSetting(id, value);
        if(id == SETTING_TRACK){
            // update the track
            track = $.getApp().track;
            if(track != null){
                // create new bitmap
                updateBitmap(track);
            }else{
                bitmap = null;
            }
            doUpdate = true;
        }
    }

    hidden function getTrackColor() as ColorType{
        return darkMode ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
    }

    hidden function getTrackThickness(zoomFactor as Float) as Number{
		var size = (width < height) ? width : height;
        var trackThickness = 1;
		if(size > 0 && zoomFactor > 0){
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

        // update track bitmap with updated colors
        var track = $.getApp().track;
        if(track != null && bitmap != null){
            updateBitmap(track);
        }
    }

    function onPosition(x as Float?, y as Float?, heading as Float?, quality as Position.Quality) as Void{
        if(x != xCurrent || y != yCurrent){
            xCurrent = x;
            yCurrent = y;
            doUpdate = true;
        }
    }
}