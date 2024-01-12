import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Application;
import Toybox.Activity;
import MyBarrel.Views;

class ViewDelegate extends Views.MyViewDelegate {
    // current dataView index
    hidden var dataViewIndex as Number = 0;

    function initialize() {
        MyViewDelegate.initialize();
    }

	function onKey(keyEvent as WatchUi.KeyEvent) as Lang.Boolean{
        var v = self.getView();
        if(v instanceof DataView){
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
        var v = getView();
        if(v != null){
            if(v instanceof DataView){
                // Open StopView
                var view = new StopView(self);
                WatchUi.switchToView(view, self, WatchUi.SLIDE_IMMEDIATE);
                return true;
            }else if(v instanceof StopView){
                // Open DataView with correct fields
                var app = $.getApp();
                var screensSettings = app.settings.get(Settings.ID_DATASCREENS) as DataView.ScreensSettings;
                var view = new DataView(dataViewIndex, screensSettings, self);
                app.settings.addListener(view);
                app.session.addListener(view);

                WatchUi.switchToView(view, self, WatchUi.SLIDE_IMMEDIATE);
                return true;
            }
        }
        return false;
    }

    (:advanced)
    function onMenu() as Boolean {
        var menu = new MainMenu();
        WatchUi.pushView(menu, menu.getDelegate(), WatchUi.SLIDE_UP);
        return true;
    }
}