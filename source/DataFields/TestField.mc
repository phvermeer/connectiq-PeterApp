import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;

class TestField extends MyDataField{
    static hidden var counter as Number = 0;
    static hidden var hours as Number;
    static hidden var minutes as Number;
    static hidden var seconds as Number;

    function initialize(settings as {
        :locX as Numeric,
        :locY as Numeric,
        :width as Numeric,
        :height as Numeric,
    }) {
        MyDataField.initialize(settings);
        var info = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        hours = info.hour;
        minutes = info.min;
        seconds = 5 * (info.sec /5);
    }

    function draw(dc as Dc){
        MyDataField.draw(dc);
        counter++;
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(locX+width/2, locY+height/2, Graphics.FONT_MEDIUM, Lang.format("$1$:$2$:$3$", [hours.format("%02u"), minutes.format("%02u"), seconds.format("%02u")]), Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function onTimer() as Void{
        var info = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var hoursNew = info.hour;
        var minutesNew = info.min;
        var secondsNew = 5*(info.sec/5);
        if(hoursNew != hours || minutesNew != minutes || secondsNew != seconds){
            hours = hoursNew;
            minutes = minutesNew;
            seconds = secondsNew;
            upToDate = false;
        }
    }
}