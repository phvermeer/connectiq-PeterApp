import Toybox.Lang;
import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Position;

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

    function onData(data as Data) as Void{
        var track = $.getApp().track;
        var value = null;
        var color = Graphics.COLOR_RED;
        if(track != null && track.isOnTrack()){
            if(self.value.color == color){
                color = getForegroundColor();
            }

            var distanceElapsed = (track.distanceElapsed != null) ? track.distanceElapsed as Float : 0f;
            var distanceOffTrack = (track.distanceOffTrack != null) ? track.distanceOffTrack as Float : 0f;
            value = formatDistance(track.distanceTotal + distanceOffTrack - distanceElapsed);
        }
        self.value.color = color;
        setValue(value);
    }

    static function formatDistance(value as Numeric|Null) as Numeric|Null{
        if(value != null){
            value /= 1000;
        }
        return value;
    }
}