import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;

class MyDataField extends WatchUi.Drawable{
    hidden var upToDate as Boolean = false;
    hidden var backgroundColor as ColorType;

    function initialize(options as {
        :locX as Numeric,
        :locY as Numeric,
        :width as Numeric,
        :height as Numeric,
        :backgroundColor as ColorType,
    }){
        Drawable.initialize(options);
        var color = options.get(:backgroundColor);
        backgroundColor = (color != null) ? color : Graphics.COLOR_WHITE;
    }

    function draw(dc as Dc) as Void{
        dc.setColor(backgroundColor, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(locX, locY, width, height);
        upToDate = true;

        // override this function
    }

    function setLocation(x, y){
        Drawable.setLocation(x, y);
        upToDate = false;
    }
    function setSize(w, h){
        Drawable.setSize(w, h);
        upToDate = false;
    }

    // this function will indicate if the value is changed since last onUpdate()
    function isUpToDate() as Boolean{
        return upToDate;
    }

    function setBackgroundColor(color as Graphics.ColorType) as Void{
        backgroundColor = color;
        upToDate = false;
    }
}