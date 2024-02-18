import Toybox.Lang;
import Toybox.Graphics;
import MyBarrel.Layout;
import MyBarrel.Drawables;

class MyLabeledField extends MyDataField{
    hidden var label as MyText|Null;
    hidden var labelText as String;

    function initialize(options as {
        :locX as Numeric,
        :locY as Numeric,
        :width as Numeric,
        :height as Numeric,
        :darkMode as Boolean,
        :label as String,
    }){
        MyDataField.initialize(options);
        labelText = options.hasKey(:label) ? (options.get(:label) as String).toUpper() : "LABEL";
    }

    function onLayout(dc) as Void{
        MyDataField.onLayout(dc);

        // align label on top
        var helper = Layout.getLayoutHelper({
            :xMin => locX,
            :xMax => locX + width,
            :yMin => locY,
            :yMax => locY + height,
        });

        var ds = System.getDeviceSettings();
        if((1f * height / ds.screenHeight) <= 0.22){
            // no label (area to small)
            label = null;
        }else{
            var color = getForegroundColor();
            var label = new Drawables.MyText({
                :text => labelText,
                :color => color,
            });

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

            label.adaptSize(dc);
            helper.align(label, Layout.ALIGN_TOP);
            self.label = label;
        }
    }

    function onUpdate(dc) as Void{
        if(label != null){
            label.draw(dc);
        }
    }

    function setDarkMode(darkMode as Boolean) as Void{
        MyDataField.setDarkMode(darkMode);
        if(label != null){
            label.color = getForegroundColor();
        }
    }
}