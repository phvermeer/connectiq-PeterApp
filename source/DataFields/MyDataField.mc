import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Application;
import Toybox.Activity;

class MyDataField extends WatchUi.Drawable{
    hidden var darkMode as Boolean;
    hidden var previousLayout as Array<Numeric>?;
    hidden var isVisible as Boolean = false;

    function initialize(options as {
        :locX as Numeric,
        :locY as Numeric,
        :width as Numeric,
        :height as Numeric,
        :darkMode as Boolean,
    }){
        Drawable.initialize(options);
        darkMode = options.hasKey(:darkMode) ? options.get(:darkMode) as Boolean : false;
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
    }


    function onShow() as Void{
        isVisible = true;
    }
    function onHide() as Void{
        isVisible = false;
    }

    protected function refresh() as Void{
        if(isVisible){
            WatchUi.requestUpdate();
        }
    }

    protected function onLayout(dc as Dc) as Void{
        // override this function
    }
    protected function onUpdate(dc as Dc) as Void{
        // override this function
    }

    public function onData(data as Data) as Void{
        // called periodicly from external
    }

    public function onTap(clickEvent as ClickEvent) as Boolean{
        // override this function
        return false;
    }

    function setDarkMode(darkMode as Boolean) as Void{
        self.darkMode = darkMode;
        refresh();
    }

    function onSetting(id as SettingId, value as Settings.ValueType) as Void{
        if(id == SETTING_DARK_MODE){
            setDarkMode(value as Boolean);
        }
    }

    function getBackgroundColor() as ColorType{
        return darkMode ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE;
    }
    function getForegroundColor() as ColorType{
        return darkMode ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
    }
}