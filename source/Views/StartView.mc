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
        var session = $.session as Session;
	    switch(keyEvent.getKey()){
			case WatchUi.KEY_ENTER:{
				// Start the session
				var settings = $.settings as Settings;
				var sport = settings.getSetting(SETTING_SPORT) as Sport;
				session.setSport(sport);
				session.start();

                // dummy fields and layout
                var fields = [
                    new MyDataField({}),
                    new MyDataField({})
                ] as Array<MyDataField>;
                var layout = [
                    { :locX => 0, :locY => 0, :width => 100, :height => 100 },
                    { :locX => 100, :locY => 100, :width => 100, :height => 100 },
                ] as Layout;
			
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
