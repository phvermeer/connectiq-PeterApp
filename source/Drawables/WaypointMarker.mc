import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

(:track)
class WaypointMarker extends WatchUi.Drawable{
    const sqrt3 = 1.732050808f;
    var color as ColorType|Null;
    var size as Number;

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

    function draw(dc as Dc){
        if(color != null){
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        }

        var radius = 0.5f * size;
        var dx = radius * sqrt3/2;
        var dy2 = 0.75f * size;
        var dy = size;

        var pts = [
            [locX - dx, locY - dy2],
            [locX, locY],
            [locX + dx, locY - dy2],
            [locX, locY - radius],
        ] as Array<Point2D>;
        dc.fillPolygon(pts);

        var thickness = (0.4 * radius).toNumber();
        dc.setPenWidth(thickness);
        dc.drawCircle(locX, locY-dy, radius-thickness/2);
    }
}