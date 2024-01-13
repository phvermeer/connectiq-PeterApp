import Toybox.Lang;
import Toybox.Graphics;
import MyLayout;
import MyDrawables;

class MyLabeledField extends MyDataField{
    hidden var label as MyText;


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
    }

    function onLayout(dc) as Void{
        MyDataField.onLayout(dc);

        // align label on top
        var helper = MyLayout.getLayoutHelper({
            :xMin => locX,
            :xMax => locX + width,
            :yMin => locY,
            :yMax => locY + height,
        });

        var ds = System.getDeviceSettings();
        if((1f * height / ds.screenHeight) <= 0.22){
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
        }else if(ratio < 0.4){
            label.setFont(Graphics.FONT_XTINY);
        }else if(ratio <= 0.5){
            label.setFont(Graphics.FONT_TINY);
        }else{
            label.setFont(Graphics.FONT_SMALL);
        }

        if(label.isVisible){
            label.adaptSize(dc);
            helper.align(label, MyLayout.ALIGN_TOP);
        }
    }

    function onUpdate(dc) as Void{
        label.draw(dc);
    }

    function setDarkMode(darkMode as Boolean) as Void{
        MyDataField.setDarkMode(darkMode);
        var color = getForegroundColor();
        label.color = color;
    }
}