import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
using Toybox.Activity as Activity;
import MyBarrel.Views;

class ConfirmDelegate extends WatchUi.ConfirmationDelegate{
	enum Action {
		ACTION_CANCEL = 0,
		ACTION_SAVE = 1,
		ACTION_DISCARD = 2,
	}

	var nextAction as Action|Null;
	hidden var requestedAction as Action;

	function initialize(action as Action){
		self.requestedAction = action;
		ConfirmationDelegate.initialize();
	}
	function onResponse(response as WatchUi.Confirm) as Boolean{
		self.nextAction = (response == WatchUi.CONFIRM_YES)
			? requestedAction
			: null;
		return true;
	}
}

class StopView extends MyView {
	var confirmation as ConfirmDelegate?;

    function initialize(delegate as MyViewDelegate){
        MyView.initialize(delegate);
    }
        
    // Load your resources here
    function onLayout(dc as Dc) as Void {
        View.onLayout(dc);
        setLayout(Rez.Layouts.stopped(dc));
    }

    function onUpdate(dc as Dc) as Void {
		View.onUpdate(dc);

		var info = Activity.getActivityInfo();
		var distance, ascent, descent;
		if(info != null){
			distance = (info.elapsedDistance != null) ? (info.elapsedDistance as Float) : 0f;
			ascent = (info.totalAscent != null) ? info.totalAscent as Number : 0;
			descent = (info.totalDescent != null) ? info.totalDescent as Number : 0;
		}else{
			distance = 0f;
			ascent = 0;
			descent = 0;
		}
		
		var width = dc.getWidth();
		var height = dc.getHeight();
		
		// Draw box for main info
		var x = -width*0.10;
		var y = height*0.22;
		var w = width;
		var h = height*0.25;
		var radius = height*0.04;
		var penWidth = (width>100) ? width/100 : 1;

		dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
		dc.setPenWidth(penWidth);
		dc.drawRoundedRectangle(x, y, w, h, radius);

		// Draw vertical side line for additional info
		x = width*0.18;
		y = height*0.50;
		h = height*0.28;
		dc.drawLine(x, y, x, y+h);
		
		// Icon backround (filled circle)
		x = width*0.17;
		y = height*0.34;
		radius = height*0.08;
		dc.fillCircle(x, y, radius);
		
		// Icon
		x = width*0.10;
		y = height*0.27;
		
		var session = getApp().session;
		var icon = session.getIcon(session.getSport());
		dc.drawBitmap(x, y, icon);
		
		// Unit Text
		var unit = "m";
		if(distance > 1000){
			distance = distance/1000;
			unit = "km";
		}
		
		dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
		var font = Graphics.FONT_MEDIUM;
		var text = unit;
		var dimensions = dc.getTextDimensions(text, font);
		x = width*0.87 - dimensions[0];
		y = height*0.42;
		var y1 = y - 0.8*dimensions[1]; // vertical align to bottom
		dc.drawText(x, y1, font, text, Graphics.TEXT_JUSTIFY_LEFT);
		
		// Value text (distance)
		font = Graphics.FONT_NUMBER_MEDIUM;
		text = distance.format("%.2f");
		dimensions = dc.getTextDimensions(text, font);
		var y2 = y - 0.8*dimensions[1]; // vertical align to bottom
		dc.drawText(x, y2, font, text, Graphics.TEXT_JUSTIFY_RIGHT);
		
		// Secondairy text 1
		text = ascent.format("%.2f");
		font =  Graphics.FONT_MEDIUM;
		dimensions = dc.getTextDimensions("X", font);
		x = width*25/100;
		y = height*52/100;
		var drawable = new Drawables.IconUp({
			:locX => x,
			:locY => y,
			:width => dimensions[0],
			:height => dimensions[1]
		}, Graphics.COLOR_WHITE);
		
		drawable.draw(dc);
		x += drawable.width*2;
		dc.drawText(x, y, font, text, Graphics.TEXT_JUSTIFY_LEFT);
		
		// Secondairy text 2
		text = descent.format("%.2f");
		font =  Graphics.FONT_MEDIUM;
		dimensions = dc.getTextDimensions("X", font);
		x = width*25/100;
		y = height*65/100;
		drawable = new Drawables.IconDown({
			:locX => x,
			:locY => y,
			:width => dimensions[0],
			:height => dimensions[1]
		}, Graphics.COLOR_WHITE);
		drawable.draw(dc);
		x += drawable.width*2;
		dc.drawText(x, y, font, text, Graphics.TEXT_JUSTIFY_LEFT);
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
		MyView.onShow();
		if(confirmation != null){
	    	// continu action after confirmation result
			if(confirmation.nextAction != null){
				// Stop and close session
				var action = confirmation.nextAction as ConfirmDelegate.Action;
				var session = getApp().session;
				switch(action){
					case ConfirmDelegate.ACTION_SAVE:
						session.save();
						break;
					case ConfirmDelegate.ACTION_DISCARD:
						session.discard();
						break;
				}

				// Switch to start views
				var delegate = getDelegate();
				if(delegate != null){
					// pop all view except for the last, that one will be replaced with a new screen (avoid closing app)
					var count = delegate.stackSize();
					for(var i=1; i<count; i++){
						WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
					}

					// replace last screen
					var view = new StartView(delegate);
					WatchUi.switchToView(view, delegate, WatchUi.SLIDE_IMMEDIATE);
				}
			}
		}
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
		MyView.onHide();
    }

	function onTap(sender as MyViewDelegate, clickEvent as ClickEvent) as Boolean{
		// Determine if the tap is a confirmation for discard or save
		var xy = clickEvent.getCoordinates();
		var y = xy[1];
		var deviceSettings = System.getDeviceSettings();
		var height = deviceSettings.screenHeight;

		var doDiscard = (y < height*1/3);
		var doSave = (y > height*2/3);

	    if(doDiscard || doSave){
			var action = doDiscard
				? ConfirmDelegate.ACTION_DISCARD
				: doSave
					? ConfirmDelegate.ACTION_SAVE
					: ConfirmDelegate.ACTION_CANCEL;

			var message = doDiscard
				? Lang.format("$1$ ?", [WatchUi.loadResource(Rez.Strings.discard)])
				: Lang.format("$1$ ?", [WatchUi.loadResource(Rez.Strings.save)]);
			var dialog = new WatchUi.Confirmation(message);
			confirmation = new ConfirmDelegate(action);
			WatchUi.pushView(
				dialog,
				confirmation,
				WatchUi.SLIDE_IMMEDIATE
			);
			return true;
		}else{
			return false;
		}
	}   

/*
	function onBack(sender as MyViewDelegate) as Boolean{
		// Open DataView with correct fields
		var app = $.getApp();
		var screensSettings = app.settings.get(Settings.ID_DATASCREENS) as DataView.ScreensSettings;

		var view = new DataView(0, screensSettings, sender);
		app.settings.addListener(view);
		app.session.addListener(view);

		WatchUi.switchToView(view, sender, WatchUi.SLIDE_IMMEDIATE);
		return true;
	}
*/
}
