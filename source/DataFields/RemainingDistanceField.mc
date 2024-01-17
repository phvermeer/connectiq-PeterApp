import Toybox.Lang;
import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Position;

(:advanced)
class RemainingDistanceField extends NumericField{
    function initialize(fieldId as DataFieldId, options as {
        :locX as Numeric,
        :locY as Numeric,
        :width as Numeric,
        :height as Numeric,
        :backgroundColor as ColorType,
    }){
        // determine the label
        var strLabel
            = (fieldId == DATAFIELD_REMAINING_DISTANCE) ? WatchUi.loadResource(Rez.Strings.remainingDistance)
            : "???";

        options.put(:label, strLabel);
        NumericField.initialize(options);
    }

    function onActivityInfo(info as Activity.Info) as Void{
        var track = $.getApp().track;
        var value = null;
        var useAlertColor = false;
        if(track != null){
            if(!track.isOnTrack()){
                useAlertColor = true;
            }

            var distanceElapsed = (track.distanceElapsed != null) ? track.distanceElapsed as Float : 0f;
            value = formatDistance(track.distanceTotal - distanceElapsed);
            setValue(value);
        }else{
            setValue(null);
        }
        // use alert color RED when off track
        var hasAlertColor = self.value.color == Graphics.COLOR_RED;
        if(hasAlertColor != useAlertColor){
            self.value.color = useAlertColor ? Graphics.COLOR_RED : getForegroundColor();
        }
        
    }

    static function formatDistance(value as Numeric|Null) as Numeric|Null{
        if(value != null){
            value /= 1000;
        }
        return value;
    }
}