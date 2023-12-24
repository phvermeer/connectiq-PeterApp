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
            var screensSettings = app.settings.get(SETTING_DATASCREENS) as DataView.ScreensSettings;
            var view = new DataView(dataViewIndex, screensSettings);
            app.data.addListener(view);
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
}