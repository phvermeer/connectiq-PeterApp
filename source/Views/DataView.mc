import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import MyViews;
import MyMath;

enum LayoutId {
	LAYOUT_FIRST = 0x1,
	LAYOUT_LAST = 0x7,
	LAYOUT_ONE_FIELD = 0x1,
	LAYOUT_TWO_FIELDS = 0x2,
	LAYOUT_THREE_FIELDS = 0x3,
	LAYOUT_FOUR_FIELDS = 0x4,
	LAYOUT_SIX_FIELDS = 0x5,
	LAYOUT_CUSTOM1 = 0x6,
	LAYOUT_CUSTOM2 = 0x7,
}

typedef Layout as Array<{
    :locX as Number,
    :locY as Number,
    :width as Number,
    :height as Number
}>;

class DataView extends MyViews.MyView{
    hidden var drawn as Boolean = false;
    hidden var visible as Boolean = false;
    hidden var layout as Layout;
    hidden var fields as Array<MyDataField>;

    function initialize(options as {
        :layout as Layout,
        :fields as Array<MyDataField>
    }){
        MyView.initialize();
        layout = (options.hasKey(:layout) ? options.get(:layout) : []) as Layout;
        fields = (options.hasKey(:fields) ? options.get(:fields) : []) as Array<MyDataField>;
        updateLayout();
    }

    // event handler when view becomes visible
    function onShow(){
        drawn = false;
        visible = true;
    }

    function onHide(){
        visible = false;
    }

    // event handler for graphical update request
    function onUpdate(dc as Dc) as Void{
        // clear
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLUE);
        dc.clear();

        var count = MyMath.min([fields.size(), layout.size()] as Array<Number>);
        for(var i=0; i<count; i++){
            var field = fields[i];
            field.draw(dc);
        }
    }

    // update single field with given field layout
    hidden function updateFieldLayout(field as MyDataField, fieldLayout as {
        :locX as Number,
        :locY as Number,
        :width as Number,
        :height as Number
    }) as Void{
        field.locX = fieldLayout.get(:locX) as Number;
        field.locY = fieldLayout.get(:locY) as Number;
        field.width = fieldLayout.get(:width) as Number;
        field.height = fieldLayout.get(:height) as Number;
    }

    // update all fields with current layout
    hidden function updateLayout() as Void{
        var count = MyMath.min([fields.size(), layout.size()] as Array<Number>);
        for(var i=0; i<count; i++){
            updateFieldLayout(fields[i], layout[i]);
        }
        drawn = false;
    }

    // setter for Layout
    function setLayout(layout as Layout){
        self.layout = layout;
        updateLayout();
    }

    // setter for DataFields
    function setFields(fields as Array<MyDataField>) as Void{
        self.fields = fields;
        updateLayout();
    }

    // event handler for session state changes
    function onSessionState(state as SessionState) as Void{
        System.println("Session state changed to " + state.toString());
    }

    // event handler for the timer
    function onTimer() as Void{
        // update fields
        var doUpdate = false;
        for(var i=0; i<fields.size(); i++){
            var field = fields[i];
            if(field has :onTimer){
                (field as TimerListener).onTimer();
            }
            if(!field.isUpToDate()){
                doUpdate = true;
            }
        }
        if(doUpdate){
            WatchUi.requestUpdate();
        }
    }

    // event handler for key press
    function onKey(sender as MyViewDelegate, keyEvent as KeyEvent) as Boolean{
        // only respond to key enter (keep default handling for other events)
		if(keyEvent.getType() == WatchUi.PRESS_TYPE_ACTION && keyEvent.getKey() == WatchUi.KEY_ENTER){
            // toggle session start/stop
            var session = $.getApp().session;
            switch(session.getState()){
                case SESSION_STATE_BUSY:
                case SESSION_STATE_PAUSED:
                    session.stop();
                    break;
                default:
                    session.start();
            }
            return true;
        }
        return false;
    }

    // get the field layout from the identifier
    static function getLayout(id as LayoutId) as Layout{
        var deviceSettings = System.getDeviceSettings();
        var width = deviceSettings.screenWidth;
        var height = deviceSettings.screenHeight;
        var margin = Math.ceil(width / 150.0f);
        
        var data = [];
        if(id == LAYOUT_ONE_FIELD){
            data.add({
                :locX => 0,
                :locY => 0,
                :width => width,
                :height => height
            });
        }else if(id == LAYOUT_TWO_FIELDS){
            var h = (height-margin) / 2;
            data.add({
                :locX => 0,
                :locY => 0,
                :width => width,
                :height => h
            });
            var y = h + margin;
            data.add({
                :locX => 0,
                :locY => y,
                :width => width,
                :height => h
            });
        }else if(id == LAYOUT_THREE_FIELDS){
            var h = (height-2*margin) / 3;
            data.add({
                :locX => 0,
                :locY => 0,
                :width => width,
                :height => h
            });
            var y = h + margin;
            data.add({
                :locX => 0,
                :locY => y,
                :width => width,
                :height => h
            });
            y += h + margin;
            data.add({
                :locX => 0,
                :locY => y,
                :width => width,
                :height => h
            });
        }else if(id == LAYOUT_FOUR_FIELDS){
            var h = (height-2*margin) / 3.0;
            var w = (width-margin) / 2.0;
            data.add({
                :locX => 0,
                :locY => 0,
                :width => width,
                :height => h
            });
            var y = h + margin;
            data.add({
                :locX => 0,
                :locY => y,
                :width => w,
                :height => h
            });
            var x = w + margin;
            data.add({
                :locX => x,
                :locY => y,
                :width => w,
                :height => h
            });
            y += h + margin;
            data.add({
                :locX => 0,
                :locY => y,
                :width => width,
                :height => h
            });
        }else if(id == LAYOUT_SIX_FIELDS){
            var h = (height-2*margin) / 4.0;
            var w = (width-margin) / 2.0;
            data.add({
                :locX => 0,
                :locY => 0,
                :width => width,
                :height => h
            });
            var y = h + margin;
            var x = w + margin;
            data.add({
                :locX => 0,
                :locY => y,
                :width => w,
                :height => h
            });
            data.add({
                :locX => x,
                :locY => y,
                :width => w,
                :height => h
            });
            y += h + margin;
            data.add({
                :locX => 0,
                :locY => y,
                :width => w,
                :height => h
            });
            data.add({
                :locX => x,
                :locY => y,
                :width => w,
                :height => h
            });
            y += h + margin;
            data.add({
                :locX => 0,
                :locY => y,
                :width => width,
                :height => h
            });
        }else if(id == LAYOUT_CUSTOM1){
            var h = 0.25 * height - 0.5 * margin;
            data.add({
                :locX => 0,
                :locY => 0,
                :width => width,
                :height => h
            });
            var y = h + margin;
            h = 0.5 * height - margin;
            var w = 0.5 * width - 0.5 * margin;
            data.add({
                :locX => 0,
                :locY => y,
                :width => w,
                :height => h
            });
            var x = w + margin;
            var h1 = 0.5 * h - 0.5 * margin;
            w = width - w - margin;
            data.add({
                :locX => x,
                :locY => y,
                :width => w,
                :height => h1
            });
            y += h1 + margin;
            h1 = h - h1 - margin;
            data.add({
                :locX => x,
                :locY => y,
                :width => w,
                :height => h1
            });
            y += h1 + margin;
            h = height - y;
            data.add({
                :locX => 0,
                :locY => y,
                :width => width,
                :height => h
            });
        }else if(id == LAYOUT_CUSTOM2){
            // Two transparent fields on top and a big field (without margins)
            var x = 0;
            var y = 0;
            var h = 0.2f * height;
            var w = 0.5f * width;
            data.add({
                :locX => x,
                :locY => y,
                :width => w,
                :height => h
            });
            x = w;
            data.add({
                :locX => x,
                :locY => y,
                :width => w,
                :height => h
            });
            x = 0;
            y = h;
            w = width;
            h = height - h;
            data.add({
                :locX => x,
                :locY => y,
                :width => w,
                :height => h
            });
        }else{
            var w2 = 0.5 * width;
            var h2 = 0.5 * height;
            data.add({
                :locX => w2,
                :locY => h2,
                :width => w2,
                :height => h2
            });
        }
        return data as Layout;            
    }
}