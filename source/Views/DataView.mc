import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import MyViews;
import MyMath;

class DataView extends MyViews.MyView{
    hidden var isDrawn as Boolean = false;
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

    function onShow(){
        isDrawn = false;
    }

    function drawFirst(dc as Dc) as Void{
        // draw from scratch
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLUE);
        dc.clear();

        // draw field areas
        var count = MyMath.min([fields.size(), layout.size()] as Array<Number>);
        for(var i=0; i<count; i++){
            var field = fields[i];
            field.draw(dc);
        }
    }
    function drawChanges(dc as Dc) as Void{
        // draw changes only
    }

    function onUpdate(dc as Dc) as Void{
        if(!isDrawn){
            isDrawn = true;
            drawFirst(dc);
        }else{
            drawChanges(dc);
        }
    }

    hidden function updateLayout() as Void{
        var count = MyMath.min([fields.size(), layout.size()] as Array<Number>);
        for(var i=0; i<count; i++){
            var field = fields[i];
            var fieldLayout = layout[i];
            field.locX = fieldLayout.get(:locX) as Number;
            field.locY = fieldLayout.get(:locY) as Number;
            field.width = fieldLayout.get(:width) as Number;
            field.height = fieldLayout.get(:height) as Number;
        }
        isDrawn = false;
    }

    function setLayout(layout as Layout){
        self.layout = layout;
        updateLayout();
    }

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
        var session = $.session as Session;
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
}