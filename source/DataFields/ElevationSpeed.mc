import Toybox.Lang;
import Toybox.Graphics;
import Toybox.Activity;
import Toybox.Time;

class ElevationSpeedField extends NumericField{
    const TIMESPAN as Duration = new Duration(15); // numer of seconds for altitude diff calculation
    typedef Item as Array<Float|Moment>;
    static var fifo as Array<Item> = new Array<Item>[0];

    function initialize(options as {
        :locX as Numeric,
        :locY as Numeric,
        :width as Numeric,
        :height as Numeric,
        :darkMode as Boolean,
    }){
        options.put(:label, WatchUi.loadResource(Rez.Strings.elevationSpeed));
        NumericField.initialize(options);
    }

    function onActivityInfo(sender as Object, info as Activity.Info) as Void{
        var time = Time.now();
        var altitude = info.altitude;
        var speed = null;

        if(altitude != null){
            var count = fifo.size();
            if(count > 0){
                var item = fifo[count-1] as Item;
                var t = item[0] as Moment;
                if(time.compare(t) <= 0){
                    // abort if this timestamp (or newer) is already added)
                    return;
                }
            }
            // add new item
            fifo.add([time, altitude] as Item);
        }

        // check if old items should be removed
        var timeOld = time.subtract(TIMESPAN) as Moment;
        var i=0;
        for(; i < fifo.size(); i++){
            var item = fifo[i] as Item;
            var t = item[0] as Moment;
            if(!timeOld.greaterThan(t)){
                break;
            }
        }

        // remove old items from fifo
        if(i>0){
            fifo = fifo.slice(i, null);
        }
        
        // calculate speed
        var count = fifo.size();
        if(count > 1){
            var first = fifo[0] as Item;
            var time0 = first[0] as Moment;
            var altitude0 = first[1] as Float;

            var last = fifo[count-1] as Item;
            var time1 = last[0] as Moment;
            var altitude1 = last[1] as Float;

            speed = Math.round(60f * (altitude1 - altitude0) / time1.subtract(time0).value()).toNumber(); // 60 * [m/s] => [m/min]
        }
        setValue(speed);
    }
}