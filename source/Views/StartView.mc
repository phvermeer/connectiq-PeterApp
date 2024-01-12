import Toybox.Activity;
import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import MyBarrel.Views;
import MyBarrel.Drawables;

class StartView extends MyView {
    var hintStart as Drawable;
    var icon as Icon;
    var text as Text;

    function initialize(delegate as MyViewDelegate){
        MyView.initialize(delegate);
        hintStart = new Drawables.HintStart({});
        icon = new Icon({});
        text = new WatchUi.Text({
            :text => WatchUi.loadResource(Rez.Strings.start) as String,
            :justification => Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER,
        });
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        // setLayout(Rez.Layouts.start(dc));
        var w = dc.getWidth();
        var h = dc.getHeight();
        
        text.locX = w / 2;
        text.locY = 0.6 * h;

        icon.width = w/5;
        icon.height = icon.width;
        icon.locX = (w - icon.width) / 2;
        icon.locY = 0.4 * (h - icon.height);
    }

    function onShow() as Void{
        var sport = getApp().settings.get(Settings.ID_SPORT) as Activity.Sport;
        icon.setBitmap(Session.getIcon(sport));
    }

    function onUpdate(dc as Dc) as Void{
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();


        // draw text "Start"
        text.draw(dc);

        // icon with current sport
        icon.draw(dc);

        // draw hint to start button
        hintStart.draw(dc);
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
                var screensSettings = settings.get(Settings.ID_DATASCREENS) as DataView.ScreensSettings;
			
				// Open the data screen
				var view = new DataView(0, screensSettings, sender);
                settings.addListener(view);
                session.addListener(view);

				WatchUi.switchToView(view, sender, WatchUi.SLIDE_IMMEDIATE);
				return true;
			}
			default:
				return false;
		}
    }
}
