import Toybox.Lang;
import Toybox.Graphics;

class TrackOverviewField extends MyDataField{
    var bitmap as BufferedBitmap?;

    function initialize(options as {
        :track as Track
    }){
        MyDataField.initialize(options);
    }

    function onLayout(dc as Dc){
        // create the bitmap
        bitmap = new Graphics.BufferedBitmap({
            :width => width.toNumber(),
            :height => height.toNumber(),
            :palette => [Graphics.COLOR_PINK, Graphics.COLOR_WHITE] as Array<ColorValue>,
        });

        // draw the bitmap
        var dc_ = bitmap.getDc();
        dc_.clear();
        dc_.fillRectangle(0, 0, width, height);
    }

    function onUpdate(dc as Dc){
        // show bitmap
        if(bitmap != null){
            dc.drawBitmap(locX, locY, bitmap);
        }
    }
}