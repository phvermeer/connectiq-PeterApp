import Toybox.Lang;
import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Activity;
import Toybox.Application;
import MyBarrel.Layout;
import MyBarrel.Math2;

(:track)
class TrackField extends MyDataField{
    hidden var trackManager as TrackManager;
    hidden var xyCurrent as Array<Float>|Null;
    hidden var legend as TrackScaleLegend;
    hidden var positionMarker as TrackPositionMarker;
    hidden var zoomFactor as Float;
    hidden var trackThickness as Number = 1;
    hidden var markerSize as Number = 3;

    function initialize(options as {
        :xyCurrent as Array<Float>,
    }){
        MyDataField.initialize(options);
        var app = $.getApp();
        trackManager = app.trackManager;
        xyCurrent = trackManager.xy;
        zoomFactor = app.settings.get(Settings.ID_ZOOMFACTOR) as Float;

        legend = new TrackScaleLegend({
            :zoomFactor => zoomFactor,
            :font => Graphics.FONT_XTINY,
        });
        positionMarker = new TrackPositionMarker({
            :darkMode => darkMode,
        });
    }

    function onLayout(dc as Dc){
        trackThickness = TrackDrawer.getTrackThickness(width, height, zoomFactor);
        legend.updateSize(dc);
        
        // determine marker size
        var deviceSettings = System.getDeviceSettings();
        var screenSize = (deviceSettings.screenWidth > deviceSettings.screenHeight) ? deviceSettings.screenHeight : deviceSettings.screenWidth;
        var fieldSize = (width > height) ? height : width;
        markerSize = Math2.max([screenSize/40, fieldSize/20] as Array<Numeric>).toNumber();


        // determine the drawing area's
        var helper = Layout.getLayoutHelper({
            :xMin => locX,
            :xMax => locX + width,
            :yMin => locY,
            :yMax => locY + height,
        });

        // positioning legend (scale indicator)
        helper.align(legend, Layout.ALIGN_BOTTOM);

        positionMarker.locX = locX + width/2;
        positionMarker.locY = locY + height/2;
    }
    function onUpdate(dc as Dc){
        // draw the legend
        var color = darkMode ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        legend.draw(dc);

        // draw the map
        var track = trackManager.track;
        dc.setPenWidth(trackThickness);

        var xOffset = locX + width/2;
        var yOffset = locY + height/2;
        var xyCurrent = trackManager.xy;
        if(xyCurrent != null ){
            xOffset -= zoomFactor * xyCurrent[0];
            yOffset -= zoomFactor * xyCurrent[1];
        }
        var drawer = new TrackDrawer({
            :darkMode => darkMode,
            :xMin => locX,
            :xMax => locX + width,
            :xOffset => xOffset,
            :yMin => locY,
            :yMax => locY + height,
            :yOffset => yOffset,
            :zoomFactor => zoomFactor,
        });

        var index = trackManager.index;
        var lambda = trackManager.lambda;

        var pt = null;
        if(track != null){
            var pts = track.xyValues;
            if(index != null && lambda != null){
                // interpolated current position on track
                var pt1 = track.xyValues[index];
                var pt2 = track.xyValues[index+1];
                pt = [
                    pt1[0] + lambda * (pt2[0] - pt1[0]),
                    pt1[1] + lambda * (pt2[1] - pt1[1]),
                ] as Array<Float>;
                pts = track.xyValues.slice(null, index+1);
                pts.add(pt);
            }

            // track (start -> current track position)
            color= TrackDrawer.getColor(darkMode);
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);

            drawer.drawLines(dc, pts);
        }

        if(Data has :breadcrumps){
            // breadcrumps
            var breadcrumps = $.getApp().data.breadcrumps as Array<XY>;
            var count = breadcrumps.size();
            if(count > 0){
                color = darkMode ? Graphics.COLOR_DK_GREEN : Graphics.COLOR_GREEN;
                dc.setColor(color, Graphics.COLOR_TRANSPARENT);
                drawer.drawLines(dc, breadcrumps);

                // draw line from last breadcrump to current position
                if(xyCurrent != null){
                    var xy = breadcrumps[count-1];
                    var x1 = xOffset + zoomFactor * xy[0];
                    var y1 = yOffset + zoomFactor * xy[1];
                    var x2 = xOffset + zoomFactor * xyCurrent[0];
                    var y2 = yOffset + zoomFactor * xyCurrent[1];
                    dc.drawLine(x1, y1, x2, y2);
                }
            }
        }

        if(track != null){
            // track (current track position -> finish)
            if(pt != null && index != null){
                color = darkMode ? Graphics.COLOR_PINK : Graphics.COLOR_PINK;
                var pts = [pt] as Array<XY>;
                pts.addAll(track.xyValues.slice(index+1, null));
                dc.setColor(color, Graphics.COLOR_TRANSPARENT);
                drawer.drawLines(dc, pts);
            }

            // draw waypoints
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            drawer.drawWaypoints(dc, track.waypoints, trackThickness * 4);
        }

        // draw current position marker
        if(xyCurrent != null){
            positionMarker.draw(dc);
        }
    }

    hidden function setZoomFactor(value as Float) as Void{
        if(value != zoomFactor){
            zoomFactor = value;
            trackThickness = TrackDrawer.getTrackThickness(width, height, zoomFactor);
            legend.setZoomFactor(zoomFactor);
            refresh();
        }
    }

    function onTap(clickEvent as ClickEvent) as Boolean{
        // zoom in/out
        // |   40%    |  20%  |   40%   |
        // | zoom out |       | zoom in |
        var area = 0.4 * width;
        var x = clickEvent.getCoordinates()[0];
        var settings = $.getApp().settings;
        if(x <= locX + area){
            // zoom out
            settings.set(Settings.ID_ZOOMFACTOR, zoomFactor / 1.3);
        }else if(x >= locX + width - area){
            // zoom in
            settings.set(Settings.ID_ZOOMFACTOR, zoomFactor * 1.3);
        }else{
            return false;
        }
        return true;
    }

    function onSetting(sender as Object, id as Settings.Id, value as Settings.ValueType) as Void{
        // internal background updates
        MyDataField.onSetting(sender, id, value);

        if(id == Settings.ID_ZOOMFACTOR){
            // update zoomfactor
            setZoomFactor(value as Float);
        }else if(id == Settings.ID_TRACK){
            refresh();
        }
    }

    function onPosition(trackManager as TrackManager, xy as XY?) as Void{
        if(xy != null && xy != xyCurrent){
            xyCurrent = xy;
            positionMarker.setHeading(trackManager.heading);
            refresh();
        }
    }

    function setDarkMode(darkMode as Boolean) as Void{
        MyDataField.setDarkMode(darkMode);
        positionMarker.setDarkMode(darkMode);
    }
}
