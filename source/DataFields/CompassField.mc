import MyDrawables;
import Toybox.Lang;
import Toybox.Graphics;

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
        var helper = MyLayout.getLayoutHelper({
            :margin => margin,
            :xMin => locX,
            :xMax => locX + width,
            :yMin => locY,
            :yMax => locY + height,
        });

        compass.setSize(1,1);
        helper.resizeToMax(compass, true);
    }

    function onData(data as Data) as Void{
        var info = data.activityInfo;
        var bearing = (info != null)
            ? (Activity.Info has :bearing)
                ? info.bearing
                : info.currentHeading
            : null;

        if(compass.bearing != bearing){
            compass.bearing = bearing;
            refresh();
        }
    }

    function onUpdate(dc as Dc){
        compass.draw(dc);
    }
}