import Toybox.Lang;
import Toybox.Graphics;
import Toybox.Math;
import MyLayout;
import MyDrawables;

class MySimpleDataField extends MyDataField{
    hidden var label as MyText;
    hidden var value as MyText;

    function initialize(options as {
        :locX as Numeric,
        :locY as Numeric,
        :width as Numeric,
        :height as Numeric,
        :backgroundColor as ColorType,
        :label as String,
    }){
        MyDataField.initialize(options);
        var lbl = options.hasKey(:label) ? (options.get(:label) as String).toUpper() : "LABEL";

        var color = getForegroundColor();
        label = new MyDrawables.MyText({
            :text => lbl,
            :color => color,
        });
        value = new MyDrawables.MyText({
            :text => "---",
            :color => color,
        });
    }

    function onLayout(dc) as Void{
        // align label on top
        var helper = MyLayout.getLayoutHelper({
            :xMin => locX,
            :xMax => locX + width,
            :yMin => locY,
            :yMax => locY + height,
        });

        var ds = System.getDeviceSettings();
        if((1f * height / ds.screenHeight) < 0.22){
            label.setVisible(false);
        }else{
            label.setVisible(true);
        }

        // determine the font sizes
        var surface = width * height;
        var surfaceMax = ds.screenWidth * ds.screenHeight;
        var ratio = 1f * surface / surfaceMax;
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

        if(label.isVisible){
            label.adaptSize(dc);
            helper.align(label, MyLayout.ALIGN_TOP);

            // align value centered in the remaining area
            helper.setLimits(locX, locX + width, label.locY + label.height, locY + height, 0);
        }

        // update the aspect ratio of current value text
        value.adaptSize(dc);
        helper.resizeToMax(value, true);
        value.adaptFont(dc, true);
    }

    function onUpdate(dc){
        // label
        label.draw(dc);
        value.draw(dc);
    }    

    function setDarkMode(darkMode as Boolean) as Void{
        MyDataField.setDarkMode(darkMode);
        var color = getForegroundColor();
        label.setColor(color);
        value.setColor(color);
    }

    function setValue(value as Numeric|String|Null) as Void{
        var txt = (value instanceof Float || value instanceof Double)
            ? value == 0f
                ? "0.00"
                : value < 100
                    ? value.format("%.2f")
                    : value < 1000
                        ? value.format("%.1f")
                        : value < 10000
                            ? value.format("%i")
                            : value.format("%.2e")
            : (value instanceof Number || value instanceof Long)
                ? value.format("%i")
                : (value instanceof String)
                    ? value
                    : "---";
        if(!txt.equals(self.value.getText())){
            self.value.setText(txt);
            refresh();
        }
    }
}