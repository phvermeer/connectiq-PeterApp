import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Activity;
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
	LAYOUT_CUSTOM2 = 6,
	LAYOUT_MAX = 6,
}

class DataView extends MyViews.MyView{
	enum SettingId {
		SETTING_LAYOUT = 0,
		SETTING_FIELDS = 1,
		SETTING_ENABLED = 2,
	}
    typedef ScreenSettings as Array< Boolean | LayoutId | Array<DataFieldId> >; // [enabled as Boolean, layoutId as LayoutId, fieldIds as Array<DataField>]
    typedef ScreensSettings as Array<ScreenSettings>; // array of [screenSettings as ScreenSettings]
    typedef Layout as Array< Array<Number> >;
    //  [
    //      [x, y, width, height]   (field 1)
    //      ...
    //      [x, y, width, height]   (field n)
    //  ]

    hidden var screenIndex as Number = 0;
    hidden var screensSettings as ScreensSettings;
    hidden var layout as Layout = [] as Layout;
    hidden var fields as Array<MyDataField> = [] as Array<MyDataField>;
    hidden var edge as Edge;
    hidden var darkMode as Boolean;

    function initialize(screenIndex as Number, screensSettings as ScreensSettings){
        MyView.initialize();

        self.screenIndex = MyMath.min([screenIndex, screensSettings.size()-1] as Array<Number>) as Number;
        self.screensSettings = screensSettings;

        var screenSettings = screensSettings[screenIndex];
        applyScreenSettings(screenSettings); // fields and layout

        edge = new MyDrawables.Edge({
            :position => MyDrawables.EDGE_ALL,
            :color => Graphics.COLOR_TRANSPARENT,
        });

        // listen to setting changes with "onSetting()"
        var settings = $.getApp().settings;
        settings.addListener(self);
        darkMode = settings.get(SETTING_DARK_MODE) as Boolean;

        // listen to session changes with "onSessionState()"
        var session = $.getApp().session;
        onSessionState(session.getState());
        session.addListener(self);
    }

    // event handler when view becomes visible
    function onShow(){
        MyView.onShow();
        for(var i=0; i<fields.size(); i++){
            fields[i].onShow();
        }
    }

    function onHide(){
        for(var i=0; i<fields.size(); i++){
            fields[i].onHide();
        }
    }

    // event handler for graphical update request
    function onUpdate(dc as Dc) as Void{
        var overlay = hasFieldOverlay();
        if(!overlay){
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLUE);
            dc.clear();
        }

        var count = MyMath.min([fields.size(), layout.size()] as Array<Number>);
        for(var i=0; i<count; i++){
            var field = fields[i];
            var fieldLayout = layout[i];
            updateFieldLayout(field, fieldLayout);
            dc.setClip(field.locX, field.locY, field.width, field.height);
            try{
                if(i==0 || !overlay){
                    dc.setColor(Graphics.COLOR_LT_GRAY, field.getBackgroundColor());
                    dc.clear();
                }
                field.draw(dc);
            }finally{
                dc.clearClip();
            }
        }

        // draw edge
        if(edge.color != Graphics.COLOR_TRANSPARENT){
            edge.draw(dc);
        }
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
    }
    function getFieldsLayout() as Layout{
        return layout;
    }

    // setter for DataFields
    function setFields(fields as Array<MyDataField>) as Void{
        var fieldsOld = self.fields;
        self.fields = fields;
        updateFieldsLayout();

        // Notify fields
        if(isVisible()){
            for(var i=0; i<fieldsOld.size(); i++){
                fieldsOld[i].onHide();
            }
            for(var i=0; i<fields.size(); i++){
                fields[i].onShow();
            }
        }
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
            break;
        case SESSION_STATE_PAUSED:
            edge.color = Graphics.COLOR_YELLOW;
            break;
        default:
            edge.color = Graphics.COLOR_TRANSPARENT;
            break;
        }
        WatchUi.requestUpdate();
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
    
    // event handler for screen touch
    function onTap(sender as MyViewDelegate, clickEvent as ClickEvent) as Boolean{
        // forward event to fields
        for(var i=0; i<fields.size(); i++){
            var field = fields[i];
            var xy = clickEvent.getCoordinates();
            if(
                xy[0] >= field.locX && 
                xy[0] <= field.locX + field.width && 
                xy[1] >= field.locY && 
                xy[1] <= field.locY + field.height
            ){
                return field.onTap(clickEvent);
            }            
        }
        return false;
    }

    function onSwipe(sender as MyViewDelegate, swipeEvent as WatchUi.SwipeEvent) as Lang.Boolean{
        var count = screensSettings.size();

        switch(swipeEvent.getDirection()){
            case WatchUi.SWIPE_DOWN:
                // next screen id
                do{
                    screenIndex++;
                    if(screenIndex >= count){
                        screenIndex = 0;
                    }
                }while(!(screensSettings[screenIndex][SETTING_ENABLED] as Boolean));
                break;
            case WatchUi.SWIPE_UP:
                do{
                    screenIndex--;
                    if(screenIndex <0){
                        screenIndex = count-1;
                    }
                }while(!(screensSettings[screenIndex][SETTING_ENABLED] as Boolean));
                break;
            default:
                return false;
        }
        // show new screen
        var screenSettings = screensSettings[screenIndex] as ScreenSettings;
        applyScreenSettings(screenSettings);
        WatchUi.requestUpdate();
        return true;
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
            data.add([0, y, width, height-y]);
        }else if(id == LAYOUT_THREE_FIELDS){
            var h = (height-2*margin) / 3;
            data.add([0, 0, width, h]);
            var y = h + margin;
            data.add([0, y, width, h]);
            y += h + margin;
            data.add([0, y, width, height-y]);
        }else if(id == LAYOUT_FOUR_FIELDS){
            var h = (height-2*margin) / 3.0;
            var w = (width-margin) / 2.0;
            data.add([0, 0,width, h]);
            var y = h + margin;
            data.add([0, y, w, h]);
            var x = w + margin;
            data.add([x, y, w, h]);
            y += h + margin;
            data.add([0, y, width, height-h]);
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
            data.add([0, y, width, height-y]);
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
        }else if(id == LAYOUT_CUSTOM2){
            // full screen
            data.add([0, 0, width, height]);
            // top
            var h = 0.25 * height;
            var y = 0;
            data.add([0, y, width, h]);
            // left
            y = (height - h)/2;
            var w = 0.4 * (width);
            data.add([0, y, w, h]);
            // right
            var x = width - w;
            data.add([x, y, w, h]);
        }else{
            var w2 = 0.5 * width;
            var h2 = 0.5 * height;
            data.add([w2/2, h2/2, w2, h2]);
        }
        return data as Layout;            
    }

    function hasFieldOverlay() as Boolean{
        // more then one fields
        if(layout.size()>1){
            // first field is full screen
            var ds = System.getDeviceSettings();
            return (layout[0][2] >= ds.screenWidth && layout[0][3] >= ds.screenHeight);
        }else{
            return false;
        }
    }

    function onSetting(id as SettingId, value as Settings.ValueType) as Void{
        if(id == SETTING_DATASCREENS){
            var screensSettings = value as ScreensSettings;
            if(screenIndex >= screensSettings.size()){
                // current screen is removed, jump to first screen
                screenIndex = 0;
            }else if(!(screensSettings[screenIndex][SETTING_ENABLED] as Boolean)){
               // current is disabled -> jump to first screen
                screenIndex = 0;
            }

            var screenSettings = screensSettings[screenIndex] as ScreenSettings;
            applyScreenSettings(screenSettings);
        }else if(id == SETTING_DARK_MODE){
            setDarkMode(value as Boolean);
        }
    }

    static function getDarkMode(backgroundColor as ColorType) as Boolean{
        var rgb = MyTools.colorToRGB(backgroundColor);
        var intensity = Math.mean(rgb);
        return (intensity < 100);
    }
    hidden function setDarkMode(darkMode as Boolean) as Void{
        self.darkMode = darkMode;
    }
    hidden function applyScreenSettings(screenSettings as ScreenSettings) as Void{
        var fields = $.getApp().fieldManager.getFields(screenSettings[SETTING_FIELDS] as Array<DataFieldId>);
        var layout = DataView.getLayoutById(screenSettings[SETTING_LAYOUT] as LayoutId);
        setFields(fields);
        setFieldsLayout(layout);
    }
}