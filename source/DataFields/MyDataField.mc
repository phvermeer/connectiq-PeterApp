import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;

class MyDataField extends WatchUi.Drawable{
    hidden var upToDate as Boolean = false;
    hidden var bgColor as ColorType;

    function initialize(settings as {
        :locX as Numeric,
        :locY as Numeric,
        :width as Numeric,
        :height as Numeric,
        :backgroundColor as ColorType,
    }){
        Drawable.initialize(settings);
        var color = settings.get(:backgroundColor);
        bgColor = (color != null) ? color : Graphics.COLOR_WHITE;
    }

    function draw(dc as Dc) as Void{
        dc.setColor(bgColor, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(locX, locY, width, height);
        upToDate = true;

        // override this function
    }

    // this function will indicate if the value is changed since last onUpdate()
    function isUpToDate() as Boolean{
        return upToDate;
    }

    function setBackground(color as Graphics.ColorType) as Void{
        bgColor = color;
    }
}