import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class WaypointMarker extends WatchUi.Drawable{
    var color as Graphics.ColorType;

    public function initialize(options as {
        :identifier as String,
        :locX as Number, 
        :locY as Number,
        :width as Number, 
        :height as Number,
        :color as Graphics.ColorType,
    }){
        Drawable.initialize(options);
        color = options.hasKey(:color) ? options.get(:color) as Graphics.ColorType : Graphics.COLOR_RED;
    }

    function draw(dc as Dc){
        var radius = 0.5f * width;
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(locX, locY, radius);
    }
}