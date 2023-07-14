import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Application;
import MyViews;

class ViewDelegate extends MyViews.MyViewDelegate {
    // current dataView index
    hidden var dataViewIndex as Number = 0;

    function initialize(view as MyView) {
        MyViewDelegate.initialize(view);
    }

    function onKey(keyEvent as KeyEvent) as Boolean{
        if(keyEvent.getKey() == WatchUi.KEY_START){
            if(keyEvent.getType() == PRESS_TYPE_ACTION){
                var session = getApp().session;
                switch(session.getState()){
                    case SESSION_STATE_IDLE:
			        case SESSION_STATE_STOPPED:
                        session.start();
                        break;
                    default:
                        session.stop();
                        break;
                }
            }
        }
        return MyViewDelegate.onKey(keyEvent);
    }

    function onMenu() as Boolean {
        var menu = new MainMenu();
        WatchUi.pushView(menu, menu.getDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

    function onSessionState(state as SessionState) as Void{
        if(mView instanceof DataView){
            (mView as DataView).onSessionState(state);
        }
    }

    function onTimer() as Void{
        if(mView instanceof DataView){
            (mView as DataView).onTimer();
        }
    }

    function onSwipe(event as SwipeEvent) as Boolean{
        if(mView instanceof DataView){
            // swipe up or down to next dataview
            switch(event.getDirection()){
                case WatchUi.SWIPE_DOWN:
                    break;
                case WatchUi.SWIPE_UP:
                    break;
            }
            return true;
        }
        return false;
    }

    // external trigger to update DataView with changed settings
    function onSettingChange(id as SettingId, value as PropertyValueType) as Void{
        if(mView instanceof DataView){
            var view = mView as DataView;
            if(id == SETTING_DATASCREENS){
                // decode settings with helpers
                var screensSettings = new DataScreensSettings(value);
                var screenSettings = screensSettings.items[dataViewIndex];

                var layout = DataView.getLayoutById(screenSettings.layoutId);
                var fields = $.getApp().fieldManager.getFields(screenSettings.fieldIds);

                view.setFields(fields);
                view.setFieldsLayout(layout);
            }
        }
    }

    function createDataView(dataViewSettings as Array) as DataView{
        // create layout from settings
        var layout = DataView.getLayoutById(dataViewSettings[0] as LayoutId);
        var fieldIds = dataViewSettings[1] as Array<DataFieldId>;
        
        // get fields for fieldIds
        var count = MyMath.min([layout.size(), fieldIds.size()] as Array<Number>);
        var fields = new Array<MyDataField>[count];
        var fieldManager = getApp().fieldManager;
        for(var i=0; i<count; i++){
            fields[i] = fieldManager.getField(fieldIds[i]);
        }

        // create the dataView
        var view = new DataView({
            :layout => layout,
            :fields => fields
        });
        return view;
    }
}