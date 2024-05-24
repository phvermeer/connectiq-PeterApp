import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Activity;
import Toybox.Math;
import MyBarrel.Views;
import MyBarrel.Math2;
import MyBarrel.Drawables;
import MyBarrel.Layout;

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

class DataView extends MyView{
	enum SettingId {
		SETTING_LAYOUT = 0,
		SETTING_FIELDS = 1,
		SETTING_ENABLED = 2,
	}
    typedef ScreenSettings as Array< Boolean | LayoutId | Array<DataFieldId> >; // [enabled as Boolean, layoutId as LayoutId, fieldIds as Array<DataField>]
    typedef ScreensSettings as Array<ScreenSettings>; // array of [screenSettings as ScreenSettings]

    typedef FieldLayout as Array<Number>; // [locX, locY, width, height]
    typedef Layout as Array<FieldLayout>;
    hidden var screenIndex as Number = 0;
    hidden var screensSettings as ScreensSettings;
    hidden var layout as Layout = [] as Layout;
    hidden var fields as Array<MyDataField> = [] as Array<MyDataField>;
    hidden var edge as Edge;
    hidden var darkMode as Boolean;

    function initialize(
        screenIndex as Number, 
        screensSettings as ScreensSettings, 
        delegate as MyViewDelegate
    ){
        MyView.initialize(delegate);

        self.screenIndex = Math2.min([screenIndex, screensSettings.size()-1] as Array<Number>) as Number;
        self.screensSettings = screensSettings;

        edge = new Drawables.Edge({
            :position => Edge.EDGE_ALL,
            :color => Graphics.COLOR_TRANSPARENT,
        });

        // listen to setting changes with "onSetting()"
        var settings = $.getApp().settings;
        darkMode = settings.get(Settings.ID_DARK_MODE) as Boolean;
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
        MyView.onHide();
    }

    function onBack(sender as MyViewDelegate) as Boolean{
        // Open StopView
        var view = new StopView(sender);
        WatchUi.switchToView(view, sender, WatchUi.SLIDE_IMMEDIATE);
        return true;
    }

    // event handler for graphical layout 
    function onLayout(dc as Dc){
        var screenSettings = screensSettings[screenIndex];
        applyScreenSettings(screenSettings); // fields and layout
    }

    // event handler for graphical update request
    function onUpdate(dc as Dc) as Void{
        var overlay = hasFieldOverlay();
        if(!overlay){
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLUE);
            dc.clear();
        }

        var count = Math2.min([fields.size(), layout.size()] as Array<Number>);
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
        var count = Math2.min([fields.size(), layout.size()] as Array<Number>);
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
    function onSessionState(sender as Object, state as SessionState) as Void{
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
        for(var i=fields.size()-1; i>=0; i--){
            var xy = clickEvent.getCoordinates();

            // compare xy with layout position
            var fieldLayout = layout[i] as FieldLayout; // [x,y,w,h]
            if(
                xy[0] >= fieldLayout[0] && 
                xy[0] <= fieldLayout[0] + fieldLayout[2] && 
                xy[1] >= fieldLayout[1] && 
                xy[1] <= fieldLayout[1] + fieldLayout[3]
            ){
                if(onFieldTap(clickEvent, i, fields[i])){
                    return true;
                }
            }            
        }
        return false;
    }
    hidden function onFieldTap(clickEvent as ClickEvent, fieldIndex as Number, field as MyDataField) as Boolean{
        return field.onTap(clickEvent);
    }

    function onPreviousPage(sender as MyViewDelegate) as Boolean{
        swipePage(false);
        return true;
    }
    function onNextPage(sender as MyViewDelegate) as Boolean{
        swipePage(true);
        return true;
    }
    hidden function swipePage(forward as Boolean) as Void{
        var count = screensSettings.size();

        if(!forward){
            // next screen id
            do{
                screenIndex++;
                if(screenIndex >= count){
                    screenIndex = 0;
                }
            }while(!(screensSettings[screenIndex][SETTING_ENABLED] as Boolean));
        }else{
            do{
                screenIndex--;
                if(screenIndex <0){
                    screenIndex = count-1;
                }
            }while(!(screensSettings[screenIndex][SETTING_ENABLED] as Boolean));
        }
        // show new screen
        var screenSettings = screensSettings[screenIndex] as ScreenSettings;
        applyScreenSettings(screenSettings);
        WatchUi.requestUpdate();
    }

    hidden static function distributeSpace(total as Number, margin as Number, parts as Array<Number>) as Array<Number>{
        var count = parts.size();
        var total_ = total - (count - 1) * margin;
        var factor = 1f * total_ / Math2.sum(parts);
        var results = [] as Array<Number>;
        var spare = total_;
        for(var i=0; i<parts.size(); i++){
            var result = (factor * parts[i]).toNumber();
            results.add(result);
            spare -= result;
        }

        // divide spare space (n, 1, n-1, 2, n-2, ...)
        var i = -1;
        var iReverse = count;
        var reverse = true;
        while(spare > 0){
            if(reverse){
                iReverse--;
                results[iReverse] += 1;
            }else{
                i++;
                results[i] += 1;
            }
            reverse = !reverse;
            spare--;
        }

        return results;
    }

    hidden static function getFieldLayout(rowSizes as Array, colSizes as Array, margin as Number, row as Number, col as Number) as FieldLayout{
        var x = 0;
        for(var i=0; i < col; i++){
            x += colSizes[i] + margin;
        }

        var y = 0;
        for(var i=0; i < row; i++){
            y += rowSizes[i] + margin;
        }

        return [x, y, colSizes[col], rowSizes[row]] as FieldLayout;
    }

    hidden static function mergeFieldLayouts(fieldLayouts as Array<FieldLayout>) as FieldLayout{
        if(fieldLayouts.size() >= 2){
            var fl = fieldLayouts[0];
            var xMin = fl[0];
            var xMax = xMin + fl[2];
            var yMin = fl[1];
            var yMax = yMin + fl[3];
            for(var i=1; i<fieldLayouts.size(); i++){
                fl = fieldLayouts[i];
                var xMin_ = fl[0];
                var xMax_ = fl[0] + fl[2];
                var yMin_ = fl[1];
                var yMax_ = fl[1] + fl[3];
                if(xMin_ < xMin) { xMin = xMin_; }
                if(xMax_ > xMax) { xMax = xMax_; }
                if(yMin_ < xMin) { yMin = yMin_; }
                if(yMax_ > xMax) { yMax = yMax_; }
            }
            return [xMin, yMin, xMax-xMin, yMax-yMin] as FieldLayout;
        }else{
            throw new InvalidValueException("At least 2 fieldlayouts are required to merge field layouts");
        }
    }

    // get the field layout from the identifier
    static function getLayoutById(id as LayoutId) as Layout{

        var deviceSettings = System.getDeviceSettings();
        var width = deviceSettings.screenWidth;      // width
        var height = deviceSettings.screenHeight;    // height
        var margin = Math.ceil(width / 150.0f).toNumber();      // margin

        var data = [];
        if(id == LAYOUT_ONE_FIELD){
            data.add(getFieldLayout([height], [width], margin, 0, 0));
        }else if(id == LAYOUT_TWO_FIELDS){
            var rowSizes = distributeSpace(height, margin, [1,1] as Array<Number>);
            data.add(getFieldLayout(rowSizes, [width], margin, 0, 0));
            data.add(getFieldLayout(rowSizes, [width], margin, 1, 0));
        }else if(id == LAYOUT_THREE_FIELDS){
            var rowSizes = distributeSpace(height, margin, [1,1,1] as Array<Number>);
            data.add(getFieldLayout(rowSizes, [width], margin, 0, 0));
            data.add(getFieldLayout(rowSizes, [width], margin, 1, 0));
            data.add(getFieldLayout(rowSizes, [width], margin, 2, 0));
        }else if(id == LAYOUT_FOUR_FIELDS){
            var rowSizes = distributeSpace(height, margin, [1,1,1] as Array<Number>);
            var colSizes = distributeSpace(width, margin, [1,1] as Array<Number>);
            data.add(getFieldLayout(rowSizes, [width], margin, 0, 0));
            data.add(getFieldLayout(rowSizes, colSizes, margin, 1, 0));
            data.add(getFieldLayout(rowSizes, colSizes, margin, 1, 1));
            data.add(getFieldLayout(rowSizes, [width], margin, 2, 0));
        }else if(id == LAYOUT_SIX_FIELDS){
            var rowSizes = distributeSpace(height, margin, [1,1,1,1] as Array<Number>);
            var colSizes = distributeSpace(width, margin, [1,1] as Array<Number>);
            data.add(getFieldLayout(rowSizes, [width], margin, 0, 0));
            data.add(getFieldLayout(rowSizes, colSizes, margin, 1, 0));
            data.add(getFieldLayout(rowSizes, colSizes, margin, 1, 1));
            data.add(getFieldLayout(rowSizes, colSizes, margin, 2, 0));
            data.add(getFieldLayout(rowSizes, colSizes, margin, 2, 1));
            data.add(getFieldLayout(rowSizes, [width], margin, 3, 0));
        }else if(id == LAYOUT_CUSTOM1){
            var rowSizes = distributeSpace(height, margin, [1,1,1,1] as Array<Number>);
            var colSizes = distributeSpace(width, margin, [1,1] as Array<Number>);
            data.add(getFieldLayout(rowSizes, [width], margin, 0, 0));
            data.add(mergeFieldLayouts([
                getFieldLayout(rowSizes, colSizes, margin, 1, 0),
                getFieldLayout(rowSizes, colSizes, margin, 2, 0),
            ] as Array<FieldLayout>));
            data.add(getFieldLayout(rowSizes, colSizes, margin, 1, 1));
            data.add(getFieldLayout(rowSizes, colSizes, margin, 2, 1));
            data.add(getFieldLayout(rowSizes, [width], margin, 3, 0));
        }else if(id == LAYOUT_CUSTOM2){
            margin = 0;
            var rowSizes = distributeSpace(height, margin, [2,1,2,2,1] as Array<Number>);
            var colSizes = distributeSpace(width, margin, [2,1,2] as Array<Number>);
            data.add(getFieldLayout([height], [width], margin, 0, 0));
            data.add(getFieldLayout(rowSizes, [width], margin, 0, 0));
            data.add(getFieldLayout(rowSizes, colSizes, margin, 2, 0));
            data.add(getFieldLayout(rowSizes, colSizes, margin, 2, 2));
            data.add(getFieldLayout(rowSizes, [width], margin, 3, 0));
        }else{
            var rowSizes = distributeSpace(height, margin, [1,2,1] as Array<Number>);
            var colSizes = distributeSpace(width, margin, [1,2,1] as Array<Number>);
            data.add(getFieldLayout(rowSizes, colSizes, margin, 1, 1));
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

    function onSetting(sender as Object, id as Settings.Id, value as Settings.ValueType) as Void{
        if(id == Settings.ID_DATASCREENS){
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
        }else if(id == Settings.ID_DARK_MODE){
            self.darkMode = value as Boolean;
        }
    }
    hidden function applyScreenSettings(screenSettings as ScreenSettings) as Void{
        var fields = $.getApp().fieldManager.getFields(screenSettings[SETTING_FIELDS] as Array<DataFieldId>);
        var layout = DataView.getLayoutById(screenSettings[SETTING_LAYOUT] as LayoutId);
        setFields(fields);
        setFieldsLayout(layout);
    }
}