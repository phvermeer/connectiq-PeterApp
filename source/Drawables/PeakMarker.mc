import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

(:track)
class PeakMarker extends WatchUi.Drawable{
    var size as Number;
    var color as ColorType|Null;

    public function initialize(options as {
        :locX as Number, 
        :locY as Number,
        :size as Number,
        :color as ColorType,
    }){
        Drawable.initialize(options);
        color = options.get(:color) as ColorType|Null;
        size = options.hasKey(:size) ? options.get(:size) as Number : 10;
    }

    public function draw(dc as Dc){
        // Draw a cross
        var w = size;
        var h = 1.5 * w;
        var x = Math.round(locX);
        var y = Math.round(locY);
        var thickness = Math.ceil(size / 5);

        if(color != null){
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        }
        dc.setPenWidth(thickness);

        // horizontal bar
        var y_ = y - h * 2/3;
        dc.drawLine(x, y_, x+w, y_);

        // vertical bar
        var x_ = x + w / 2;
        dc.drawLine(x_, y, x_, y-h);

    }
}