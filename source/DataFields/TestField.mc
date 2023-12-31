import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;
import MyTools;
import MyDrawables;

class TestField extends MyDataField{
    hidden var label as MyText;

    function initialize(options as {
        :locX as Numeric,
        :locY as Numeric,
        :width as Numeric,
        :height as Numeric,
    }) {
        MyDataField.initialize(options);

        label = new MyText({
            :text => "TEST",
            :color => getTextColor(),
        });
    }
    function onLayout(dc){

        // determine the font sizes
        var surface = width * height;
        var surfaceMax = dc.getWidth() * dc.getHeight();
        var ratio = surface / surfaceMax;
        if(ratio < 0.2){
            label.setFont(Graphics.FONT_XTINY);
        }else if(ratio < 0.4){
            label.setFont(Graphics.FONT_XTINY);
        }else if(ratio <= 0.5){
            label.setFont(Graphics.FONT_TINY);
        }else{
            label.setFont(Graphics.FONT_SMALL);
        }

        label.adaptSize(dc);
        label.locX = locX + (width-label.width)/2;
        label.locY = locY + (height-label.height)/2;
    }

    function onUpdate(dc){
        // label
        dc.drawRectangle(locX, locY, width, height);
        label.draw(dc);
    }

    function setBackgroundColor(color as ColorType) as Void{
        MyDataField.setBackgroundColor(color);
        label.setColor(getTextColor());
    }
    hidden function getTextColor() as ColorType{
        return darkMode ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
    }
}