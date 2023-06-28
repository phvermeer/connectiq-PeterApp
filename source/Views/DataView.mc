import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import MyViews;
import MyMath;

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