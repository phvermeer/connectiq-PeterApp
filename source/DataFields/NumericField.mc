import Toybox.Lang;
import Toybox.Graphics;
import Toybox.Math;
import MyBarrel.Layout;
import MyBarrel.Drawables;

class NumericField extends MyLabeledField{
    hidden var value as MyText;
    hidden var rawValue as Numeric|String|Null;

    function initialize(options as {
        :locX as Numeric,
        :locY as Numeric,
        :width as Numeric,
        :height as Numeric,
        :darkMode as Boolean,
        :label as String,
    }){
        MyLabeledField.initialize(options);
        value = new Drawables.MyText({
            :text => "---",
            :color => getForegroundColor(),
        });
    }

    function onLayout(dc as Dc) as Void{
        MyLabeledField.onLayout(dc);

        // align label on top
        var helper = Layout.getLayoutHelper({
            :xMin => locX,
            :xMax => locX + width,
            :yMin => label != null ? label.locY + label.height : locY,
            :yMax => locY + height,
        });
        
        // align value centered in the remaining area
        value.setSize(3f, 1); // requested aspect ratio of value area
        helper.resizeToMax(value, true);
        value.adaptFontToHeight(dc, true);
    }

    function onUpdate(dc as Dc) as Void{
        MyLabeledField.onUpdate(dc);
        value.draw(dc);
    }    

    function setDarkMode(darkMode as Boolean) as Void{
        MyLabeledField.setDarkMode(darkMode);
        value.color = getForegroundColor();
    }

    function setValue(value as String|Numeric|Null) as Void{
        if(value != rawValue){
            if(value == null || !value.equals(rawValue)){
                rawValue = value;
                self.value.text = (value == null )
                    ? "---"
                    : (value instanceof Float || value instanceof Double)
                        ? formatDecimal(value, 2, 5)
                        : value.toString();
                refresh();
            }
        }
    }

    static function formatDecimal(value as Decimal, digits as Number, maxLength as Number) as String{
        // prevent "-" sign for 0f value
        if(value.toFloat() == 0f){
            value = 0;
        }

        // get number count in front of decimal separator
        var x = 1f;
        var count = 0;
        while(x <= value && count <= maxLength){
            count++;
            x *= 10;
        }

        if(count > maxLength){
            return value.format("%.1E");
        }else{
            var digitsMax = maxLength - count; // excluding decimal character
            var d = (digits > digitsMax) ? digitsMax : digits;
            if(d <= 0){
                return value.format("%i");
            }else{
                return value.format("%."+d.toNumber()+"f");
            }
        }
    }
}