import Toybox.Lang;
import Toybox.Graphics;
import MyBarrel.Drawables;
import MyBarrel.Layout;
import Toybox.Activity;

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

    function onActivityInfo(sender as Object, info as Activity.Info) as Void{
        if(counter > 0){
            counter--;
            if(counter==0){
                refresh();
            }
        }
    }
    function onUpdate(dc as Dc){
        if(counter > 0){
            dc.setPenWidth(1);
            dc.setColor(getForegroundColor(), getBackgroundColor());
            dc.drawRectangle(locX, locY, width, height);
        }
    }
}