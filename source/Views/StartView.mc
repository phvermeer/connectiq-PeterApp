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

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
//    	var icon = findDrawableById("icon") as IconSport;
//        var settings = getApp().settings;
//    	var sport = settings.getSetting(SETTING_SPORT) as Sport;
//    	icon.setSport(sport);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    function onKey(sender as MyViewDelegate, keyEvent as WatchUi.KeyEvent) as Boolean{
        var app = $.getApp();
        var session = app.session;
	    switch(keyEvent.getKey()){
			case WatchUi.KEY_ENTER:{
				// Start the session
				var settings = app.settings as Settings;
				var sport = settings.get(SETTING_SPORT) as Sport;
				session.setSport(sport);
				session.start();

                // Show DataView
                var screens = settings.get(SETTING_DATASCREENS) as Array;
                var screen = screens[0] as Array;
                var layout = DataView.getLayoutById(screen[0] as LayoutId);
                var fieldIds = screen[1] as Array<DataFieldId>;
                var fields = app.fieldManager.getFields(fieldIds);
			
				// Open the data screen
				var view = new DataView({
                    :fields => fields,
                    :layout => layout
                });
				sender.switchToView(view, WatchUi.SLIDE_IMMEDIATE);
				return true;
			}
			default:
				return false;
		}
    }
}
