import Toybox.Activity;
import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import MyViews;

class StartView extends MyViews.MyView {
    function initialize() {
        MyView.initialize();

    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.start(dc));
    }

    function onShow() as Void{
        var icon = findDrawableById("icon") as Icon;
        var app = getApp();
        var sport = app.settings.get(SETTING_SPORT) as Activity.Sport;
        icon.setBitmap(Session.getIcon(sport));

    }

    function onKey(sender as MyViewDelegate, keyEvent as WatchUi.KeyEvent) as Boolean{
        var app = $.getApp();
        var session = app.session;
	    switch(keyEvent.getKey()){
			case WatchUi.KEY_ENTER:{
				// Start the session
				session.start();

                // Show DataView
                var settings = app.settings;
                var screensSettings = settings.get(SETTING_DATASCREENS) as DataView.ScreensSettings;
			
				// Open the data screen
				var view = new DataView(0, screensSettings);
                app.data.addListener(view);
				sender.switchToView(view, WatchUi.SLIDE_IMMEDIATE);
				return true;
			}
			default:
				return false;
		}
    }
}
