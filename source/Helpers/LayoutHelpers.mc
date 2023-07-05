import Toybox.Lang;
import Toybox.Graphics;
import Toybox.System;

typedef IDrawable as interface{
    var locX as Numeric;
    var locY as Numeric;
    var width as Numeric;
    var height as Numeric;
};

enum Alignment{
    ALIGN_TOP = 1,
    ALIGN_RIGHT = 2,
    ALIGN_BOTTOM = 4,
    ALIGN_LEFT = 8,
}

class RoundScreenHelper{

    // internal definitions
    hidden enum Quadrant{
        QUADRANT_TOP_RIGHT = 1,
        QUADRANT_TOP_LEFT = 2,
        QUADRANT_BOTTOM_LEFT = 4,
        QUADRANT_BOTTOM_RIGHT = 8,
    }

    // compact area data
    typedef Area as Array<Numeric>; // [minX, maxX, minY, maxY];

    // protected vars
    hidden var limits as Area;
    hidden var r as Number;


    function initialize(options as {
        :xMin as Numeric,
        :xMax as Numeric,
        :yMin as Numeric,
        :yMax as Numeric,
    }){
        var ds = System.getDeviceSettings();
        var w = ds.screenWidth;
        var h = ds.screenHeight;
        if(w != h){
            throw new MyTools.MyException("Screenshape is not supported");
        }
        var dia = w;
        r = dia/2;

        var xMin = (options.hasKey(:xMin) ? options.get(:xMin) as Numeric : 0).toFloat();
        var xMax = (options.hasKey(:xMax) ? options.get(:xMax) as Numeric : dia).toFloat();
        var yMin = (options.hasKey(:yMin) ? options.get(:yMin) as Numeric : 0).toFloat();
        var yMax = (options.hasKey(:yMax) ? options.get(:yMax) as Numeric : dia).toFloat();
        limits = [xMin, xMax, yMin, yMax] as Area;
    }

    function align(object as IDrawable, alignment as Alignment|Number) as Void{
        // move object to outer limits in given align direction
        var obj = [object.locX, object.locX+object.width, object.locY, object.locY+object.height] as Area;

    	// remove opposite alignment values
        if(alignment & (ALIGN_TOP|ALIGN_BOTTOM) == (ALIGN_TOP|ALIGN_BOTTOM)){
            alignment &= ~(ALIGN_TOP|ALIGN_BOTTOM);
        }
        if(alignment & (ALIGN_LEFT|ALIGN_RIGHT) == (ALIGN_LEFT|ALIGN_RIGHT)){
            alignment &= ~(ALIGN_LEFT|ALIGN_RIGHT);
        }

        // calculate the following 2 variables to move the object
        var dx = 0;
        var dy = 0;

        // determine the align type (centered/horizontal/vertical/diagonal)
    	var alignType = MyMath.countBitsHigh(alignment as Number); // 0 => centered), 1 => straight, 2 => diagonal

        if(alignment < 0 || alignment > 15){
            throw new MyTools.MyException(Lang.format("Unsupported align direction $1$", [alignment]));
        }
        if(alignType == 0){
            // centered
            throw new MyTools.MyException("Centered alignment is not (yet) supported");
        }else if(alignType == 2){
            // diagonal
            throw new MyTools.MyException("Diagonal alignment is not (yet) supported");
        }else if(alignType == 1){
            // straight
            // transpose to TOP alignment
            var nrOfQuadrantsToRotate = (alignment == ALIGN_TOP)
                ? 0
                : (alignment == ALIGN_RIGHT)
                    ? 1
                    : (alignment == ALIGN_BOTTOM)
                        ? 2
                        : 3;
            var obj_ = rotateArea(obj, nrOfQuadrantsToRotate);
            var limits_ = rotateArea(limits, nrOfQuadrantsToRotate);

            // ********* Do the top alignment ***********
            // (x,y) with (0,0) at top left corner
            // now use (X,Y) with (0,0) at circle center
            var XminL = limits_[0] - r;
            var XmaxL = limits_[1] - r;
            var YminL = limits_[2] - r;
            var YmaxL = limits_[3] - r;
            var Xmin = obj_[0] - r;
            var Xmax = obj_[1] - r;
            var Ymin = obj_[2] - r;
            var Ymax = obj_[3] - r;

            // check if the width fits inside the boundaries
            if((Xmax - Xmin) > (XmaxL - XminL)){
                // exceeds boundaries
                throw new MyTools.MyException("shape cannot be aligned, shape outside limits");
            }
            // check space on top boundary within the circle
            //   Y² + X² = radius²
            //   X = ±√(radius² - Y²)
            //   Xmax = +√(radius² - Ymin²), Xmin = -√(radius² - Ymin²) 
            var r2 = r*r;
            var Xcircle = Math.sqrt(r2 - YminL*YminL);
            var XmaxCalc = (Xcircle < XmaxL) ? Xcircle : XmaxL;
            var XminCalc = (-Xcircle > XminL) ? -Xcircle : XminL;

            // check if the object fits against the top boundary
            var w = Xmax - Xmin;
            var h = Ymax - Ymin;
            if((XmaxCalc - XminCalc) >= w){
                XminCalc = 0.5 * (XminCalc + XmaxCalc - w);
                var YminCalc = YminL;
                dx = XminCalc - Xmin;
                dy = YminCalc - Ymin;
            }else{
                // move away from the border until the object fits
                // needs space on circle both left and right or only left or right
                var needsRight = false;
                var needsLeft = false;
                if(XminL > -w/2){
                    needsRight = true;
                }else if(XmaxL < w/2){
                    needsLeft = true;
                }else{
                    needsLeft = true;
                    needsRight = true;
                }
                var xNeeded = (needsLeft && needsRight) // x needed for each circle side
                    ? 0.5f * w
                    : needsLeft
                        ? w - XmaxL
                        : w + XminL;
                // y² + x² = radius²
                // y = ±√(radius² - x²)
                var YminCalc = - Math.sqrt(r2 - xNeeded*xNeeded);
                XminCalc = (XminL > -xNeeded) ? XminL : -xNeeded;
                dx = XminCalc - Xmin;
                dy = YminCalc - Ymin;
            }
            obj_[0] += dx;
            obj_[1] += dx;
            obj_[2] += dy;
            obj_[3] += dy;

            // transpose back to original orientation
            nrOfQuadrantsToRotate = 4 - nrOfQuadrantsToRotate;
            var obj_aligned = rotateArea(obj_, nrOfQuadrantsToRotate);

            // get the movement
            dx = obj_aligned[0] - obj[0];
            dy = obj_aligned[2] - obj[2];

        }

        object.locX += dx;
        object.locY += dy;
    }


    function resize(obj as IDrawable, ratio as Float) as Void{
        // resize object to fit within outer limits (ratio = obj.width/obj.height)
        

    }

    function getSurfaceArea()as Float{
        return (limits[1]-limits[0]) * (limits[3]-limits[2]);
    }

    // helper functions
    hidden function rotateArea(area as Area, nrOfQuadrants as Number) as Area{
        nrOfQuadrants %= 4;
        var dia = 2*r;
        if(nrOfQuadrants == 1){
            return [area[2], area[3], dia-area[1], dia-area[0]] as Area;
        }else if(nrOfQuadrants == 2){
            return [dia-area[1], dia-area[0], dia-area[3], dia-area[2]] as Area;
        }else if(nrOfQuadrants == 3){
            return [dia-area[3], dia-area[2], area[0], area[1]] as Area;
        }else{
            return [area[0], area[1], area[2], area[3]] as Area;
        }
    }
    hidden function flipArea(area as Area, horizontal as Boolean) as Area{
        var dia = 2*r;
        if(horizontal){
            return [dia-area[1], dia-area[0], area[2], area[3]] as Area;
        }else{
            return [area[0], area[1], dia-area[3], dia-area[2]] as Area;
        }
    }

    hidden function getPiePartsWithinBoundary(y as Number, r as Numeric) as Array< Array<Float|Boolean> >{
        //      rad:    angle (0 = →, 0.5∏ = ↑, ∏ = ←)
        //      y:      vertical distance from circle center
        //      r:      circle radius
        // calculate where the range of rad where the circle is below the y value
        //      rad = [0..∏]
        //      r * sin(rad) < y 

        // 

        if(y >= r){
            // no flattend edges
        }else if(y <= 0){
            // no round edges
        }else{
            // partly flattend

        }
        return [] as Array< Array<Float|Boolean> >;
    }
}