import Toybox.Lang;
import Toybox.Graphics;
import MyDrawables;
import MyLayoutHelper;

class EmptyField extends MyDataField{
    const COUNTER = 2;
    var counter as Number = 0;

    function initialize(options as {
        :locX as Numeric,
        :locY as Numeric,
        :width as Numeric,
        :height as Numeric,
        :backgroundColor as ColorType,
    }){
        MyDataField.initialize(options);
    }

    function onShow(){
        MyDataField.onShow();
        counter = COUNTER;
    }
    function onUpdate(dc as Dc){
        if(counter > 0){
            var color = darkMode ? Graphics.COLOR_DK_GRAY : Graphics.COLOR_LT_GRAY;
            dc.setPenWidth(1);
            dc.setColor(color, backgroundColor);
            dc.drawRectangle(locX, locY, width, height);
            counter--;
        }

    }
}