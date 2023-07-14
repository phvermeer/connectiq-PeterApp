import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;
import MyTools;
import MyDrawables;

class TestField extends MyDataField{
    hidden var foregroundColor as ColorType;
    hidden var label as MyText;
    hidden var value as MyText;
    hidden var visible as Boolean = false;    

    function initialize(options as {
        :locX as Numeric,
        :locY as Numeric,
        :width as Numeric,
        :height as Numeric,
    }) {
        MyDataField.initialize(options);
        foregroundColor = getForegroundColor(backgroundColor);

        label = new MyText({
            :text => "TEST",
        });
        value = new MyText({
            :text => "---",
        });
    }
    function onLayout(dc){
        //if(locY > 50 && locY < 130 && locX == 0){
            visible = true;
        //}else{
        //    visible = false;
        //    return;
        //}

        var helper = new MyLayoutHelper.RoundScreenHelper({
            :xMin => locX,
            :xMax => locX + width,
            :yMin => locY,
            :yMax => locY + height
        });

        // determine the font sizes
        var surface = width * height;
        var surfaceMax = dc.getWidth() * dc.getHeight();
        var ratio = surface / surfaceMax;
        if(ratio < 0.2){
            label.setFont(Graphics.FONT_XTINY);
            value.setFont(Graphics.FONT_NUMBER_MILD);
        }else if(ratio < 0.4){
            label.setFont(Graphics.FONT_XTINY);
            value.setFont(Graphics.FONT_NUMBER_MILD);
        }else if(ratio <= 0.5){
            label.setFont(Graphics.FONT_TINY);
            value.setFont(Graphics.FONT_NUMBER_HOT);
        }else{
            label.setFont(Graphics.FONT_SMALL);
            value.setFont(Graphics.FONT_NUMBER_THAI_HOT);
        }


        label.updateDimensions(dc);
        helper.align(label, MyLayoutHelper.ALIGN_TOP);

        value.updateDimensions(dc);
        value.setLocation(locX + (width-value.width)/2, locY + (height-value.height)/2);

    }

    function onUpdate(dc){
        MyDataField.onUpdate(dc);

        dc.setColor(foregroundColor, backgroundColor);
        if(visible){
            // label
            dc.drawRectangle(label.locX, label.locY, label.width, label.height);
            label.draw(dc);

            // value
            dc.drawRectangle(value.locX, value.locY, value.width, value.height);
            value.draw(dc);
        }
    }

    function setBackgroundColor(color as ColorType) as Void{
        MyDataField.setBackgroundColor(color);
        foregroundColor = getForegroundColor(color);
    }
    hidden function getForegroundColor(backgroundColor as ColorType) as ColorType{
        var rgb = MyTools.colorToRGB(backgroundColor);
        var intensity = Math.mean(rgb);
        return (intensity > 100) ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE;
    }

    function onTimer() as Void{
        var info = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var hours = info.hour;
        var minutes = info.min;
        var seconds = 10*(info.sec/10);
        var valueNew = Lang.format("$1$:$2$:$3$", [hours.format("%02u"), minutes.format("%02u"), seconds.format("%02u")]);
        if(!valueNew.equals(value.getText())){
            value.setText(valueNew);
            upToDate = false;
        }
    }
}