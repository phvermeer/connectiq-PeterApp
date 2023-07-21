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
