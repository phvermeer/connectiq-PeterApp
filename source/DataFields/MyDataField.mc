import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Application;

class MyDataField extends WatchUi.Drawable{
    hidden var doUpdate as Boolean = true;
    hidden var backgroundColor as ColorType;
    hidden var previousLayout as Array<Numeric>?;

    function initialize(options as {
        :locX as Numeric,
        :locY as Numeric,
        :width as Numeric,
        :height as Numeric,
        :backgroundColor as ColorType,
    }){
        Drawable.initialize(options);
        var color = options.get(:backgroundColor);
        backgroundColor = (color != null) ? color : Graphics.COLOR_WHITE;
    }

    function draw(dc as Dc) as Void{
        // check if onLayout should be called
        var doLayout = false;
        var layout = [locX, locY, width, height] as Array<Numeric>;
        if(previousLayout != null){
            var prevLayout = previousLayout;
            for(var i=0; i<layout.size(); i++){
                if(layout[i] != prevLayout[i]){
                    doLayout = true;
                    doUpdate = true;
                    break;
                }
            }
        }else{
            doLayout = true;
        }

        // call onLayout and onUpdate methods
        if(doLayout){
            onLayout(dc);
        }
        previousLayout = layout;

        // alway update when called
        onUpdate(dc);
        doUpdate = false;
    }

    function onShow() as Void{
        doUpdate = true;
    }

    protected function onLayout(dc as Dc) as Void{
        // override this function
    }
    protected function onUpdate(dc as Dc) as Void{
        // override this function
    }

    public function onTimer() as Void{
        // called periodicly from external
    }

    // this function will indicate if the value is changed since last onUpdate()
    function isUpToDate() as Boolean{
        return !doUpdate;
    }

    function setBackgroundColor(color as Graphics.ColorType) as Void{
        backgroundColor = color;
        doUpdate = true;
    }
    function getBackgroundColor() as Graphics.ColorType{
        return backgroundColor;
    }

    function onSetting(id as SettingId, value as PropertyValueType) as Void{
        if(id == SETTING_BACKGROUND_COLOR){
            setBackgroundColor(value as ColorType);
        }
    }
}