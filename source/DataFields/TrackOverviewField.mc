import Toybox.Lang;
import Toybox.Graphics;

class TrackOverviewField extends MyDataField{
    var bitmap as BufferedBitmap?;
    var xBitmap as Numeric?;
    var yBitmap as Numeric?;
    var track as Track?;
    var zoomLevel as Float?;

    function initialize(options as {
        :track as Track
    }){
        MyDataField.initialize(options);
        track = options.get(:track);
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
        }

        // draw the bitmap
        if(track != null && bitmap != null){
            drawTrack(bitmap, track as Track);
        }
    }

    function onUpdate(dc as Dc){
        // show bitmap
        dc.setColor(Graphics.COLOR_TRANSPARENT, backgroundColor);
        dc.clear();

        if(bitmap != null){
            dc.drawBitmap(xBitmap as Numeric, yBitmap as Numeric, bitmap);
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
                drawTrack(bitmap, track);
            }else{
                bitmap.getDc().clear();
            }
        }
    }

    function drawTrack(bitmap as BufferedBitmap, track as Track) as Void{
        var dc = bitmap.getDc();
        if(dc != null){
            var w = dc.getWidth();
            var h = dc.getHeight();
            var colorPalette = bitmap.getPalette();
            dc.setColor(colorPalette[0], colorPalette[1]);
            dc.clear();

            var ratioHor = w / (track.xMax - track.xMin);
            var ratioVert = h / (track.yMax - track.yMin);
            var ratio = ratioHor<ratioVert ? ratioHor : ratioVert;
            var count = track.count;

            var x1 = ratio * track.xValues[0] + w/2;
            var y1 = ratio * track.yValues[0] + h/2;
            for(var i=1; i<count; i++){
                var x2 = ratio * track.xValues[i] + w/2;
                var y2 = ratio * track.yValues[i] + h/2;

                dc.drawLine(x1, y1, x2, y2);

                x1 = x2;
                y1 = y2;
            }
        }
    }

    function getTrackColor() as ColorType{
        var rgb = MyTools.colorToRGB(backgroundColor);
        var intensity = Math.mean(rgb);
        return (intensity > 100) ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE;
    }
    function setBackgroundColor(color as ColorType) as Void{
        MyDataField.setBackgroundColor(color);

        // update color palette of bitmap
        var trackColor = getTrackColor();
        if(bitmap != null){
            bitmap.setPalette([trackColor, Graphics.COLOR_TRANSPARENT] as Array<ColorValue>);
        }
    }
}