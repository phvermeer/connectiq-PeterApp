import Toybox.Lang;
import Toybox.Graphics;

(:noTrack)
module TrackDrawing{
    
}

(:track)
module TrackDrawing{
    function getInterpolatedY(x1 as Numeric, y1 as Numeric, x2 as Numeric, y2 as Numeric, x as Numeric) as Numeric{
        if(x1 != x2){
            var rc = (y2-y1)/(x2-x1);
            return y1 + rc * (x-x1);
        }else{
            return (y1+y2)/2;
        }
    }
    function getInterpolatedX(x1 as Numeric, y1 as Numeric, x2 as Numeric, y2 as Numeric, y as Numeric) as Numeric{
        return getInterpolatedY(y1, x1, y2, x2, y);
    }


    function drawPoints(
        dc as Dc, 
        pts as Array<XY|Null>, 
        options as {
            :xOffset as Numeric,
            :xMin as Numeric,
            :xMax as Numeric, 
            :yOffset as Numeric,
            :yMin as Numeric,
            :yMax as Numeric,
            :zoomFactor as Decimal,
        }
    ) as Void{
        var count = pts.size();
        if(count > 1){
            var xOffset = options.hasKey(:xOffset) ? options.get(:xOffset) as Numeric: 0;
            var yOffset = options.hasKey(:yOffset) ? options.get(:yOffset) as Numeric: 0;
            var xMin = options.hasKey(:xMin) ? options.get(:xMin) as Numeric: 0;
            var xMax = options.hasKey(:xMax) ? options.get(:xMax) as Numeric: dc.getWidth();
            var yMin = options.hasKey(:yMin) ? options.get(:yMin) as Numeric: 0;
            var yMax = options.hasKey(:yMax) ? options.get(:yMax) as Numeric: dc.getHeight();
            var zoomFactor = options.hasKey(:zoomFactor) ? options.get(:zoomFactor) as Numeric: 1f;

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
}