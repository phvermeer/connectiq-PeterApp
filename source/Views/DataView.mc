import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Math;
import MyViews;
import MyMath;
import MyDrawables;

enum LayoutId {
	LAYOUT_ONE_FIELD = 0,
	LAYOUT_TWO_FIELDS = 1,
	LAYOUT_THREE_FIELDS = 2,
	LAYOUT_FOUR_FIELDS = 3,
	LAYOUT_SIX_FIELDS = 4,
	LAYOUT_CUSTOM1 = 5,
	LAYOUT_MAX = 5,
}

typedef Layout as Array< Array<Number> >;
// array of [x, y, width, height]

class DataView extends MyViews.MyView{
    hidden var upToDate as Boolean = false;
    hidden var layout as Layout;
    hidden var fields as Array<MyDataField>;
    hidden var edge as Edge;

    function initialize(options as {
        :layout as Layout,
        :fields as Array<MyDataField>
    }){
        MyView.initialize();
        layout = (options.hasKey(:layout) ? options.get(:layout) : []) as Layout;
        fields = (options.hasKey(:fields) ? options.get(:fields) : []) as Array<MyDataField>;
        updateFieldsLayout();

        edge = new MyDrawables.Edge({
            :visible => false,
            :position => MyDrawables.EDGE_ALL,
        });
    }

    // event handler when view becomes visible
    function onShow(){
        MyView.onShow();
        upToDate = false;

        for(var i=0; i<fields.size(); i++){
            fields[i].onShow();
        }
    }

    // event handler for graphical update request
    function onUpdate(dc as Dc) as Void{
        if(!upToDate){
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLUE);
            dc.clear();
        }
        upToDate = true;

        var count = MyMath.min([fields.size(), layout.size()] as Array<Number>);
        for(var i=0; i<count; i++){
            var field = fields[i];
            var fieldLayout = layout[i];
            updateFieldLayout(field, fieldLayout);
            field.draw(dc);
        }

        // draw the edge
        edge.draw(dc);
    }

    // update single field with given field layout
    hidden function updateFieldLayout(field as MyDataField, fieldLayout as Array<Number>) as Void{
        field.setLocation(fieldLayout[0], fieldLayout[1]);
        field.setSize(fieldLayout[2], fieldLayout[3]);
    }

    // update all fields with current layout
    hidden function updateFieldsLayout() as Void{
        var count = MyMath.min([fields.size(), layout.size()] as Array<Number>);
        for(var i=0; i<count; i++){
            updateFieldLayout(fields[i], layout[i]);
        }
    }

    // setter for Layout
    function setFieldsLayout(layout as Layout) as Void{
        self.layout = layout;
        updateFieldsLayout();
        upToDate = false;
    }
    function getFieldsLayout() as Layout{
        return layout;
    }

    // setter for DataFields
    function setFields(fields as Array<MyDataField>) as Void{
        self.fields = fields;
        updateFieldsLayout();
    }

    // getter for DataFields
    function getFields() as Array<MyDataField>{
         return fields;
    }

    // event handler for session state changes
    function onSessionState(state as SessionState) as Void{

        System.println("Session state changed to " + state.toString());
        switch(state){
            case SESSION_STATE_STOPPED:
                edge.color = Graphics.COLOR_RED;
                edge.setVisible(true);
                break;
            case SESSION_STATE_PAUSED:
                edge.color = Graphics.COLOR_YELLOW;
                edge.setVisible(true);
                break;
            default:
                edge.setVisible(false);
                break;
        }
        WatchUi.requestUpdate();
    }

    function isUpToDate() as Boolean{
        if(!upToDate){
            return false;
        }
        for(var i=0; i<fields.size(); i++){
            var field = fields[i];
            if(!field.isUpToDate()){
                return false;
            }
        }
        return true;
    }

    // event handler for the timer
    function onTimer() as Void{
        // update fields
        for(var i=0; i<fields.size(); i++){
            var field = fields[i];
            if(field has :onTimer){
                (field as TimerListener).onTimer();
            }
        }
        if(isVisible()){
            if(!isUpToDate()){
                requestUpdate();
            }

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
    static function getLayoutById(id as LayoutId) as Layout{
        var deviceSettings = System.getDeviceSettings();
        var width = deviceSettings.screenWidth;
        var height = deviceSettings.screenHeight;
        var margin = Math.ceil(width / 150.0f);
        
        var data = [];
        if(id == LAYOUT_ONE_FIELD){
            data.add([0, 0, width, height]);
        }else if(id == LAYOUT_TWO_FIELDS){
            var h = (height-margin) / 2;
            data.add([0, 0, width, h]);
            var y = h + margin;
            data.add([0, y, width, h]);
        }else if(id == LAYOUT_THREE_FIELDS){
            var h = (height-2*margin) / 3;
            data.add([0, 0, width, h]);
            var y = h + margin;
            data.add([0, y, width, h]);
            y += h + margin;
            data.add([0, y, width, h]);
        }else if(id == LAYOUT_FOUR_FIELDS){
            var h = (height-2*margin) / 3.0;
            var w = (width-margin) / 2.0;
            data.add([0, 0,width, h]);
            var y = h + margin;
            data.add([0, y, w, h]);
            var x = w + margin;
            data.add([x, y, w, h]);
            y += h + margin;
            data.add([0, y, width, h]);
        }else if(id == LAYOUT_SIX_FIELDS){
            var h = (height-2*margin) / 4.0;
            var w = (width-margin) / 2.0;
            data.add([0, 0, width, h]);
            var y = h + margin;
            var x = w + margin;
            data.add([0, y, w, h]);
            data.add([x, y, w, h]);
            y += h + margin;
            data.add([0, y, w, h]);
            data.add([x, y, w, h]);
            y += h + margin;
            data.add([0, y, width, h]);
        }else if(id == LAYOUT_CUSTOM1){
            var h = 0.25 * height - 0.5 * margin;
            data.add([0, 0, width, h]);
            var y = h + margin;
            h = 0.5 * height - margin;
            var w = 0.5 * width - 0.5 * margin;
            data.add([0, y, w, h]);
            var x = w + margin;
            var h1 = 0.5 * h - 0.5 * margin;
            w = width - w - margin;
            data.add([x, y, w, h1]);
            y += h1 + margin;
            h1 = h - h1 - margin;
            data.add([x, y, w, h1]);
            y += h1 + margin;
            h = height - y;
            data.add([0, y, width, h]);
        }else{
            var w2 = 0.5 * width;
            var h2 = 0.5 * height;
            data.add([w2/2, h2/2, w2, h2]);
        }
        return data as Layout;            
    }
}