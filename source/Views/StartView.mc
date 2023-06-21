import Toybox.Activity;
import Toybox.Graphics;
using Toybox.WatchUi;
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

}
