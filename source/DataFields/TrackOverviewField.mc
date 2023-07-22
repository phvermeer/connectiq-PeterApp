import Toybox.Lang;
import Toybox.Graphics;
import Toybox.Position;

class TrackOverviewField extends MyDataField{
    hidden var track as Track?;
    hidden var bitmap as BufferedBitmap?;
    hidden var xBitmap as Number = 0;
    hidden var yBitmap as Number = 0;
    hidden var xCenter as Numeric = 0;
    hidden var yCenter as Numeric = 0;

    hidden var zoomFactor as Float = 0.1f;
    hidden var markerSize as Number = 0;
    hidden var darkMode as Boolean = false;
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
        // show bitmap
        dc.setColor(Graphics.COLOR_TRANSPARENT, backgroundColor);
        dc.clear();

        // draw markers
        if(track != null && bitmap != null){
            var track = self.track as Track;
            var bitmap = self.bitmap as BufferedBitmap;

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

            // Draw the track
            dc.drawBitmap(xBitmap as Numeric, yBitmap as Numeric, bitmap);
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
        xBitmap = (dummy.locX - margin).toNumber();
        yBitmap = (dummy.locY - margin).toNumber();
        xCenter = dummy.locX + dummy.width/2;
        yCenter = dummy.locY + dummy.height/2;

        // create the bitmap
        var color = getTrackColor();
        var colorPalette = [color, Graphics.COLOR_TRANSPARENT] as Array<ColorValue>;
        var bitmap = new Graphics.BufferedBitmap({
            :width => (dummy.width + 2 * margin).toNumber(),
            :height => (dummy.height + 2 * margin).toNumber(),
            :palette => colorPalette,
        });
        self.bitmap = bitmap;
        xBitmap = dummy.locX.toNumber();
        yBitmap = dummy.locY.toNumber();
        xCenter = (xBitmap + dummy.width/2).toNumber();
        yCenter = (yBitmap + dummy.height/2).toNumber();

        // draw the track
        var dc = bitmap.getDc();
        var xOffset = xCenter - xBitmap;
        var yOffset = yCenter - yBitmap;

        if(dc != null){
            var factorHor = dummy.width.toFloat() / (track.xMax - track.xMin);
            var factorVert = dummy.height.toFloat() / (track.yMax - track.yMin);
            zoomFactor = (factorHor + factorVert) / 2;

            var count = track.count;

            dc.setColor(colorPalette[0], colorPalette[1]);
            dc.clear();
            var penWidth = getTrackThickness(zoomFactor);
            dc.setPenWidth(penWidth);

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

    function updateTrack() as Void{
        var track = $.getApp().track;
        setTrack(track);
    }

    function setTrack(track as Track?) as Void{
        self.track = track;
        if(track != null){
            // create new bitmap
            updateBitmap(track);
        }else{
            bitmap = null;
        }
        doUpdate = true;
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
        var rgb = MyTools.colorToRGB(backgroundColor);
        var intensity = Math.mean(rgb);
        darkMode = (intensity < 100);

        // update color palette of bitmap
        var trackColor = getTrackColor();
        if(bitmap != null){
            bitmap.setPalette([trackColor, Graphics.COLOR_TRANSPARENT] as Array<ColorValue>);
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