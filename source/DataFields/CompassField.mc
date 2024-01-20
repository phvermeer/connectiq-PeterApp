import MyBarrel.Drawables;
import Toybox.Lang;
import Toybox.Graphics;
import Toybox.Activity;
import MyBarrel.Layout;

class CompassField extends MyDataField{
    var compass as Compass;

    function initialize(options as {
        :darkMode as Boolean,
    }){
        MyDataField.initialize(options);
        compass = new Compass({
            :darkMode => darkMode,
        });
    }

    function onLayout(dc as Dc) as Void{
        var margin = Math.ceil(dc.getWidth()*0.01).toNumber();
        var helper = Layout.getLayoutHelper({
            :margin => margin,
            :xMin => locX,
            :xMax => locX + width,
            :yMin => locY,
            :yMax => locY + height,
        });

        compass.setSize(1,1);
        helper.resizeToMax(compass, true);
    }

    function onActivityInfo(info as Activity.Info) as Void{
        var heading = info.currentHeading;

        if(compass.heading != heading){
            compass.heading = heading;
            refresh();
        }
    }

    function onUpdate(dc as Dc){
        compass.draw(dc);
    }
}