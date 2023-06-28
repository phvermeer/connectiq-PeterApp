import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;

class MyDataField extends WatchUi.Drawable{
    function initialize(settings as {
        :locX as Numeric,
        :locY as Numeric,
        :width as Numeric,
        :height as Numeric,
    }){
        Drawable.initialize(settings);
    }

    function draw(dc as Dc){
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(locX, locY, width, height);
    }
}