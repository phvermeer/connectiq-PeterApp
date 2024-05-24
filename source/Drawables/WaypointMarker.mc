import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

(:track)
class WaypointMarker extends WatchUi.Drawable{
    const sqrt3 = 1.732050808f;
    var darkMode as Boolean;
    var size as Number;
    var type as Waypoint.Type = Waypoint.TYPE_DEFAULT;

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

    function draw(dc as Dc){
        if(type == Waypoint.TYPE_DEFAULT){
            drawDefault(dc, Graphics.COLOR_RED);
        }else{
            drawFlag(dc, Graphics.COLOR_BLUE);
        }
    }

    hidden function drawDefault(dc as Dc, color as ColorType) as Void{
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);

        var radius = 0.5f * size;
        var dx = radius * sqrt3/2;
        var dy2 = 0.75f * size;
        var dy = size;

        var pts = [
            [locX - dx, locY - dy2],
            [locX, locY],
            [locX + dx, locY - dy2],
            [locX, locY - radius],
        ] as Array<Point2D>;
        dc.fillPolygon(pts);

        var thickness = (0.4 * radius).toNumber();
        dc.setPenWidth(thickness);
        dc.drawCircle(locX, locY-dy, radius-thickness/2);
    }

    hidden function drawFlag(dc as Dc, color as ColorType) as Void{
        var h = 1.2 * size;
        
        // flag
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        var pts = [
            [locX, locY - h],
            [locX, locY - 0.4*h],
            [locX + size, locY - 0.8*h],
        ] as Array<Point2D>;
        dc.fillPolygon(pts);

        // pole
        dc.setColor(darkMode ? Graphics.COLOR_YELLOW: Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(size/5);
        dc.drawLine(locX, locY, locX, locY-h);
    }

/*
    public function drawCustom(dc as Dc, color as ColorType) as Void{
        var sqrt32 = 0.866025404f;


        dc.setColor(color, Graphics.COLOR_TRANSPARENT);

        var radius = 0.5f * size;
        var dx = radius * sqrt32;
        var dy2 = 0.75f * size;
        var dy = size;

        // bottom triangle
        var pts = [
            [locX - dx, locY - dy2],
            [locX, locY],
            [locX + dx, locY - dy2],
        ] as Array<Point2D>;
        dc.fillPolygon(pts);

        // top circle
        var y = locY-dy;
        dc.fillCircle(locX, y, radius);

        // draw inner sign
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        radius = 0.4 * size;
        dx = sqrt32 * radius;
        dy = radius / 2;
        pts = [
            [locX, y-radius],
            [locX - dx, y + dy],
            [locX + dx, y + dy],
        ] as Array<Point2D>;
        dc.fillPolygon(pts);
    }

    hidden function drawFinish(dc as Dc) as Void{
        var clWhite = Graphics.COLOR_WHITE;
        var clBlack = Graphics.COLOR_BLACK;
        var clStick = darkMode ? Graphics.COLOR_YELLOW : Graphics.COLOR_ORANGE;

        // draw black/white flag on brown stick

        // pole
        dc.setPenWidth(size/5);
        dc.setColor(clStick, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(locX, locY,  locX, locY - size);

        // flag
        dc.setColor(clWhite, clBlack);
        var x1 = locX;
        var y1 = locY-size/2;
        var x2 = locX + size;
        var y2 = locY-size;

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

*/
}