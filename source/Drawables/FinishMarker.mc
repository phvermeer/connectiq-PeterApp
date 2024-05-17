import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

(:track)
class FinishMarker extends WatchUi.Drawable{
    const sqrt3 = 1.732050808f;
    var size as Number;
    var darkMode as Boolean;

    public function initialize(options as {
        :locX as Number, 
        :locY as Number,
        :size as Number,
        :darkMode as Boolean,
    }){
        Drawable.initialize(options);
        darkMode = options.hasKey(:darkMode) ? options.get(:darkMode) as Boolean : false;
        size = options.hasKey(:size) ? options.get(:size) as Number : 10;
    }

    hidden function drawFlag(dc as Dc, x1 as Numeric, y1 as Numeric, x2 as Numeric, y2 as Numeric) as Void{
        // make sure x1 < x2 and y2 > y1
        var temp;
        if(x1 > x2){ temp = x1; x1 = x2; x2 = temp; }
        if(y1 > y2){ temp = y1; y1 = y2; y2 = temp; }

        // clear background
        dc.setClip(x1, y1, x2-x1, y2-y1);
        try{
            dc.clear();

            // draw flag with black/white blocks
            var colCount = 4;
            var rowCount = 3;
            var x = x1 + 1;
            var w = x2 - x1 - 2;
            var y = y1 + 1;
            var h = y2 - y1 - 2;

            var dx = w / colCount;
            var dy = h / rowCount;

            
            for(var r=0; r < rowCount; r++){
                for(var c=0; c < colCount; c++){
                    if((r+c) % 2 == 0){
                        // draw block
                        dc.fillRectangle(x + c*dx, y + r*dy, Math.round(dx), Math.round(dy));
                    }
                }
            }
        }finally{
            dc.clearClip();
        }
    }

    function draw(dc as Dc){
        var clWhite = Graphics.COLOR_WHITE;
        var clBlack = Graphics.COLOR_BLACK;
        var clStick = darkMode ? Graphics.COLOR_YELLOW : Graphics.COLOR_ORANGE;

        // draw black/white flag on brown stick

        // pole
        dc.setColor(clStick, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(locX, locY,  locX, locY - size);

        // flag
        dc.setColor(clWhite, clBlack);
        drawFlag(dc, locX, locY-size/2, locX + size, locY-size);



/*
        var pts = [
            [0.1*size + locX, locY - size],
            [0.05*size + locX, locY - 0.5 * size],
            [0.95*size + locX, locY - 0.5 * size],
            [size + locX, locY - size],
        ] as Array<Point2D>;
        dc.setColor(clBlack, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon(pts);
*/
/*
        var dx = size/3f;
        var dy = dx/2;

        var x0 = locX;
        var x1 = x0 + dx;
        var x2 = x1 + dx;
        var x3 = x2 + dx;

        var y0 = locY - size;
        var y1 = y0 + dy;
        var y2 = y1 + dy;
        var y3 = y2 + dy;

        dc.setPenWidth(1);
        dc.setColor(clWhite, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x0, y0, x3-x0, y3-y0);

        var pts = [
            [x0, y0],
            [x1, y0],
            [x1, y3],
            [x0, y3],
            [x0, y2],
            [x3, y2],
            [x3, y3],
            [x2, y3],
            [x2, y0],
            [x3, y0],
            [x3, y1],
            [x0, y1],
        ] as Array<Point2D>;
        dc.setColor(clBlack, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon(pts);
*/        
    }
}