import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;

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
        dc.setClip(locX, locY, width, height);
        dc.setColor(Graphics.COLOR_LT_GRAY, backgroundColor);
        try{
            if(doLayout){
                onLayout(dc);
            }
            previousLayout = layout;

            // check if onUpdate should be called
            if(doUpdate){
                doUpdate = false;
                onUpdate(dc);
            }
        }finally{
            dc.clearClip();
        }
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
}