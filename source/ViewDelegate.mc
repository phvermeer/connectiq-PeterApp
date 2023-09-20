import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Application;
import Toybox.Activity;
import MyViews;

class ViewDelegate extends MyViews.MyViewDelegate {
    // current dataView index
    hidden var dataViewIndex as Number = 0;

    function initialize(view as MyView) {
        MyViewDelegate.initialize(view);
    }

	function onKey(keyEvent as WatchUi.KeyEvent) as Lang.Boolean{
        if(mView instanceof DataView){
            if(keyEvent.getType() == WatchUi.PRESS_TYPE_ACTION){
                switch(keyEvent.getKey()){
                    case WatchUi.KEY_ENTER:
                    {
                        var session = getApp().session;
                        switch(session.getState()){
                            case SESSION_STATE_BUSY:
                            case SESSION_STATE_PAUSED:
                                session.stop();
                                break;
                            default:
                                session.start();
                                break;
                        }
                        return true;
                    }
                }
            }
		}
		return MyViewDelegate.onKey(keyEvent);
	}

    function onBack() as Boolean{
        // check current view
        if(mView instanceof DataView){
            // Open StopView
            var view = new StopView();
            switchToView(view, WatchUi.SLIDE_IMMEDIATE);
            return true;
        }else if(mView instanceof StopView){
            // Open DataView with correct fields
            var app = $.getApp();
            var screensSettings = new DataScreensSettings(app.settings.get(SETTING_DATASCREENS));
            var screenSettings = screensSettings.items[dataViewIndex];
            var fields = app.fieldManager.getFields(screenSettings.fieldIds);
            var layout = DataView.getLayoutById(screenSettings.layoutId);
            var view = new DataView({
                :fields => fields,
                :layout => layout,
                :sessionState => app.session.getState(),
            });
            switchToView(view, WatchUi.SLIDE_IMMEDIATE);
            return true;
        }
        return false;
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

    function onSwipe(event as SwipeEvent) as Boolean{
        if(mView instanceof DataView){
            var dataView = mView as DataView;

            // get screens settings
            var app = $.getApp();
            var screensSettings = new DataScreensSettings(app.settings.get(SETTING_DATASCREENS));
            var count = screensSettings.items.size();

            // swipe up or down to next dataview
            switch(event.getDirection()){
                case WatchUi.SWIPE_DOWN:
                    // next screen id
                    do{
                        dataViewIndex++;
                        if(dataViewIndex >= count){
                            dataViewIndex = 0;
                        }
                    }while(!screensSettings.items[dataViewIndex].enabled);
                    break;
                case WatchUi.SWIPE_UP:
                    do{
                        dataViewIndex--;
                        if(dataViewIndex <0){
                            dataViewIndex = count-1;
                        }
                    }while(!screensSettings.items[dataViewIndex].enabled);
                    break;
                default:
                    return false;
            }
            // show new screen
            var screenSettings = screensSettings.items[dataViewIndex];
            var fields = app.fieldManager.getFields(screenSettings.fieldIds);
            var layout = DataView.getLayoutById(screenSettings.layoutId);
            dataView.setFields(fields);
            dataView.setFieldsLayout(layout);
            WatchUi.requestUpdate();
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