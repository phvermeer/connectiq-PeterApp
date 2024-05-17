import Toybox.Lang;
import Toybox.Graphics;
import Toybox.System;
import Toybox.Math;

(:track)
class TrackDrawer{
    var darkMode as Boolean;
    var xOffset as Numeric;
    var yOffset as Numeric;
    var xMin as Numeric;
    var xMax as Numeric;
    var yMin as Numeric;
    var yMax as Numeric;
    var zoomFactor as Numeric;

    function initialize(
        options as {
            :xOffset as Numeric,
            :xMin as Numeric,
            :xMax as Numeric, 
            :yOffset as Numeric,
            :yMin as Numeric,
            :yMax as Numeric,
            :zoomFactor as Decimal,
        }
    ){
        var deviceSettings = System.getDeviceSettings();
        darkMode = options.hasKey(:darkMode) ? options.get(:darkMode) as Boolean: false; 
        xOffset = options.hasKey(:xOffset) ? options.get(:xOffset) as Numeric: 0;
        yOffset = options.hasKey(:yOffset) ? options.get(:yOffset) as Numeric: 0;
        xMin = options.hasKey(:xMin) ? options.get(:xMin) as Numeric: 0;
        xMax = options.hasKey(:xMax) ? options.get(:xMax) as Numeric: deviceSettings.screenWidth;
        yMin = options.hasKey(:yMin) ? options.get(:yMin) as Numeric: 0;
        yMax = options.hasKey(:yMax) ? options.get(:yMax) as Numeric: deviceSettings.screenHeight;
        zoomFactor = options.hasKey(:zoomFactor) ? options.get(:zoomFactor) as Numeric: 1f;
    }

    hidden static function getInterpolatedY(x1 as Numeric, y1 as Numeric, x2 as Numeric, y2 as Numeric, x as Numeric) as Numeric{
        if(x1 != x2){
            var rc = (y2-y1)/(x2-x1);
            return y1 + rc * (x-x1);
        }else{
            return (y1+y2)/2;
        }
    }
    hidden static function getInterpolatedX(x1 as Numeric, y1 as Numeric, x2 as Numeric, y2 as Numeric, y as Numeric) as Numeric{
        return getInterpolatedY(y1, x1, y2, x2, y);
    }

	static function getColorAhead(darkMode as Boolean) as ColorType{
		return Graphics.COLOR_PINK;
	}
	static function getColorBehind(darkMode as Boolean) as ColorType{
		return Graphics.COLOR_GREEN;
	}
	static function getColor(darkMode as Boolean) as ColorType{
		return darkMode ? Graphics.COLOR_DK_GRAY : Graphics.COLOR_LT_GRAY;
	}

    static function getTrackThickness(width as Numeric, height as Numeric, zoomFactor as Float) as Number{
        var size = (width < height) ? width : height;
        var trackThickness = 1;
        if(size > 0 && zoomFactor > 0){
            var ds = System.getDeviceSettings();
            var thicknessMax = (size > 10) ? size / 10 : 1;
            var thicknessMin = Math.ceil(0.01f * ds.screenWidth);

            var range = size / zoomFactor; // [m]
            // 0 → 50m:		 	maxPenWidth
            // 50m → 10km: 		scaled between maxPenWidth and minPenWidth
            // 10km → ∞:			minPenWidth
            var rangeMin = 50;
            var rangeMax = 10000;

            if(range <= rangeMin){
                trackThickness = thicknessMax.toNumber();
            } else if(range >= rangeMax){
                trackThickness = thicknessMin.toNumber();
            }else{
                // The penWidth between rangeMin and rangeMax:
                var rangeFactor = rangeMax / rangeMin;  
                var thicknessFactor = thicknessMax / thicknessMin;
                // use the log value to convert range to penWidth
                var log = Math.log(thicknessFactor, rangeFactor); 

                // the scaling from range between rangemin and rangeMax will result in 
                // the equalvalent of the penWIdth between penWidthMax end penWIdthMin using a logaritmic correction
                trackThickness = Math.round(thicknessMax / Math.pow(range/rangeMin, log)).toNumber();			
            }
        }
        return trackThickness;            
    }

    function drawLines(dc as Dc, pts as Array<XY|Null>) as Void{
        var count = pts.size();
        if(count > 1){
            // first point
            var i;
            var pt1 = null;
            for(i=0; i<count; i++){
                pt1 = pts[i];
                if(pt1 != null){
                    break;
                }
            }                
            if(pt1 != null){
                var x1 = xOffset + zoomFactor * pt1[0];
                var y1 = yOffset + zoomFactor * pt1[1];
                var x1_ok = (x1 > xMin && x1 < xMax);
                var y1_ok = (y1 > yMin && y1 < yMax);

                for(i++; i<count; i++){
                    var pt2 = pts[i];
                    if(pt2 != null){

                        var x2 = xOffset + zoomFactor * pt2[0];
                        var y2 = yOffset + zoomFactor * pt2[1];
                        var x2_ok = (x2 > xMin && x2 < xMax);
                        var y2_ok = (y2 > yMin && y2 < yMax);

                        if(x1_ok || x2_ok){
                            if(!x1_ok){
                                // interpolate x1
                                if(x1 < xMin && x2 > xMin){
                                    y1 = getInterpolatedY(x1, y1, x2, y2, xMin);
                                    x1 = xMin;
                                }else if(x1 > xMax && x2 < xMax){
                                    y1 = getInterpolatedY(x1, y1, x2, y2, xMax);                        
                                    x1 = xMax;
                                }
                            }else if(!x2_ok){
                                // interpolate x2
                                if(x2 < xMin && x1 > xMin){
                                    y2 = getInterpolatedY(x1, y1, x2, y2, xMin);
                                    x2 = xMin;
                                }else if(x2 > xMax && x1 < xMax){
                                    y2 = getInterpolatedY(x1, y1, x2, y2, xMax);                        
                                    x2 = xMax;
                                }
                            }

                            if(y1_ok || y2_ok){
                                if(!y1_ok){
                                    // interpolate y1
                                    if(y1 < yMin && y2 > yMin){
                                        x1 = getInterpolatedX(x1, y1, x2, y2, yMin);
                                        y1 = yMin;
                                    }else if(y1 > yMax && y2 < yMax){
                                        x1 = getInterpolatedX(x1, y1, x2, y2, yMax);
                                        y1 = yMax;
                                    }
                                }else if(!y2_ok){
                                    // interpolate y2
                                    if(y2 < yMin && y1 > yMin){
                                        x2 = getInterpolatedX(x1, y1, x2, y2, yMin);
                                        y2 = yMin;
                                    }else if(x2 > xMax && x1 < xMax){
                                        x2 = getInterpolatedX(x1, y1, x2, y2, yMax);                        
                                        y2 = yMax;
                                    }
                                }

                                // draw
                                dc.drawLine(x1, y1, x2, y2);
                            }
                        }

                        x1 = x2;
                        y1 = y2;
                        x1_ok = x2_ok;
                        y1_ok = y2_ok;
                    }
                }
            }
        }
    }

    function drawWaypoints(dc as Dc, waypoints as Array<Waypoint>, size as Number) as Void{
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        var marker = new WaypointMarker({
            :size => size,
        });
/*
        var marker = new FinishMarker({
            :size => size,
            :darkMode => darkMode,
        });
*/
/*
        dc.setColor((darkMode ? Graphics.COLOR_LT_GRAY : Graphics.COLOR_DK_GRAY), Graphics.COLOR_TRANSPARENT);
        var marker = new PeakMarker({
            :size => size,
        });
*/
        for(var i=0; i<waypoints.size(); i++){
            var wp = waypoints[i];
            marker.locX = xOffset + zoomFactor * wp.xy[0];
            marker.locY = yOffset + zoomFactor * wp.xy[1];
            marker.draw(dc);
        }
    }
}
